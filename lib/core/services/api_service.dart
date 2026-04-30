import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static String activeBaseUrl = 'http://10.169.253.192:8000/api';
  
  static const List<String> possibleHosts = [
    'http://10.169.253.192:8000/api', 
    'http://10.0.2.2:8000/api',       
    'http://localhost:8000/api',      
  ];

  static List<dynamic> localExercises = [
    {'id': 101, 'name': 'Leg Raise', 'goal': 'Lower limb Exercise', 'device_count': 1, 'default_reps': 10},
    {'id': 102, 'name': 'Knee Extension', 'goal': 'Lower limb Exercise', 'device_count': 1, 'default_reps': 10},
    {'id': 103, 'name': 'Wall Support Squat', 'goal': 'Lower limb Exercise', 'device_count': 1, 'default_reps': 10},
  ];

  static List<dynamic> localAssignments = [
    {
      'id': 201, 'exercise': 101, 'exercise_name': 'Leg Raise', 'reps': 10, 'difficulty': 'Medium', 'status': 'ASSIGNED', 'patient': 2
    },
    {
      'id': 202, 'exercise': 102, 'exercise_name': 'Knee Extension', 'reps': 10, 'difficulty': 'Medium', 'status': 'ASSIGNED', 'patient': 2
    }
  ];

  static List<dynamic> localRequestedExercises = [];

  static List<dynamic> localResults = [
    {
      'id': 1, 'patient': 2, 'exercise': 101, 'accuracy': 85.0, 'time_taken': 900, 'score': 250, 'date': DateTime.now().subtract(const Duration(days: 1)).toIso8601String()
    },
    {
      'id': 2, 'patient': 2, 'exercise': 102, 'accuracy': 92.0, 'time_taken': 1200, 'score': 300, 'date': DateTime.now().toIso8601String()
    },
    {
      'id': 3, 'patient': 2, 'exercise': 101, 'accuracy': 78.0, 'time_taken': 600, 'score': 150, 'date': DateTime.now().subtract(const Duration(days: 2)).toIso8601String()
    }
  ];

  /// Helper to try all possible hosts for a given request.
  /// If [discoveryOnly] is true, it just finds a working host and returns its URL.
  static Future<http.Response> _tryRequest(String path, {String method = 'GET', Map<String, dynamic>? body}) async {
    // Try the last known working host first
    final hosts = [activeBaseUrl, ...possibleHosts.where((h) => h != activeBaseUrl)];
    
    for (var host in hosts) {
      final url = Uri.parse('$host$path');
      try {
        http.Response response;
        if (method == 'POST') {
          response = await http.post(url, headers: {'Content-Type': 'application/json'}, body: json.encode(body)).timeout(const Duration(seconds: 2));
        } else if (method == 'PATCH') {
          response = await http.patch(url, headers: {'Content-Type': 'application/json'}, body: json.encode(body)).timeout(const Duration(seconds: 2));
        } else {
          response = await http.get(url).timeout(const Duration(seconds: 2));
        }

        if (response.statusCode >= 200 && response.statusCode < 300) {
          activeBaseUrl = host; // Remember working host
          return response;
        }
      } catch (e) {
        print("API Error on $host: $e");
      }
    }
    throw Exception("Could not reach any host for path: $path");
  }

  static Future<List<dynamic>> getExercises() async {
    try {
      final response = await _tryRequest('/exercises/');
      return json.decode(response.body);
    } catch (_) {
      return localExercises;
    }
  }

  static Future<List<dynamic>> getPatientAssignments(int patientId) async {
    try {
      final response = await _tryRequest('/assignments/patient_assignments/?patient_id=$patientId');
      return json.decode(response.body);
    } catch (_) {
      return localAssignments;
    }
  }

  static Future<List<dynamic>> getRequestedExercises() async {
    try {
      final response = await _tryRequest('/assignments/');
      List<dynamic> all = json.decode(response.body);
      return all.where((a) => a['status'] == 'PENDING').toList();
    } catch (_) {
      return localRequestedExercises;
    }
  }

  static Future<void> requestExercise(int patientId, int exerciseId, {Map<String, dynamic>? localFallbackData}) async {
    try {
      await _tryRequest('/assignments/request_exercise/', method: 'POST', body: {
        'patient_id': patientId,
        'exercise_id': exerciseId,
      });
    } catch (_) {
      if (localFallbackData != null) {
        if (!localRequestedExercises.any((e) => e['id'] == localFallbackData['id'])) {
          localRequestedExercises.add(localFallbackData);
        }
      }
      throw Exception("Local mode");
    }
  }

  static Future<void> cancelExerciseRequest(int patientId, int exerciseId) async {
    try {
      final response = await _tryRequest('/assignments/?patient_id=$patientId');
      List<dynamic> all = json.decode(response.body);
      final assignment = all.firstWhere((a) => a['exercise'] == exerciseId && a['status'] == 'PENDING', orElse: () => null);
      if (assignment != null) {
        await _tryRequest('/assignments/${assignment['id']}/', method: 'DELETE');
      }
    } catch (e) {
      localRequestedExercises.removeWhere((ex) => ex['id'] == exerciseId);
    }
  }

  static Future<List<dynamic>> getAllRequests() async {
    try {
      final response = await _tryRequest('/assignments/');
      List<dynamic> all = json.decode(response.body);
      return all.where((a) => a['status'] == 'PENDING').toList();
    } catch (_) {
      return []; // Return empty instead of crashing therapist dashboard
    }
  }

  static Future<void> assignExercise(int assignmentId, int reps, String difficulty, String targetRange) async {
    await _tryRequest('/assignments/$assignmentId/', method: 'PATCH', body: {
      'reps': reps,
      'difficulty': difficulty,
      'target_range': targetRange,
      'status': 'ASSIGNED',
    });
  }

  static Future<void> saveSessionResult({
    required int patientId,
    required int exerciseId,
    required double accuracy,
    required int timeTaken,
    required int score,
  }) async {
    await _tryRequest('/results/', method: 'POST', body: {
      'patient': patientId,
      'exercise': exerciseId,
      'accuracy': accuracy,
      'time_taken': timeTaken,
      'score': score,
    });
  }

  static Future<List<dynamic>> getPatientResults(int patientId) async {
    try {
      final response = await _tryRequest('/results/?patient=$patientId');
      return json.decode(response.body);
    } catch (_) {
      return localResults;
    }
  }

  static Future<void> completeAssignment(int assignmentId) async {
    await _tryRequest('/assignments/$assignmentId/', method: 'PATCH', body: {
      'status': 'COMPLETED',
    });
  }

  static Future<Map<String, dynamic>> getPatientProfile(int userId) async {
    try {
      final response = await _tryRequest('/profiles/?user=$userId');
      List<dynamic> profiles = json.decode(response.body);
      return profiles.isNotEmpty ? profiles[0] : {};
    } catch (_) {
      return {};
    }
  }
}
