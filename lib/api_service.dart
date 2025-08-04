import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String base = 'http://192.168.43.35:8080/api';

  /// 🔐 Login method that returns the role
  static Future<String?> login(String username, String password) async {
    final r = await http.post(
      Uri.parse('$base/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (r.statusCode == 200 && r.body.isNotEmpty) {
      // After successful login, fetch user info to get the role
      final role = await getRole(username);
      return role;
    }

    return null;
  }

  /// 📌 Fetch user role
  static Future<String?> getRole(String username) async {
    final res = await http.get(Uri.parse('$base/user/$username'));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['role']; // assumes your user JSON contains `role`
    }

    return null;
  }

  /// 📝 Registration method (role now comes from frontend)
  static Future<bool> register(String username, String password, String role, String email) async {
    final r = await http.post(
      Uri.parse('$base/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'role': role, // use role from frontend
        'email': email
      }),
    );

    return r.statusCode == 200;
  }

  /// 📨 Submit new project (client side)
  Future<bool> submitProject(Map<String, dynamic> data) async {
    final r = await http.post(
      Uri.parse('$base/projects/submit'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return r.statusCode == 200;
  }

  /// 📥 Get all projects for a constructor
  Future<List<dynamic>> getProjectsForConstructor(String name) async {
    final r = await http.get(Uri.parse('$base/projects/constructor/$name'));
    if (r.statusCode == 200) {
      return jsonDecode(r.body);
    }
    return [];
  }

  /// 📤 Get all projects for a client
  Future<List<dynamic>> getProjectsForClient(String name) async {
    final r = await http.get(Uri.parse('$base/projects/client/$name'));
    if (r.statusCode == 200) {
      return jsonDecode(r.body);
    }
    return [];
  }

  /// ✅ Approve a project with budget (constructor side)
  Future<bool> approveProject(int id, String budget) async {
    final r = await http.put(
      Uri.parse('$base/projects/approve/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'budget': budget}),
    );
    return r.statusCode == 200;
  }

  /// ❌ Reject a project with reason (constructor side)
  Future<bool> rejectProject(int id, String reason) async {
    final r = await http.put(
      Uri.parse('$base/projects/reject/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'reason': reason}),
    );
    return r.statusCode == 200;
  }

  Future<bool> updateProfile(String username, Map<String, dynamic> data) async {
    final r = await http.put(
      Uri.parse('$base/user/$username'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return r.statusCode == 200;
  }

  static Future<Map<String, dynamic>?> fetchUserInfo(String username) async {
    final res = await http.get(Uri.parse('$base/user/$username'));

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return null;
  }

  static Future<List<Map<String, String>>> fetchAllConstructors() async {
    final res = await http.get(Uri.parse('$base/user/constructors'));
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Map<String, String>.from(e)).toList();
    }
    return [];
  }
}