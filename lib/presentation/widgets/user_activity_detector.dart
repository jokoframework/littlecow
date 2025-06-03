import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:littlecow/controller/bloc/auth/auth_bloc.dart';
import 'package:littlecow/controller/bloc/auth/auth_state.dart';
import 'package:littlecow/controller/bloc/user_activity/user_activity_bloc.dart';
import 'package:littlecow/controller/bloc/user_activity/user_activity_event.dart';

/// Widget que detecta la actividad del usuario y reinicia el temporizador de inactividad.
/// Debe envolver toda la aplicación o las pantallas donde se quiera detectar la actividad.
class UserActivityDetector extends StatefulWidget {
  final Widget child;

  const UserActivityDetector({
    super.key,
    required this.child,
  });

  @override
  State<UserActivityDetector> createState() => _UserActivityDetectorState();
}

class _UserActivityDetectorState extends State<UserActivityDetector> {
  // Utilizar un temporizador para evitar enviar eventos con demasiada frecuencia
  Timer? _debounceTimer;
  bool _isAuthenticated = false;
  
  @override
  void initState() {
    super.initState();
    // Verificar estado inicial de autenticación después de que el widget esté montado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final authState = context.read<AuthBloc>().state;
        setState(() {
          _isAuthenticated = authState is AuthAuthenticated;
        });
        print('🔍 UserActivityDetector: Initial authentication state: $_isAuthenticated');
      }
    });
  }
  
  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, authState) {
        final wasAuthenticated = _isAuthenticated;
        _isAuthenticated = authState is AuthAuthenticated;
        print('🔍 UserActivityDetector: Auth state changed - Was: $wasAuthenticated, Now: $_isAuthenticated');
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent, 
        onTap: () => _resetTimer(context),
        onPanUpdate: (_) => _resetTimer(context),
        child: Listener(
          onPointerMove: (_) => _resetTimer(context),
          onPointerDown: (_) => _resetTimer(context),
          child: widget.child,
        ),
      ),
    );
  }

  void _resetTimer(BuildContext context) {
    // Solo resetear el temporizador si el usuario está autenticado
    if (!_isAuthenticated) {
      print('⏱️ UserActivityDetector: Skipping timer reset - User is not authenticated');
      return;
    }    
    
    // Evitar múltiples resets en poco tiempo
    if (_debounceTimer?.isActive ?? false) return;
    
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      
      try {
        print('⏱️ UserActivityDetector: Resetting activity timer');
        context.read<UserActivityBloc>().add(UserActivityResetTimer());
      } catch (e) {
        print('❌ UserActivityDetector: Error resetting timer: $e');
      }
    });
  }
}
