import 'package:flutter/material.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:littlecow/views/security/login_screen.dart';

import 'controller/bloc/auth_bloc.dart';
import 'controller/bloc/dashboard_bloc.dart'; // Importa DashboardBloc

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(),
        ),
        BlocProvider<DashboardBloc>(
          create: (context) => DashboardBloc()..add(LoadDataEvent()), // Inicia el evento de carga de datos
        ),
      ],
      child: MaterialApp(
      title: 'BLoC Example',
        home: LoginScreen(),
      ),
    );
  }
}