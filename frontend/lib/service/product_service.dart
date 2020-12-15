import 'dart:convert';

import 'package:frontend/model/product.dart';
import 'package:google_sign_in/google_sign_in.dart';
import "package:http/http.dart" as http;

Future<List<Product>> fetchProducts(
    GoogleSignInAccount _currentUser, String _basicToken) async {
  String token = await _getToken(_currentUser, _basicToken);

  final http.Response response =
      await http.get('http://192.168.178.34:8080/api/products', headers: {
    'Authorization': token,
  });
  return _parseProducts(response.body);
}

Future<void> saveProduct(GoogleSignInAccount _currentUser, String _basicToken,
    Product product) async {
  String token = await _getToken(_currentUser, _basicToken);

  await http.put('http://192.168.178.34:8080/api/products',
      headers: {'Authorization': token, "Content-Type": "application/json"},
      body: jsonEncode(product.toJson()));
}

Future<void> createProduct(GoogleSignInAccount _currentUser, String _basicToken,
    Product product) async {
  String token = await _getToken(_currentUser, _basicToken);

  await http.post('http://192.168.178.34:8080/api/products',
      headers: {'Authorization': token, "Content-Type": "application/json"},
      body: jsonEncode(product.toJson()));
}

Future<void> increaseQuantity(GoogleSignInAccount _currentUser,
    String _basicToken, String productId, int delta) async {
  String token = await _getToken(_currentUser, _basicToken);

  await http.post(
      'http://192.168.178.34:8080/api/products/$productId/quantity/increase',
      headers: {'Authorization': token, "Content-Type": "application/json"},
      body: delta.toString());
}

Future<void> removeProduct(GoogleSignInAccount _currentUser, String _basicToken,
    String productId) async {
  String token = await _getToken(_currentUser, _basicToken);

  await http.delete('http://192.168.178.34:8080/api/products/$productId',
      headers: {'Authorization': token, "Content-Type": "application/json"});
}

Future<bool> decreaseQuantity(GoogleSignInAccount _currentUser,
    String _basicToken, String productId, int delta) async {
  String token = await _getToken(_currentUser, _basicToken);

  http.Response response = await http.post(
      'http://192.168.178.34:8080/api/products/$productId/quantity/decrease',
      headers: {'Authorization': token, "Content-Type": "application/json"},
      body: delta.toString());

  if (response.statusCode == 200) {
    return true;
  } else {
    return false;
  }
}

Future<String> synchronizeProducts(GoogleSignInAccount _currentUser,
    String _basicToken, List<Map> commands) async {
  String token = await _getToken(_currentUser, _basicToken);

  http.Response response = await http.post(
      'http://192.168.178.34:8080/api/products/synchronize',
      headers: {'Authorization': token, "Content-Type": "application/json"},
      body: jsonEncode({"commands": commands}));

  return response.body;
}

Future<String> _getToken(
    GoogleSignInAccount _currentUser, String _basicToken) async {
  if (_currentUser != null) {
    GoogleSignInAuthentication authentication =
        await _currentUser.authentication;
    String token = authentication.idToken;
    return "Bearer $token";
  } else {
    return "Basic $_basicToken";
  }
}

List<Product> _parseProducts(String responseBody) {
  final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();

  return parsed.map<Product>((json) => Product.fromJson(json)).toList();
}
