import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'home_screen.dart';
import 'theme.dart';
import 'utils/dev_link.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  DevLink.initialize();
  // Los plugins web (file_picker para elegir imágenes, video_player,
  // pointer_interceptor...) se registran solos: Flutter genera el registrant
  // y lo invoca desde el entrypoint web.
  runApp(const DevPlayApp());
}

class DevPlayApp extends StatelessWidget {
  const DevPlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider()..checkAuth(),
      child: MaterialApp(
        title: 'DevPlay',
        debugShowCheckedModeBanner: false,
        theme: buildDevPlayTheme(),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (auth.isAuthenticated) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
