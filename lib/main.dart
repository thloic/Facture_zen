import 'package:facture_zen/features/home/viewmodels/home_viewmodel.dart';
import 'package:facture_zen/features/home/views/home_screen.dart';
import 'package:facture_zen/features/invoicing/views/invoice_history_screen.dart';
import 'package:facture_zen/features/invoicing/views/subscription_screen.dart';
import 'package:facture_zen/features/invoicing/views/voice_recording_screen.dart';
import 'package:facture_zen/features/profile/views/profile_screenn.dart';
import 'package:facture_zen/features/notifications/views/notifications_screen.dart';
import 'package:facture_zen/revenue_cat_util.dart' as revenue_cat;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'common/services/auth_service.dart';
import 'common/services/pin_service.dart';
import 'common/services/firebase_invoice_service.dart';
import 'features/profile/services/firebase_profile_service.dart';
import 'features/auth/viewmodels/login_viewmodel.dart';
import 'features/auth/viewmodels/register_viewmodel.dart';
import 'features/auth/viewmodels/forgot_password_viewmodel.dart';
import 'features/auth/views/login_screen.dart';
import 'features/auth/views/register_screen.dart';
import 'features/auth/views/forgot_password_screen.dart';
import 'features/auth/views/pin_setup_screen.dart';
import 'features/auth/views/pin_login_screen.dart';
import 'features/invoicing/viewmodels/subscription_view_model.dart';
import 'features/settings/views/company_setup_screen.dart';
import 'features/invoicing/viewmodels/invoice_history_viewmodel.dart';
import 'features/invoicing/viewmodels/voice_recording_viewmodel.dart';
import 'features/profile/viewmodels/profile_viewmodel.dart';
import 'features/profile/viewmodels/company_profile_viewmodel.dart';
import 'features/profile/views/company_profile_setup_screen.dart';
import 'features/notifications/viewmodels/notification_viewmodel.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  // Charger les variables d'environnement (.env)
  await dotenv.load(fileName: ".env");

  await revenue_cat.initialize(
    "App Store API Key",
    dotenv.env['REVENUE_CAT_PLAY_STORE_KEY'] ?? '',
    debugLogEnabled: true,
    loadDataAfterLaunch: true,
  );
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool _isAppInBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Détecter quand l'app passe en arrière-plan
    if (state == AppLifecycleState.paused) {
      _isAppInBackground = true;
    }

    // Détecter quand l'app revient au premier plan
    if (state == AppLifecycleState.resumed && _isAppInBackground) {
      _isAppInBackground = false;
      _checkPinOnResume();
    }
  }

  /// Vérifie si un PIN est configuré et force la navigation vers l'écran de PIN
  /// SEULEMENT si l'utilisateur est toujours connecté
  Future<void> _checkPinOnResume() async {
    // Attendre un peu pour que le widget tree soit stable
    await Future.delayed(const Duration(milliseconds: 300));

    final authService = AuthService();
    final pinService = PinService();

    // 1. Vérifier si l'utilisateur est TOUJOURS connecté (pas déconnecté)
    final isAuthenticated = authService.isAuthenticated;
    debugPrint('🔐 Resume - isAuthenticated: $isAuthenticated');
    
    // 2. Si déconnecté, ne rien faire (l'app reste sur l'écran de login)
    if (!isAuthenticated) {
      debugPrint('🔐 Resume - Utilisateur non authentifié, pas de PIN demandé');
      return;
    }

    // 3. Si connecté ET a un PIN configuré → demander le PIN
    final hasPin = await pinService.hasPin();
    debugPrint('🔐 Resume - hasPin: $hasPin');
    
    if (hasPin) {
      debugPrint('🔐 Resume - Navigation forcée vers /pin-login');
      // Forcer la navigation vers l'écran de PIN en supprimant tout l'historique
      _navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/pin-login',
        (route) => false, // Supprimer toutes les routes précédentes
      );
    } else {
      debugPrint('🔐 Resume - Pas de PIN configuré, pas de redirection');
    }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final invoiceService = FirebaseInvoiceService();
    
    return MultiProvider(
      providers: [
        Provider<AuthService>.value(value: authService),
        Provider<FirebaseInvoiceService>.value(value: invoiceService),
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
        ChangeNotifierProvider(
          create: (_) => HomeViewModel(invoiceService: invoiceService),
        ),
        ChangeNotifierProvider(create: (_) => SubscriptionViewModel()), // ✅ AJOUTÉ
        ChangeNotifierProvider(create: (_) => VoiceRecordingViewModel()),
        ChangeNotifierProvider(
          create: (_) => InvoiceHistoryViewModel(invoiceService: invoiceService),
        ),
        ChangeNotifierProvider(create: (_) => NotificationViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => CompanyProfileViewModel()),
      ],
      child: MaterialApp(
        navigatorKey: _navigatorKey,
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
          '/company-profile-setup': (context) => const CompanyProfileSetupScreen(),
          '/home': (context) => const HomeScreen(),
          '/subscription-screen':(context)=>const SubscriptionScreen(),
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

    // ⚠️ IMPORTANT: Attendre que Firebase Auth ait restauré l'état de l'utilisateur
    // Le premier événement du stream contient l'état actuel après restauration
    final user = await authService.authStateChanges.first;
    final isAuthenticated = user != null;
    debugPrint('🔐 AppInitializer - isAuthenticated: $isAuthenticated (user: ${user?.email})');

    if (isAuthenticated) {
      // Utilisateur connecté - d'abord vérifier si un PIN est configuré
      final hasPin = await pinService.hasPin();
      debugPrint('🔐 AppInitializer - hasPin: $hasPin');
      
      if (hasPin) {
        // PIN configuré - aller à l'écran de connexion par PIN
        debugPrint('🔐 AppInitializer - Navigation vers /pin-login');
        return '/pin-login';
      }

      // Pas de PIN - vérifier si le profil entreprise existe
      final profileService = FirebaseProfileService();
      final hasProfile = await profileService.hasProfile();
      debugPrint('📋 AppInitializer - hasProfile: $hasProfile');

      // Si pas de profil, rediriger vers la configuration
      if (!hasProfile) {
        debugPrint('📋 AppInitializer - Redirection vers configuration profil');
        return '/company-profile-setup';
      }

      // Profil existe et pas de PIN - aller directement à l'accueil
      debugPrint('🔐 AppInitializer - Navigation vers /home (pas de PIN)');
      return '/home';
    } else {
      // Utilisateur non connecté - aller à l'écran de login
      debugPrint('🔐 AppInitializer - Navigation vers /login (non authentifié)');
      return '/login';
    }
  }
}