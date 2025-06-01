import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:littlecow/controller/bloc/auth_bloc.dart';
import 'package:littlecow/controller/bloc/dashboard_bloc.dart';
import 'package:littlecow/controller/bloc/notification_bloc.dart';
import 'package:littlecow/controller/bloc/app_bloc_observer.dart';
import 'package:littlecow/data/auth_repository.dart';
import 'package:littlecow/data/notifications_repository.dart';
import 'package:littlecow/data/secure_storage_service.dart';
import 'package:littlecow/services/auth_service.dart';
import 'package:littlecow/services/notification_service.dart' show NotificationService;
import 'package:watch_it/watch_it.dart';

Future<void> initLocator() async {
  // Configure BlocObserver
  Bloc.observer = AppBlocObserver();

  // Register services
  di.registerLazySingleton<SecureStorageService>(() => SecureStorageService());
  di.registerLazySingleton<AuthService>(() => AuthService());
  di.registerLazySingleton<NotificationService>(() => NotificationService());

  // Register repositories
  di.registerLazySingleton<AuthRepository>(() => AuthRepository());
  di.registerLazySingleton<NotificationsRepository>(() => NotificationsRepository());

  // Register blocs
  di.registerSingleton<AuthBloc>(AuthBloc());
  di.registerFactory<DashboardBloc>(() => DashboardBloc());
  di.registerFactory<NotificationBloc>(() => NotificationBloc());
}
