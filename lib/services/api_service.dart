import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/customer.dart';
import 'auth_service.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  static final String _base = AppConfig.baseUrl;

  static Future<Map<String, String>> get _headers async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static dynamic _decode(http.Response r) {
    final body = jsonDecode(r.body);
    if (r.statusCode == 401) throw ApiException('UNAUTHORIZED');
    if (r.statusCode >= 400) {
      throw ApiException((body['error'] ?? 'Error desconocido').toString());
    }
    return body;
  }

  // ── Productos ────────────────────────────────────────────
  static Future<List<Product>> getProducts() async {
    final r = await http.get(Uri.parse('$_base/products'), headers: await _headers);
    final list = _decode(r) as List;
    return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Product> createProduct(Map<String, dynamic> data) async {
    final r = await http.post(Uri.parse('$_base/products'),
        headers: await _headers, body: jsonEncode(data));
    return Product.fromJson(_decode(r) as Map<String, dynamic>);
  }

  static Future<void> updateProduct(int id, Map<String, dynamic> data) async {
    final r = await http.put(Uri.parse('$_base/products/$id'),
        headers: await _headers, body: jsonEncode(data));
    _decode(r);
  }

  static Future<void> deleteProduct(int id) async {
    final r = await http.delete(Uri.parse('$_base/products/$id'), headers: await _headers);
    _decode(r);
  }

  // ── Ventas ───────────────────────────────────────────────
  static Future<List<Sale>> getSales() async {
    final r = await http.get(Uri.parse('$_base/sales'), headers: await _headers);
    final list = _decode(r) as List;
    return list.map((e) => Sale.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Map<String, dynamic>> createSale(Map<String, dynamic> data) async {
    final r = await http.post(Uri.parse('$_base/sales'),
        headers: await _headers, body: jsonEncode(data));
    return _decode(r) as Map<String, dynamic>;
  }

  static Future<void> deleteSale(int id) async {
    final r = await http.delete(Uri.parse('$_base/sales/$id'), headers: await _headers);
    _decode(r);
  }

  static Future<void> updatePaymentStatus(int id, String status) async {
    final r = await http.patch(Uri.parse('$_base/sales/$id/payment-status'),
        headers: await _headers, body: jsonEncode({'status': status}));
    _decode(r);
  }

  static Future<Uint8List> getInvoicePdf(int id) async {
    final h = await _headers;
    final r = await http.get(Uri.parse('$_base/sales/$id/invoice'), headers: h);
    if (r.statusCode >= 400) throw ApiException('Error al descargar PDF');
    return r.bodyBytes;
  }

  // ── Estadísticas ─────────────────────────────────────────
  static Future<Map<String, dynamic>> getSalesStats() async {
    final r = await http.get(Uri.parse('$_base/sales/stats/summary'), headers: await _headers);
    return _decode(r) as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> getMonthlyStats() async {
    final r = await http.get(Uri.parse('$_base/sales/stats/monthly'), headers: await _headers);
    final list = _decode(r) as List;
    return list.cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> getTopProducts() async {
    final r = await http.get(Uri.parse('$_base/sales/stats/top-products'), headers: await _headers);
    final list = _decode(r) as List;
    return list.cast<Map<String, dynamic>>();
  }

  // ── Clientes ─────────────────────────────────────────────
  static Future<List<Customer>> getCustomers() async {
    final r = await http.get(Uri.parse('$_base/customers'), headers: await _headers);
    final list = _decode(r) as List;
    return list.map((e) => Customer.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Customer> createCustomer(Map<String, dynamic> data) async {
    final r = await http.post(Uri.parse('$_base/customers'),
        headers: await _headers, body: jsonEncode(data));
    return Customer.fromJson(_decode(r) as Map<String, dynamic>);
  }

  static Future<void> updateCustomer(int id, Map<String, dynamic> data) async {
    final r = await http.put(Uri.parse('$_base/customers/$id'),
        headers: await _headers, body: jsonEncode(data));
    _decode(r);
  }

  static Future<void> deleteCustomer(int id) async {
    final r = await http.delete(Uri.parse('$_base/customers/$id'), headers: await _headers);
    _decode(r);
  }

  static Future<List<Map<String, dynamic>>> getCustomerSales(int id) async {
    final r = await http.get(Uri.parse('$_base/customers/$id/sales'), headers: await _headers);
    final list = _decode(r) as List;
    return list.cast<Map<String, dynamic>>();
  }

  // ── Empresa ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> getCompanyInfo() async {
    final r = await http.get(Uri.parse('$_base/sales/company/info'), headers: await _headers);
    return _decode(r) as Map<String, dynamic>;
  }

  static Future<void> updateCompanyInfo(Map<String, dynamic> data) async {
    final r = await http.put(Uri.parse('$_base/sales/company/info'),
        headers: await _headers, body: jsonEncode(data));
    _decode(r);
  }
}
