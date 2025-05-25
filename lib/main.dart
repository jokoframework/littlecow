import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:littlecow/views/security/login_screen.dart';
import 'package:littlecow/views/landing/dashboard_screen.dart';
import 'package:littlecow/controller/events/auth_event.dart';
import 'package:littlecow/controller/states/auth_state.dart';
import 'controller/bloc/auth_bloc.dart';
import 'controller/bloc/dashboard_bloc.dart';
import 'controller/bloc/notification_bloc.dart';
import 'package:littlecow/presentation/widgets/app_snackbar.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc()..add(AuthCheckRequested()),
        ),
        BlocProvider<DashboardBloc>(
          create: (context) => DashboardBloc(),
        ),
        BlocProvider<NotificationBloc>(
          create: (context) => NotificationBloc(),
        ),
      ],
      child: MaterialApp(
        title: 'Little Cow',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthFailure) {
              AppSnackBar.showError(
                context: context,
                message: state.message,
                duration: const Duration(seconds: 4),
              );
            }
          },
          builder: (context, state) {
            if (state is AuthInitial || state is AuthLoading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (state is AuthAuthenticated) {
              return const DashboardScreen();
            }
            if (state is AuthUnauthenticated) {
              return const LoginScreen();
            }
            if (state is AuthFailure) {
              return const LoginScreen();
            }
            if (state is AuthTokenInvalidated) {
              return const LoginScreen();
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}