import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:littlecow/controller/bloc/user_activity/user_activity_bloc.dart';
import 'package:littlecow/controller/bloc/user_activity/user_activity_event.dart';
import 'package:littlecow/core/di/locator_service.dart';
import 'package:littlecow/views/landing/notification_screen.dart';
import 'package:littlecow/views/security/login_screen.dart';
import 'package:littlecow/views/landing/dashboard_screen.dart';
import 'package:littlecow/views/security/connection_error_screen.dart';
import 'package:littlecow/controller/bloc/auth/auth_event.dart';
import 'package:littlecow/controller/bloc/auth/auth_state.dart';
import 'controller/bloc/auth/auth_bloc.dart';
import 'controller/bloc/dashboard/dashboard_bloc.dart';
import 'controller/bloc/notification/notification_bloc.dart';
import 'package:littlecow/presentation/widgets/app_snackbar.dart';
import 'package:littlecow/presentation/widgets/user_activity_detector.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  initLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // UserActivityBloc debe estar antes que AuthBloc para que esté disponible
        BlocProvider<UserActivityBloc>(
          create: (context) {
            print('🔄 Creating UserActivityBloc and adding UserActivityStarted event');
            // Set a shorter inactivity duration for easier testing
            return UserActivityBloc(inactivityDuration: const Duration(seconds: 10))..add(UserActivityStarted());
          },
        ),
        BlocProvider<AuthBloc>(
          create: (context) {
            final authBloc = AuthBloc()..add(AuthCheckRequested());
            WidgetsBinding.instance.addPostFrameCallback((_) {
              try {
                final userActivityBloc = BlocProvider.of<UserActivityBloc>(context, listen: false);
                print('🔄 Setting up AuthBloc to listen to UserActivityBloc');
                authBloc.listenToUserActivity(userActivityBloc);
              } catch (e) {
                print('❌ Error setting up user activity listener: $e');
              }
            });
            return authBloc;
          },
        ),
        BlocProvider<DashboardBloc>(
          create: (context) => DashboardBloc(),
        ),
        BlocProvider<NotificationBloc>(
          create: (context) => NotificationBloc(),
        ),
      ],
      child: UserActivityDetector(
        child: MaterialApp(
          title: 'Little Cow',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/connection-error': (context) => const ConnectionErrorScreen(),
        },
        home: BlocListener<AuthBloc, AuthState>(
          listener: (context, authState) {
            debugPrint('AuthBloc state changed: $authState');
            if (authState is AuthAuthenticated) {
              // Iniciar el temporizador de actividad cuando el usuario se autentica
              context.read<UserActivityBloc>().add(UserActivityStarted());
              print('🚀 Main: User authenticated, starting activity timer');
              
              Navigator.of(context).pushNamed(
                '/dashboard',
              );
            }
            if (authState is AuthUnauthenticated) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (route) => route.isFirst, 
              );
                if(authState.message.isNotEmpty) {
                  AppSnackBar.showError(
                    context: context,
                    message: authState.message,
                  );
                }
              });
            }
          },
          child: const LoginScreen(),
        ),
      ),
    ),
    );
  }
}