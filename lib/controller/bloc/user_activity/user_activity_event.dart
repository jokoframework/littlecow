import 'package:equatable/equatable.dart';

abstract class UserActivityEvent extends Equatable {
  const UserActivityEvent();
  @override
  List<Object?> get props => [];
}

class UserActivityStarted extends UserActivityEvent {}
class UserActivityResetTimer extends UserActivityEvent {}
class UserActivityCheckInactivity extends UserActivityEvent {}