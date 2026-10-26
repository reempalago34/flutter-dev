import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';

/// Enlace profundo de DevPlay.
///
/// El perfil se comparte con una URL `?user=<username>`. Esta clase la
/// interpreta y la resuelve contra la API real (`GET /users/by-username/{u}`).
class DevLink {
  static const MethodChannel _channel = MethodChannel('devplay/deep_links');
  static final StreamController<Uri> _incomingLinks =
      StreamController<Uri>.broadcast();
  static bool _initialized = false;

  /// Parámetro de query que lleva el username del perfil.
  static const String userParam = 'user';

  /// Instala el receptor nativo de enlaces entrantes en Android.
  static void initialize() {
    if (kIsWeb || _initialized) return;
    _initialized = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'onLink' || call.arguments is! String) return;
      final uri = Uri.tryParse(call.arguments as String);
      if (uri != null) _incomingLinks.add(uri);
    });
  }

  /// Enlaces recibidos mientras la app ya está abierta.
  static Stream<Uri> get incomingLinks => _incomingLinks.stream;

  /// Usuario del enlace inicial, leído desde la URL web o el intent Android.
  static Future<String?> initialUsername() async {
    if (kIsWeb) return usernameFrom(Uri.base);
    try {
      final link = await _channel.invokeMethod<String>('getInitialLink');
      return link == null ? null : usernameFrom(Uri.parse(link));
    } on MissingPluginException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Extrae el username de perfil de una URL de DevPlay.
  ///
  /// Acepta `?user=alice`, `/#/user/alice` y URLs completas.
  static String? usernameFrom(Uri uri) {
    final fromQuery = uri.queryParameters[userParam];
    if (fromQuery != null && fromQuery.trim().isNotEmpty) {
      return fromQuery.trim();
    }
    // Formato por ruta: /#/user/alice
    final segments = uri.pathSegments;
    for (var i = 0; i < segments.length - 1; i++) {
      if (segments[i] == userParam && segments[i + 1].trim().isNotEmpty) {
        return segments[i + 1].trim();
      }
    }
    final hash = uri.fragment;
    if (hash.isNotEmpty) {
      final hashUri = Uri.tryParse('http://x/$hash');
      if (hashUri != null) {
        final fromHash = usernameFrom(hashUri);
        if (fromHash != null) return fromHash;
      }
    }
    return null;
  }

  /// Construye la URL pública de un perfil.
  static String profileUrl(String username, {String? origin}) {
    final base = origin ?? _currentOrigin();
    return '$base/?$userParam=$username';
  }

  /// Origen de la web; en Android se usa el dominio público de DevPlay.
  static String _currentOrigin() {
    final uri = Uri.base;
    if (uri.scheme == 'http' || uri.scheme == 'https') return uri.origin;
    return 'https://app.proyecto.sbs';
  }

  /// Resuelve el username de un enlace a su id de usuario real.
  ///
  /// Devuelve `null` si el usuario no existe o no se puede resolver.
  static Future<String?> resolveUserId(String username) async {
    try {
      return await ApiService.getJson(
        '/users/by-username/$username',
        auth: false,
      ).then((data) {
        final user = data['user'] as Map<String, dynamic>?;
        return user?['id'] as String?;
      });
    } catch (_) {
      return null;
    }
  }
}
