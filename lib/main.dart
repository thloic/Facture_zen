import 'package:facture_zen/features/home/viewmodels/home_viewmodel.dart';
import 'package:facture_zen/features/home/views/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/auth/viewmodels/login_viewmodel.dart';
import 'features/auth/viewmodels/register_viewmodel.dart';
import 'features/auth/views/login_screen.dart';
import 'features/auth/views/register_screen.dart';

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
        ChangeNotifierProvider(create: (_) => RegisterViewModel()),
        ChangeNotifierProvider(create: (_)=> HomeViewModel())
      ],
      child: MaterialApp(
        title: 'FactureZen',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFF5B5FC7),
          fontFamily: 'SF Pro Display', // iOS default
        ),
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home':(context)=> const HomeScreen()
        },
      ),
    );
  }
}
