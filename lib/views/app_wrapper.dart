import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:littlecow/controller/bloc/auth/auth_state.dart';
import 'package:littlecow/controller/bloc/auth/auth_bloc.dart';
import 'package:littlecow/controller/bloc/user_activity/user_activity_bloc.dart';
import 'package:littlecow/controller/bloc/user_activity/user_activity_event.dart';
import 'package:littlecow/presentation/widgets/app_snackbar.dart';
import 'package:littlecow/views/security/login_screen.dart';
import 'package:littlecow/views/landing/dashboard_screen.dart';
import 'package:littlecow/views/security/connection_error_screen.dart';

/// Pantalla wrapper que contiene un BlocListener para escuchar cambios de autenticación
/// y manejar el contenido apropiado en función del estado de autenticación.
class AppWrapper extends StatelessWidget {
  const AppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        debugPrint('AppWrapper: AuthBloc state changed: $state');
        if (state is AuthAuthenticated) {
          context.read<UserActivityBloc>().add(UserActivityStarted());
        }
        if (state is AuthUnauthenticated && state.message.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            AppSnackBar.showError(
              context: context,
              message: state.message,
            );
          });
        }
      },
      builder: (context, state) {
        if (state is AuthLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (state is AuthAuthenticated) {
          return  const DashboardScreen();
        } else if (state is AuthUnauthenticated) {
          if (state.message.contains('conexión') ||
              state.message.contains('internet') ||
              state.message.contains('No hay conexión')) {
            return const ConnectionErrorScreen();
          }
          return const LoginScreen();
        }        
        return const LoginScreen();
      },
    );
  }
}
