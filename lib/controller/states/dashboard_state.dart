part of '../bloc/dashboard_bloc.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final List<Post> posts;

  DashboardLoaded({required this.posts});

  @override
  List<Object> get props => [posts];
}

class PostBodyLoading extends DashboardState {}

class PostBodyLoaded extends DashboardState {
  final Post post;

  PostBodyLoaded({required this.post});

  @override
  List<Object> get props => [post];
}