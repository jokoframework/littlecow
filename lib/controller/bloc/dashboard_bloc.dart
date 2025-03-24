library dashboard_bloc;

import 'dart:developer' as developer;
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../model/post_model.dart';

part '../events/dashboard_event.dart';

part '../states/dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc() : super(DashboardInitial()) {
    on<LoadDataEvent>(_onLoadDataEvent);
    on<LoadPostBodyEvent>(_onLoadPostBodyEvent);
  }

  void _onLoadDataEvent(LoadDataEvent event, Emitter<DashboardState> emit) {
    developer.log('LoadDataEvent triggered', name: 'DashboardBloc');
    emit(DashboardLoading());
    // Aquí usarías datos mock
    final posts = List.generate(
        5,
        (index) =>
            //agrega un body de 3 líneas tipo lorep ipsum
            Post(
              id: index,
                title: 'Post $index',
                body:
                    'Lorem ipsum $index dolor sit amet, consectetur adipiscing elit. Nullam nec nunc nec nunc. Donec nec nunc nec nunc. Donec nec nunc nec nunc.'));
    emit(DashboardLoaded(posts: posts));
    developer.log('DashboardLoaded state emitted', name: 'DashboardBloc');
  }

  void _onLoadPostBodyEvent(LoadPostBodyEvent event, Emitter<DashboardState> emit) async {
    emit(PostBodyLoading());
    // Simulación de un retardo
    await Future.delayed(Duration(seconds: 2));
    final updatedPost = Post(
      id: event.postId,
      title: 'Post ${event.postId}',
      body: 'Este es un contenido muy largo del post ${event.postId}. Aquí puedes poner mucho texto para simular una carga larga. Lorem ipsum dolor sit amet, consectetur adipiscing elit...',
    );
    emit(PostBodyLoaded(post: updatedPost));
  }
}

