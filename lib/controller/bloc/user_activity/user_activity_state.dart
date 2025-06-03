import 'package:equatable/equatable.dart';

abstract class UserActivityState extends Equatable {
  const UserActivityState();

  @override
  List<Object?> get props => [];
}
class UserActivityInitial extends UserActivityState {}
class UserActivityActive extends UserActivityState {}
class UserActivityInactive extends UserActivityState {}