import 'dart:async';

import 'package:bloc/bloc.dart';

import 'user_activity_event.dart';
import 'user_activity_state.dart';

class UserActivityBloc extends Bloc<UserActivityEvent, UserActivityState> {
  final Duration inactivityDuration;
  Timer? _inactivityTimer;

  UserActivityBloc({this.inactivityDuration = const Duration(minutes: 15)})
      : super(UserActivityInitial()) {
    on<UserActivityStarted>(_onUserActivityStarted);
    on<UserActivityResetTimer>(_onUserActivityResetTimer);
    on<UserActivityCheckInactivity>(_onUserActivityCheckInactivity);
  }
  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(inactivityDuration, () {
      add(UserActivityCheckInactivity());
    });
  }

  void _onUserActivityStarted(
    UserActivityStarted event,
    Emitter<UserActivityState> emit,
  ) {
    emit(UserActivityActive());
    _startInactivityTimer();
  }

  void _onUserActivityResetTimer(
    UserActivityResetTimer event,
    Emitter<UserActivityState> emit,
  ) {
    _inactivityTimer?.cancel();
    _startInactivityTimer();
    if (state is! UserActivityActive) {
      emit(UserActivityActive());
    }
  }

  void _onUserActivityCheckInactivity(
    UserActivityCheckInactivity event,
    Emitter<UserActivityState> emit,
  ) {
    emit(UserActivityInactive());
  }
  @override
  Future<void> close() {
    _inactivityTimer?.cancel();
    return super.close();
  }
}