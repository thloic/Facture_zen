import 'package:facture_zen/features/home/viewmodels/home_viewmodel.dart';
import 'package:facture_zen/features/home/views/home_screen.dart';
import 'package:facture_zen/features/invoicing/views/invoice_history_screen.dart';
import 'package:facture_zen/features/invoicing/views/voice_recording_screen.dart';
import 'package:facture_zen/features/profile/views/profile_screenn.dart';
import 'package:facture_zen/features/notifications/views/notifications_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'common/services/auth_service.dart';
import 'common/services/pin_service.dart';
import 'features/auth/viewmodels/login_viewmodel.dart';
import 'features/auth/viewmodels/register_viewmodel.dart';
import 'features/auth/viewmodels/forgot_password_viewmodel.dart';
import 'features/auth/views/login_screen.dart';
import 'features/auth/views/register_screen.dart';
import 'features/auth/views/forgot_password_screen.dart';
import 'features/auth/views/pin_setup_screen.dart';
import 'features/auth/views/pin_login_screen.dart';
import 'features/settings/views/company_setup_screen.dart';
import 'features/invoicing/viewmodels/invoice_history_viewmodel.dart';
import 'features/invoicing/viewmodels/voice_recording_viewmodel.dart';
import 'features/profile/viewmodels/profile_viewmodel.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return MultiProvider(
      providers: [
        Provider<AuthService>.value(value: authService),
        ChangeNotifierProvider(
          create: (_) => ProfileViewModel(authService: authService),
        ),
        ChangeNotifierProvider(
          create: (_) => LoginViewModel(authService: authService),
        ),
        ChangeNotifierProvider(
          create: (_) => RegisterViewModel(authService: authService),
        ),
        ChangeNotifierProvider(
          create: (_) => ForgotPasswordViewModel(authService: authService),
        ),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => VoiceRecordingViewModel()),
        ChangeNotifierProvider(create: (_) => InvoiceHistoryViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
      ],
      child: MaterialApp(
        title: 'FactureZen',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFF5B5FC7),
          fontFamily: 'SF Pro Display', // iOS default
        ),
        home: const AppInitializer(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/pin-setup': (context) => const PinSetupScreen(),
          '/pin-login': (context) => const PinLoginScreen(),
          '/company-setup': (context) => const CompanySetupScreen(),
          '/home': (context) => const HomeScreen(),
          '/record': (context) => const VoiceRecordingScreen(),
          '/historiqueInvoicing': (context) => const InvoiceHistoryScreen(),
          '/settings': (context) => const ProfileScreen(),
          '/notifications': (context) => const NotificationsScreen(),
        },
      ),
    );
  }
}

/// AppInitializer
/// Détermine l'écran initial en fonction de l'état d'authentification et du PIN
class AppInitializer extends StatelessWidget {
  const AppInitializer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _determineInitialRoute(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Afficher un écran de chargement pendant la vérification
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF5B5FC7),
              ),
            ),
          );
        }

        // Rediriger vers la route appropriée
        final route = snapshot.data ?? '/login';
        
        // Utiliser Navigator.pushReplacementNamed après le premier frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, route);
        });

        return const Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: CircularProgressIndicator(
              color: Color(0xFF5B5FC7),
            ),
          ),
        );
      },
    );
  }

  /// Détermine la route initiale en fonction de l'état
  Future<String> _determineInitialRoute() async {
    final authService = AuthService();
    final pinService = PinService();

    // Vérifier si l'utilisateur est connecté à Firebase
    final isAuthenticated = authService.isAuthenticated;

    if (isAuthenticated) {
      // Utilisateur connecté - vérifier si un PIN est configuré
      final hasPin = await pinService.hasPin();
      
      if (hasPin) {
        // PIN configuré - aller à l'écran de connexion par PIN
        return '/pin-login';
      } else {
        // Pas de PIN - aller directement à l'accueil
        return '/home';
      }
    } else {
      // Utilisateur non connecté - aller à l'écran de login
      return '/login';
    }
  }
}