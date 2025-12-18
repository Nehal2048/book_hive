import 'package:book_hive/main_navigation.dart';
import 'package:book_hive/pages/sign_up.dart';
import 'package:flutter/material.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String? _emailError;
  String? _passwordError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 400),
          padding: EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.deepPurple.shade50, blurRadius: 16),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hive, color: Colors.deepPurple, size: 48),
              SizedBox(height: 16),
              Text(
                'BookHive',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              SizedBox(height: 24),
              TextField(
                controller: emailController,
                onChanged: (v) {
                  if (_emailError != null && v.trim().isNotEmpty) {
                    setState(() => _emailError = null);
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 2),
                  ),
                ).copyWith(errorText: _emailError),
              ),
              SizedBox(height: 16),
              TextField(
                controller: passwordController,
                onChanged: (v) {
                  if (_passwordError != null && v.isNotEmpty) {
                    setState(() => _passwordError = null);
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 2),
                  ),
                ).copyWith(errorText: _passwordError),
                obscureText: true,
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // final email = emailController.text.trim();
                    // final password = passwordController.text;

                    // String? emailErr;
                    // String? passErr;
                    // if (email.isEmpty) emailErr = 'Email is required';
                    // if (password.isEmpty) passErr = 'Password is required';

                    // if (emailErr != null || passErr != null) {
                    //   setState(() {
                    //     _emailError = emailErr;
                    //     _passwordError = passErr;
                    //   });
                    //   return;
                    // }

                    // Proceed to main app (demo)
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => MainNavigation()),
                    );
                  },
                  child: Text('Login'),
                ),
              ),
              SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => SignUpPage()),
                    );
                  });
                },
                child: Text('Create an account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
