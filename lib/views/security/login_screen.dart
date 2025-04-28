import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer' as developer;

import '../../controller/bloc/auth_bloc.dart';
import '../../controller/events/auth_event.dart';
import '../../controller/states/auth_state.dart';
import '../landing/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Disparar el evento AuthStarted al construir la pantalla
    context.read<AuthBloc>().add(const AuthStarted());
  }

  @override
  Widget build(BuildContext context) {
    developer.log('LoginScreen built', name: 'LoginScreen');
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthInProgress) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is AuthLoginSuccess) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Mostrar SnackBar de éxito
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Login successful!')),
              );
              // Redirigir al Dashboard
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => DashboardScreen()),
              );
            });
            return const SizedBox.shrink(); // Retorna un widget vacío mientras se redirige
          } else if (state is AuthFailure) {
            // Mostrar SnackBar de error
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${state.message}')),
              );
            });
          }

          return Padding(
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
                  onPressed: () {
                    final username = _usernameController.text.trim();
                    final password = _passwordController.text.trim();
                    if (username.isNotEmpty && password.isNotEmpty) {
                      developer.log('Login button pressed', name: 'LoginScreen');
                      context.read<AuthBloc>().add(
                        AuthLoginRequested(name: username, password: password),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter both username and password')),
                      );
                    }
                  },
                  child: const Text('Login'),
                ),
              ],
            ),
          );
        },
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