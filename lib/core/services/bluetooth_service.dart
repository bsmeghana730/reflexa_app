import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SensorMessage { moveCorrect, moveWrong, green, yellow, red, none, sessionComplete, repDetected }

class BleEvent {
  final SensorMessage type;
  final String? data;
  BleEvent(this.type, {this.data});
}

class AppBluetoothService {
  static final AppBluetoothService _instance = AppBluetoothService._internal();
  factory AppBluetoothService() => _instance;
  AppBluetoothService._internal();

  static const String keyLastDeviceId = "last_ble_device_id";
  static const String keyLastDeviceName = "last_ble_device_name";

  fbp.BluetoothDevice? _connectedDevice;
  fbp.BluetoothCharacteristic? _writeCharacteristic;
  bool _isAutoConnecting = false;
  
  final StreamController<BleEvent> _messageController = StreamController<BleEvent>.broadcast();
  Stream<BleEvent> get messageStream => _messageController.stream;

  final StreamController<List<int>> _activeDevicesController = StreamController<List<int>>.broadcast();
  Stream<List<int>> get activeDevicesStream => _activeDevicesController.stream;
  List<int> _activeDevices = [];
  List<int> get activeDevices => _activeDevices;

  final Map<int, double> _sensorDataMap = {};
  Map<int, double> get sensorDataMap => _sensorDataMap;

  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  bool get isConnected {
    final connected = _connectedDevice != null && _writeCharacteristic != null;
    if (!connected) {
      print("BLE: isConnected check failed: Device=${_connectedDevice != null}, WriteChar=${_writeCharacteristic != null}");
    }
    return connected;
  }
  String? get connectedDeviceName => _connectedDevice?.advName ?? _connectedDevice?.platformName;

  /// Initialize service and check for saved devices
  Future<void> init() async {
    print("BLE: Initializing Service...");
    
    fbp.FlutterBluePlus.adapterState.listen((state) {
      print("BLE: Adapter state changed to $state");
      if (state == fbp.BluetoothAdapterState.on) {
        unawaited(_attemptAutoConnect());
      }
    });

    unawaited(_attemptAutoConnect());
  }

