import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:littlecow/controller/bloc/user_activity/user_activity_bloc.dart';
import 'package:littlecow/controller/bloc/user_activity/user_activity_event.dart';
import 'package:littlecow/core/di/locator_service.dart';
import 'package:littlecow/views/app_wrapper.dart';
import 'package:littlecow/controller/bloc/auth/auth_event.dart';
import 'package:watch_it/watch_it.dart';
import 'controller/bloc/auth/auth_bloc.dart';
import 'controller/bloc/dashboard/dashboard_bloc.dart';
import 'controller/bloc/notification/notification_bloc.dart';
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
        BlocProvider<UserActivityBloc>(
          create: (context) {
            return UserActivityBloc(
                inactivityDuration: const Duration(minutes: 15))
              ..add(UserActivityStarted());
          },
        ),
        BlocProvider<AuthBloc>(
          create: (context) {
            final authBloc = di<AuthBloc>()..add(AuthCheckRequested());
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final userActivityBloc =
                  BlocProvider.of<UserActivityBloc>(context, listen: false);
              authBloc.listenToUserActivity(userActivityBloc);
            });
            return authBloc;
          },
        ),
        BlocProvider<DashboardBloc>(
          create: (context) => di<DashboardBloc>(),
        ),
        BlocProvider<NotificationBloc>(
          create: (context) => di<NotificationBloc>(),
        ),
      ],
      child: UserActivityDetector(
        child: MaterialApp(
          title: 'Little Cow',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          home: const AppWrapper(),
        ),
      ),
    );
  }
}
