import 'package:book_hive/pages/splash_screen.dart';
import 'package:flutter/material.dart';
import 'main_navigation.dart';
import 'package:book_hive/pages/dashboard/dashboard.dart';
import 'package:book_hive/pages/sign_up.dart';
import 'package:book_hive/pages/sign_in.dart';
import 'package:book_hive/services/app_controller.dart';
import 'package:book_hive/shared/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/instance_manager.dart';

// void main() {
//   runApp(BookHiveApp());
// }

var storage = const FlutterSecureStorage();
Future<void> main() async {
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return const Center(child: Text("Ran into an error"));
  };
  final AppController c = Get.put(AppController());
  c.token = await storage.read(key: 'token') ?? "";
  c.userID = await storage.read(key: 'userID') ?? "";
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
        '/': (context) => const SplashScreen(),
        // '/': (context) => const Dashboard(),
        '/dashboard': (context) => const DashboardScreen(),
        '/login': (context) => const SignInPage(),
      },
      supportedLocales: const [Locale('en', 'UK')],
      theme: themeData,
    );
  }
}
