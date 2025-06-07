import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../controller/bloc/auth/auth_bloc.dart';
import '../../controller/bloc/auth/auth_event.dart';
import '../../controller/bloc/auth/auth_state.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              return DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(
                      Icons.account_circle,
                      color: Colors.white,
                      size: 60,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      state is AuthAuthenticated ? state.user.name : 'Invitado',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Inicio'),
            onTap: () {
              Navigator.pop(context); 
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesión'),
            onTap: () {
              final authBloc = context.read<AuthBloc>();              
              Navigator.pop(context);              
              showDialog(
                context: context,
                builder: (BuildContext dialogContext) {
                  return BlocListener<AuthBloc, AuthState>(
                    listener: (context, state) {
                      if (state is AuthUnauthenticated) {
                        Navigator.of(dialogContext).pop();
                      }
                    },
                    child: AlertDialog(
                      title: const Text('Cerrar sesión'),
                      content: const Text('¿Estás seguro que deseas cerrar sesión?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                          },
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () {
                            authBloc.add(AuthLoggedOut());
                          },
                          child: const Text('Aceptar'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
