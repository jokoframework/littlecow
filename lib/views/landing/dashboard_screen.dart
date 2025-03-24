import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../controller/bloc/dashboard_bloc.dart';

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DashboardBloc()..add(LoadDataEvent()),
      child: Scaffold(
        appBar: AppBar(title: Text('Dashboard')),
        body: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading) {
              return Center(child: CircularProgressIndicator());
            } else if (state is DashboardLoaded) {
              return ListView.builder(
                itemCount: state.posts.length,
                itemBuilder: (_, index) => ListTile(
                  title: Text(state.posts[index].title),
                  onTap: () => _showPostBodyModal(context, state.posts[index].id),
                ),
              );
            }
            return Center(child: Text('Something went wrong!'));
          },
        ),
      ),
    );
  }

  void _showPostBodyModal(BuildContext context, int postId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BlocProvider.value(
          value: BlocProvider.of<DashboardBloc>(context),
          child: _PostBodyDialog(postId: postId),
        );
      },
    );
  }
}

class _PostBodyDialog extends StatelessWidget {
  final int postId;

  const _PostBodyDialog({Key? key, required this.postId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    context.read<DashboardBloc>().add(LoadPostBodyEvent(postId: postId));

        return Dialog(
            child: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            if (state is PostBodyLoading) {
                  return Padding(
                  padding: const EdgeInsets.all(20.0),
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
                        Text(state.post.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 10),
                          Text(state.post.body),
                      ],
                    ),
                    ),
                  );
            }
          return Text("Error al cargar el post");
          },
            ),
    );
  }
}
