import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:book_hive/main.dart';
import 'package:book_hive/services/app_controller.dart';
import 'package:book_hive/shared/const.dart';
import 'package:get/instance_manager.dart';
import 'package:http/http.dart' as http;

class AuthServices {
  final AppController c = Get.put(AppController());

  Future<String> signIn(userSignIn) async {
    try {
      final response = await http.post(
        Uri.parse("${apiCallLinkProduction}api/auth/signin"),
        headers: <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(userSignIn),
      );
      if (kDebugMode) {
        print(response.body);
      }
      if (response.statusCode == 200) {
        String token = jsonDecode(response.body)['data']['accessToken'];
        await storage.write(key: 'token', value: token);
        String userID = jsonDecode(response.body)['data']['userData']["_id"];
        await storage.write(key: 'userID', value: userID);
        c.userID = userID;
        c.token = token;
        return "Success";
      } else {
        return jsonDecode(response.body)['message'];
      }
    } catch (e) {
      debugPrint(e.toString());
      return e.toString();
    }
  }
}
