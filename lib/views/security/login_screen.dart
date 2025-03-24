import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer' as developer;

import '../../controller/bloc/auth_bloc.dart';
import '../../controller/events/auth_event.dart';
import '../landing/dashboard_screen.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    developer.log('LoginScreen built', name: 'LoginScreen');
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                developer.log('Login button pressed', name: 'LoginScreen');
                context.read<AuthBloc>().add(
                    LoginEvent(username: 'mockUser', password: 'mockPassword'));
                Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => DashboardScreen()));
                developer.log('Navigating to DashboardScreen', name: 'LoginScreen');
              },
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}