  Future<void> _attemptAutoConnect() async {
    if (isConnected || _isAutoConnecting) return;
    
    final prefs = await SharedPreferences.getInstance();
    final String? savedId = prefs.getString(keyLastDeviceId);
    
    if (savedId != null) {
      print("BLE: Auto-reconnect triggered for $savedId");
      _isAutoConnecting = true;
      try {
        await connectToMacAddress(savedId, isAuto: true);
      } catch (e) {
        print("BLE: Auto-reconnect error: $e");
      } finally {
        _isAutoConnecting = false;
      }
    }
  }

  Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
    return statuses.values.every((status) => status.isGranted);
  }

  Completer<bool>? _ackCompleter;

  Stream<List<fbp.ScanResult>> get scanResults => fbp.FlutterBluePlus.scanResults;

  Future<void> startManualScan() async {
    await requestPermissions();
    if (await fbp.FlutterBluePlus.adapterState.first != fbp.BluetoothAdapterState.on) return;
    
    await fbp.FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 15),
      androidScanMode: fbp.AndroidScanMode.lowLatency,
      androidUsesFineLocation: true,
    );
  }

  Future<void> stopManualScan() async {
    await fbp.FlutterBluePlus.stopScan();
  }

  Future<bool> connectToMacAddress(String macId, {Function(String)? onStatus, bool isAuto = false}) async {
    macId = macId.toUpperCase().trim();
    print("BLE: Connecting to $macId (Auto: $isAuto)");
    try {
      // If already connected correctly, return success
      if (_connectedDevice?.remoteId.str == macId && _writeCharacteristic != null) {
        print("BLE: Already connected to $macId with characteristic.");
        return true;
      }

      onStatus?.call("Checking status...");
      fbp.BluetoothDevice device = fbp.BluetoothDevice.fromId(macId);
      
      // Monitor this device's connection status globally
      device.connectionState.listen((state) {
        print("BLE: Device connection state: $state");
        if (state == fbp.BluetoothConnectionState.disconnected) {
          _connectedDevice = null;
          _writeCharacteristic = null;
          _connectionController.add(false);
        }
      });

      if (_connectedDevice?.remoteId.str == macId && _writeCharacteristic != null) {
        print("BLE: Already connected to $macId with characteristic.");
        return true;
      }

      onStatus?.call("Connecting...");
      await device.connect(
        timeout: isAuto ? const Duration(seconds: 20) : const Duration(seconds: 12),
        autoConnect: isAuto, 
      );
      
      return await _setupDevice(device, onStatus);
    } catch(e) {
      print("BLE: Connection failed: $e");
      onStatus?.call("Failed.");
      return false;
    }
  }

  Future<bool> _setupDevice(fbp.BluetoothDevice device, Function(String)? onStatus) async {
    try {
      print("BLE: Starting setup for ${device.remoteId}");
      
      try {
        await device.requestMtu(256);
      } catch(_) {}

      await Future.delayed(const Duration(milliseconds: 800));

      onStatus?.call("Pairing...");
      _ackCompleter = Completer<bool>();
      
      // Discover services and subscribe
      await _discoverServices(device);
      
      onStatus?.call("Verifying...");
      
      // Send a small ping to trigger an ACK if not already sent
      if (_writeCharacteristic != null) {
        await _writeCharacteristic!.write(utf8.encode("ping"));
      }

      // Check if handshake (ack) was received
      bool isReady = await _ackCompleter!.future.timeout(
        const Duration(seconds: 12),
        onTimeout: () => false,
      );
      
      if (isReady) {
        print("BLE: Handshake SUCCESS for ${device.remoteId}");
        onStatus?.call("Connected!");
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(keyLastDeviceId, device.remoteId.str);
        await prefs.setString(keyLastDeviceName, device.advName.isNotEmpty ? device.advName : device.platformName);
        
        _connectedDevice = device;
        _connectionController.add(true);
        return true;
      } else {
        print("BLE: Handshake TIMEOUT for ${device.remoteId}");
        onStatus?.call("Handshake missed.");
        await device.disconnect();
        _connectedDevice = null;
        _connectionController.add(false);
        return false;
      }
    } catch (e) {
      print("BLE: Setup error: $e");
      return false;
    }
  }

  Future<void> _discoverServices(fbp.BluetoothDevice device) async {
    const String notifyUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
    const String writeUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a9";

    print("BLE: Discovering services...");
    List<fbp.BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      for (var characteristic in service.characteristics) {
        String uuid = characteristic.uuid.toString().toLowerCase();
        
        if (uuid == notifyUuid) {
          print("BLE: Notify characteristic found: $uuid");
          await characteristic.setNotifyValue(true);
          characteristic.onValueReceived.listen((value) => _parseData(value));
        } else if (uuid == writeUuid) {
          print("BLE: Write characteristic found: $uuid");
          _writeCharacteristic = characteristic;
        } else if (uuid.contains("6e400003")) { // Standard UART fallback
          await characteristic.setNotifyValue(true);
          characteristic.onValueReceived.listen((value) => _parseData(value));
        } else if (uuid.contains("6e400002")) {
          _writeCharacteristic = characteristic;
        }
      }
    }
  }

  Future<void> configureExercise(String exerciseBase, String level, int reps) async {
    if (_writeCharacteristic == null) {
      print("BLE: Cannot write, characteristic null");
      return;
    }
    
    String hwExercise = "leg_raise";
    String exerciseLower = exerciseBase.toLowerCase();
    
    if (exerciseLower.contains("leg raise")) {
      hwExercise = "leg_raise";
    } else if (exerciseLower.contains("knee extension") || exerciseLower.contains("knee")) {
      hwExercise = "knee_extension";
    } else if (exerciseLower.contains("squat")) {
      hwExercise = "wall_squat"; 
    }

    try {
      print("BLE: Sending exercise command: $hwExercise");
      await _writeCharacteristic!.write(utf8.encode(hwExercise));
    } catch (e) {
      print("BLE: Write error: $e");
    }
  }

  void _parseData(List<int> value) {
    try {
      String message = utf8.decode(value).replaceAll('\x00', '').trim();
      print("BLE Received: $message");

      if (message.startsWith("ACTIVE_LIST:")) {
        _handleActiveListUpdate(message);
        return;
      }

      if (message.startsWith("D:")) {
        _handleDistanceUpdate(message);
        return;
      }

      String messageLower = message.toLowerCase();

      if (messageLower == "ack" || messageLower == "ready" || messageLower == "connected" || messageLower == "waiting_exercise") {
        if (_ackCompleter != null && !_ackCompleter!.isCompleted) {
          _ackCompleter!.complete(true);
        }
        return;
      }

      if (messageLower.startsWith("rep:")) {
        _messageController.add(BleEvent(SensorMessage.repDetected, data: messageLower.split(":")[1]));
      } else if (messageLower == "complete" || messageLower == "finished") {
        _messageController.add(BleEvent(SensorMessage.sessionComplete));
      } else if (messageLower == "correct" || messageLower == "green") {
        _messageController.add(BleEvent(SensorMessage.green));
      } else if (messageLower == "almost" || messageLower == "yellow" || messageLower == "near") {
        _messageController.add(BleEvent(SensorMessage.yellow));
      } else if (messageLower == "wrong" || messageLower == "red") {
        _messageController.add(BleEvent(SensorMessage.red));
      }
    } catch (e) {
      print("BLE Parse error: $e");
    }
  }

  void _handleActiveListUpdate(String response) {
    // Expected: "ACTIVE_LIST:1,2,5,"
    final String data = response.substring(12);
    final List<String> parts = data.split(',');
    
    List<int> newList = [];
    for (var p in parts) {
      final id = int.tryParse(p.trim());
      if (id != null) newList.add(id);
    }
    
    _activeDevices = newList;
    _activeDevicesController.add(_activeDevices);
    print("BLE: Active sensors updated: $_activeDevices");
  }

  void _handleDistanceUpdate(String response) {
    // Expected: "D:DeviceID:Distance" (e.g. "D:1:120.5")
    final List<String> parts = response.split(':');
    if (parts.length >= 3) {
      final int? id = int.tryParse(parts[1]);
      final double? value = double.tryParse(parts[2]);
      if (id != null && value != null) {
        _sensorDataMap[id] = value;
        // Optionally add a specific Event if your UI needs to react to raw data
        _messageController.add(BleEvent(SensorMessage.none, data: "sensor_$id:$value"));
      }
    }
  }

  /// Force a service discovery if we're connected but missing characteristics
  Future<void> ensureDiscovery() async {
    if (_connectedDevice != null && _writeCharacteristic == null) {
      print("BLE: Connected but missing write characteristic. Re-discovering...");
      await _discoverServices(_connectedDevice!);
      if (_writeCharacteristic != null) {
        _connectionController.add(true);
      }
    }
  }

  void disconnect() async {
    await _connectedDevice?.disconnect();
    _connectedDevice = null;
    _writeCharacteristic = null;
    _connectionController.add(false);
  }

  void forgetDevice() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyLastDeviceId);
    await prefs.remove(keyLastDeviceName);
    disconnect();
  }
}
