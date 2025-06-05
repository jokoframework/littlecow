import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:littlecow/controller/bloc/auth/auth_bloc.dart';
import 'package:littlecow/controller/bloc/auth/auth_state.dart';
import 'package:littlecow/controller/bloc/user_activity/user_activity_bloc.dart';
import 'package:littlecow/controller/bloc/user_activity/user_activity_event.dart';

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
  Timer? _debounceTimer;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final authState = context.read<AuthBloc>().state;
        setState(() {
          _isAuthenticated = authState is AuthAuthenticated;
        });
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
        _isAuthenticated = authState is AuthAuthenticated;
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
    if (!_isAuthenticated) {
      return;
    }

    if (_debounceTimer?.isActive ?? false) return;

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      try {
        context.read<UserActivityBloc>().add(UserActivityResetTimer());
      } catch (e) {
        debugPrint('❌ UserActivityDetector: Error resetting timer: $e');
      }
    });
  }
}
