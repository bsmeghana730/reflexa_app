import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reflexa_app/features/auth/presentation/splash_screen.dart';
import 'package:reflexa_app/core/services/database_seeder.dart';
import 'package:reflexa_app/core/services/storage_service.dart';
import 'package:reflexa_app/core/services/bluetooth_service.dart';


void main() async {
  debugPrint('App: main() started');
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('App: WidgetsBinding initialized');
  try {
    await Firebase.initializeApp();
    debugPrint('App: Firebase initialized successfully');
    
    // Initialize Storage
    await StorageService().init();

    // Seed data for the new workflow
    await DatabaseSeeder.seedData();

    // Initialize BLE Auto-reconnect
    await _initBluetooth();
  } catch (e) {
    debugPrint('App: Firebase initialization failed: $e');
  }
  runApp(const MyApp());
}

Future<void> _initBluetooth() async {
  try {
    await AppBluetoothService().init();
  } catch (e) {
    debugPrint("BLE: Init error: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reflexa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF006C55),
          primary: const Color(0xFF006C55),
          secondary: const Color(0xFF00886C),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAF9),
        textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme),
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          titleTextStyle: GoogleFonts.outfit(
            color: const Color(0xFF1A1A1A),
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFE8E8E8)),
          ),
          color: Colors.white,
          margin: const EdgeInsets.symmetric(vertical: 8),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: const Color(0xFF006C55),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
