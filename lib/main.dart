import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/auth/viewmodels/login_viewmodel.dart';
import 'features/auth/views/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
        // Ajoutez d'autres providers ici
      ],
      child: MaterialApp(
        title: 'FactureZen',
        theme: ThemeData(primaryColor: const Color(0xFF5B5FC7)),
        home: const LoginScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
