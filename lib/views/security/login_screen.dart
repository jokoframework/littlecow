import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer' as developer;

import '../../controller/bloc/auth_bloc.dart';
import '../../controller/events/auth_event.dart';
import '../../controller/states/auth_state.dart';
import 'package:littlecow/presentation/widgets/app_snackbar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  /// Método para manejar el inicio de sesión
  /// 
  _handleLogin() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    if (username.isNotEmpty && password.isNotEmpty) {
      context.read<AuthBloc>().add(AuthLoggedIn(username: username, password: password));
    } else {
      AppSnackBar.showError(
        context: context,
        message: 'Por favor, complete todos los campos.',
        duration: const Duration(seconds: 4),
      );
    }
  }
  /// Método para manejar el error de autenticación
  ///   
  _handleError(AuthState state) {
    if (state is AuthFailure) {
      AppSnackBar.showError(
        context: context,
        message: state.message,
        duration: const Duration(seconds: 4),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    developer.log('LoginScreen built', name: 'LoginScreen');
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            _handleError(state);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              return Column(
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
                    onPressed: _handleLogin,                   
                    child: const Text('Iniciar Sesión'),
                  ),
                ],
              );
            },
          ),
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