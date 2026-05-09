import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class AuthService {
  static const _tokenKey = 'auth_token';
  static const _companyKey = 'company_data';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<Map<String, dynamic>?> getCompany() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_companyKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<void> _save(String token, Map<String, dynamic> company) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_companyKey, jsonEncode(company));
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_companyKey);
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('${AppConfig.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) throw Exception(data['error'] ?? 'Error al iniciar sesión');
    await _save(data['token'] as String, data['company'] as Map<String, dynamic>);
    return data;
  }

  static Future<Map<String, dynamic>> register({
    required String companyName,
    required String email,
    required String password,
    String? nif,
    String? address,
    String? city,
    String? postalCode,
    String? phone,
    String? companyEmail,
  }) async {
    final res = await http.post(
      Uri.parse('${AppConfig.baseUrl}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'company_name': companyName,
        'email': email,
        'password': password,
        if (nif != null && nif.isNotEmpty) 'nif': nif,
        if (address != null && address.isNotEmpty) 'address': address,
        if (city != null && city.isNotEmpty) 'city': city,
        if (postalCode != null && postalCode.isNotEmpty) 'postal_code': postalCode,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (companyEmail != null && companyEmail.isNotEmpty) 'company_email': companyEmail,
      }),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 201) throw Exception(data['error'] ?? 'Error al registrar');
    await _save(data['token'] as String, data['company'] as Map<String, dynamic>);
    return data;
  }
}
