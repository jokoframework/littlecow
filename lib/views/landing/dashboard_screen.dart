import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../controller/bloc/dashboard/dashboard_bloc.dart';
import '../../controller/bloc/auth/auth_bloc.dart';
import '../../controller/bloc/auth/auth_event.dart';
import '../../controller/bloc/auth/auth_state.dart';
import 'notification_screen.dart';
import '../components/app_drawer.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DashboardBloc()..add(LoadDataEvent()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
          actions: [
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                if (authState is AuthAuthenticated) {
                  final user = authState.user;
                  return IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      developer.log(
                          'Notifications icon pressed for user: ${user.name} (ID: ${user.id})',
                          name: 'DashboardScreen');
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => NotificationsScreen(user: user),
                        ),
                      );
                    },
                    tooltip: 'Ver notificaciones',
                  );
                } else {
                  return IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.grey),
                    onPressed: () {
                      context.read<AuthBloc>().add(AuthLoggedOut());
                    },
                    tooltip: 'Iniciar sesión para ver notificaciones',
                  );
                }
              },
            ),
          ],
        ),
        drawer: const AppDrawer(),
        body: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is DashboardLoaded) {
              return ListView.builder(
                itemCount: state.posts.length,
                itemBuilder: (_, index) => ListTile(
                  title: Text(state.posts[index].title),
                  onTap: () =>
                      _showPostBodyModal(context, state.posts[index].id),
                ),
              );
            }
            return const Center(child: Text('Something went wrong!'));
          },
        ),
      ),
    );
  }

  void _showPostBodyModal(BuildContext context, int postId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(
              value: BlocProvider.of<DashboardBloc>(context),
            ),
            BlocProvider.value(
              value: BlocProvider.of<AuthBloc>(context),
            ),
          ],
          child: _PostBodyDialog(postId: postId),
        );
      },
    );
  }
}

class _PostBodyDialog extends StatelessWidget {
  final int postId;

  const _PostBodyDialog({required this.postId});

  @override
  Widget build(BuildContext context) {
    context.read<DashboardBloc>().add(LoadPostBodyEvent(postId: postId));
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(context).pop();
        }
      },
      child: Dialog(
        child: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            if (state is PostBodyLoading) {
              return const Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text("Cargando contenido..."),
                  ],
                ),
              );
            } else if (state is PostBodyLoaded && state.post.id == postId) {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(state.post.title,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text(state.post.body),
                    ],
                  ),
                ),
              );
            }
            return const Text("Error al cargar el post");
          },
        ),
      ),
    );
  }
}
