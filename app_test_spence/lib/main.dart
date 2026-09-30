import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'router.dart'; // Lo crearemos en el siguiente paso

Future<void> main() async {
  // Asegura que los widgets de Flutter estén listos
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Supabase con tus credenciales
  await Supabase.initialize(
    url: 'https://ghitrgudwxoptddeuvlw.supabase.co',
    publishableKey: 'sb_publishable_bOuE3q1sdfpcMkdHqAFtsQ_3zExGJmA',
  );

  runApp(const SpenceApp());
}

class SpenceApp extends StatelessWidget {
  const SpenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos MaterialApp.router para la navegación con go_router
    return MaterialApp.router(
      title: 'Spence MentalHealth',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        fontFamily: 'Inter', // O la fuente que prefieras
      ),
      routerConfig: appRouter,
    );
  }
}
