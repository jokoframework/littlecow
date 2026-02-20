import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

class AppBlocObserver extends BlocObserver { 
  AppBlocObserver();

  @override
  void onCreate(BlocBase bloc) {
    debugPrint('📦 Bloc creado: ${bloc.runtimeType}');
    super.onCreate(bloc);
  }

  @override
  void onClose(BlocBase bloc) {
    debugPrint('🔒 Bloc cerrado: ${bloc.runtimeType}');
    super.onClose(bloc);
  }
  @override
  void onChange(BlocBase bloc, Change change) {
    debugPrint('🔄 Bloc cambiado: ${bloc.runtimeType}, Cambio: $change');
    super.onChange(bloc, change);
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    debugPrint('🚫 Bloc Error: ${bloc.runtimeType}, Error: $error');
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    debugPrint('📣 Bloc: ${bloc.runtimeType}, Event: $event');
    super.onEvent(bloc, event);
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
  }
}
