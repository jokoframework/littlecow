import 'package:flutter/material.dart';
import 'dart:developer' as developer;

import 'package:littlecow/presentation/widgets/app_snackbar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:littlecow/controller/bloc/auth/auth_bloc.dart';
import 'package:littlecow/controller/bloc/auth/auth_event.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  void handleLogin() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    
    if (username.isNotEmpty && password.isNotEmpty) {
      developer.log('Login attempt with: $username', name: 'LoginScreen');
      context.read<AuthBloc>().add(
        AuthLoggedIn(username: username, password: password),
      );
    } else {
      AppSnackBar.showError(
        context: context,
        message: 'Por favor, complete todos los campos.',
        duration: const Duration(seconds: 4),
      );
    }
  }  
  
  @override
  Widget build(BuildContext context) {
    developer.log('LoginScreen built', name: 'LoginScreen');
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: handleLogin,                   
              child: const Text('Iniciar Sesión'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}