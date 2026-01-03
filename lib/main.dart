import 'package:book_hive/main_navigation.dart';
import 'package:book_hive/pages/sign_up.dart';
import 'package:book_hive/services/auth_gate.dart';
import 'package:book_hive/shared/const.dart';
import 'package:book_hive/shared/keys.dart';
import 'package:flutter/material.dart';
import 'package:book_hive/pages/sign_in.dart';
import 'package:book_hive/services/app_controller.dart';
import 'package:book_hive/shared/theme.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/instance_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_strategy/url_strategy.dart';

// void main() {
//   runApp(BookHiveApp());
// }

var storage = const FlutterSecureStorage();
Future<void> main() async {
  // Remove the hash (#) from web URLs
  setPathUrlStrategy();

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return const Center(child: Text("Ran into an error"));
  };
  final AppController c = Get.put(AppController());
  c.token = await storage.read(key: 'token') ?? "";
  c.userID = await storage.read(key: 'userID') ?? "";

  await Supabase.initialize(
    url: apiCallLinkProductionLogin,
    anonKey: apiKeySupabase,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // showPerformanceOverlay: true,
      debugShowCheckedModeBanner: false,
      title: 'Book Hive',
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGate(),
        // '/': (context) => const Dashboard(),
        '/dashboard': (context) => const MainNavigation(),
        '/login': (context) => const SignInPage(),
        '/signup': (context) => const SignUpPage(),
      },
      supportedLocales: const [Locale('en', 'UK')],
      theme: themeData,
    );
  }
}
