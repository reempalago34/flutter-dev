import '../models/user.dart';
import 'api_service.dart';

/// Respuesta de `POST /auth/login`: tokens + `user` (UserMe).
class AuthSession {
  final String accessToken;
  final String refreshToken;
  final UserMe user;

  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });
}

/// Respuesta de `POST /auth/register`: la cuenta se crea pero pide código
/// de 6 dígitos (`sentTo` enmascarado, `demoCode` si no hay SMTP).
class RegisterResult {
  final String id;
  final String username;
  final String sentTo;
  final String? demoCode;

  const RegisterResult({
    required this.id,
    required this.username,
    required this.sentTo,
    this.demoCode,
  });

  factory RegisterResult.fromJson(Map<String, dynamic> json) => RegisterResult(
        id: json['id'] as String,
        username: json['username'] as String,
        sentTo: json['sentTo'] as String? ?? '',
        demoCode: json['demoCode'] as String?,
      );
}

/// Respuesta de `POST /auth/verify-register`.
class VerifyResult {
  final bool ok;
  final String? username;
  final String? sentTo;
  final String? demoCode;

  const VerifyResult({
    required this.ok,
    this.username,
    this.sentTo,
    this.demoCode,
  });

  factory VerifyResult.fromJson(Map<String, dynamic> json) => VerifyResult(
    ok: json['ok'] as bool? ?? false,
    username: json['username'] as String?,
    sentTo: json['sentTo'] as String?,
    demoCode: json['demoCode'] as String?,
  );
}

class AuthService {
  /// `POST /auth/forgot-password` → envía código de recuperación por email.
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    return await ApiService.postJson(
      '/auth/forgot-password',
      body: {'email': email},
      auth: false,
    ) as Map<String, dynamic>;
  }

  /// `POST /auth/reset-password` → valida el código y guarda la nueva clave.
  static Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    await ApiService.postJson(
      '/auth/reset-password',
      body: {'email': email, 'code': code, 'password': password},
      auth: false,
    );
  }

  /// `POST /auth/login` → tokens + usuario; guarda el par de tokens.
  static Future<AuthSession> login(String email, String password) async {
    final data = await ApiService.postJson(
      '/auth/login',
      body: {'email': email, 'password': password},
      auth: false,
    ) as Map<String, dynamic>;

    await ApiService.saveTokens(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
    );
    return AuthSession(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
      user: UserMe.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  /// `POST /auth/register` → paso 1: crea la cuenta y envía el código.
  static Future<RegisterResult> register({
    required String email,
    required String username,
    required String password,
    required String fullName,
    required int age,
  }) async {
    final data = await ApiService.postJson(
      '/auth/register',
      body: {
        'email': email,
        'username': username,
        'password': password,
        'fullName': fullName,
        'age': age,
      },
      auth: false,
    ) as Map<String, dynamic>;
    return RegisterResult.fromJson(data);
  }

  /// `POST /auth/verify-register` → paso 2: confirma el código
  /// (`resend: true` lo reenvía).
  static Future<VerifyResult> verifyRegister({
    required String email,
    String? code,
    bool resend = false,
  }) async {
    final data = await ApiService.postJson(
      '/auth/verify-register',
      body: {'email': email, 'code': ?code, 'resend': resend},
      auth: false,
    ) as Map<String, dynamic>;
    return VerifyResult.fromJson(data);
  }

  /// `POST /auth/guest` → invitado de solo lectura con sesión propia.
  static Future<AuthSession> guest({String? username}) async {
    final data = await ApiService.postJson(
      '/auth/guest',
      body: {'username': username},
      auth: false,
    ) as Map<String, dynamic>;

    await ApiService.saveTokens(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
    );
    return AuthSession(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
      user: UserMe(
        id: data['id'] as String,
        email: '',
        username: data['username'] as String,
        role: 'USER',
        language: 'es',
        isGuest: data['isGuest'] as bool? ?? true,
        isPrivate: false,
        tourCompleted: false,
        devCoins: 0,
        createdAt: DateTime.now(),
      ),
    );
  }

  /// `GET /auth/me` → usuario del token vigente.
  static Future<UserMe> getMe() async {
    final data = await ApiService.getJson('/auth/me');
    return UserMe.fromJson(data as Map<String, dynamic>);
  }

  static Future<void> logout() => ApiService.clearTokens();

  static Future<bool> isLoggedIn() => ApiService.hasTokens();
}
