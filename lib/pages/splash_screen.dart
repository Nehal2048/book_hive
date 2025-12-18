import 'dart:async';
import 'package:book_hive/pages/sign_in.dart';
import 'package:flutter/material.dart';
import 'package:book_hive/pages/dashboard/dashboard.dart';
import 'package:get/instance_manager.dart';

import '../services/app_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  final AppController c = Get.put(AppController());

  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      Navigator.of(context).pushReplacement(
        (c.token == "" || c.userID == "")
            ? MaterialPageRoute(
                settings: const RouteSettings(name: "/login"),
                builder: (BuildContext context) {
                  return const SignInPage();
                },
              )
            : MaterialPageRoute(
                settings: const RouteSettings(name: "/dashboard"),
                builder: (BuildContext context) {
                  return const DashboardScreen();
                },
              ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Icon(Icons.hive, color: Colors.deepPurple, size: 100),
      ),
    );
  }
}
