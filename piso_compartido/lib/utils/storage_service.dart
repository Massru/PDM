import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio genérico de persistencia local sobre SharedPreferences.
/// Abstrae la serialización/deserialización JSON para que los providers
/// no tengan que tratar con strings crudos.
class StorageService {
  /// Guarda cualquier dato serializable como JSON bajo [key].
  static Future<void> save(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(data));
  }

  /// Lee un objeto JSON y lo convierte usando [fromJson].
  /// Devuelve null si la clave no existe todavía.
  static Future<T?> load<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return null;
    return fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Lee una lista JSON y convierte cada elemento usando [fromJson].
  /// Devuelve lista vacía si la clave no existe.
  static Future<List<T>> loadList<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Elimina una clave de SharedPreferences.
  static Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}