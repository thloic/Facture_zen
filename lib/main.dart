import 'dart:io';

import 'package:facture_zen/features/home/viewmodels/home_viewmodel.dart';
import 'package:facture_zen/features/home/views/home_screen.dart';
import 'package:facture_zen/features/invoicing/views/invoice_history_screen.dart';
import 'package:facture_zen/features/invoicing/views/subscription_screen.dart';
import 'package:facture_zen/features/invoicing/views/voice_recording_screen.dart';
import 'package:facture_zen/features/profile/views/profile_screenn.dart';
import 'package:facture_zen/features/notifications/views/notifications_screen.dart';
import 'package:facture_zen/revenue_cat_util.dart' as revenue_cat;
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'common/services/auth_service.dart';
import 'common/services/pin_service.dart';
import 'common/services/firebase_invoice_service.dart';
import 'common/services/tracking_service.dart';
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

import 'common/providers/premium_provider.dart';
import 'common/services/analytics_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Charger les variables d'environnement (.env)
  await dotenv.load(fileName: ".env");
  print('📁 .env chargé, GEMINI_API_KEY existe: [1m${dotenv.env['GEMINI_API_KEY'] != null}[0m');

  // Initialiser Firebase AVANT tout le reste
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // S'assurer que la collecte Analytics est activée (important pour first_open)
  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);

  // Initialiser RevenueCat APRÈS Firebase
  await revenue_cat.initialize(
    dotenv.env['REVENUE_CAT_APP_STORE_KEY'] ?? '', // iOS
    dotenv.env['REVENUE_CAT_PLAY_STORE_KEY'] ?? '', // Android
    debugLogEnabled: true,
    loadDataAfterLaunch: true,
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
    // Initialiser le tracking APRÈS le premier frame pour que la popup ATT iOS
    // puisse s'afficher correctement (sinon elle échoue silencieusement et
    // setAdvertiserTrackingEnabled(false) est appelé → 0 install attribué Meta)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TrackingService().initialize();
    });
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

  /// BLOC 1 - Vérifie si un PIN est configuré ET activé, puis force la navigation
  /// SEULEMENT si l'utilisateur est toujours connecté
  Future<void> _checkPinOnResume() async {
    await Future.delayed(const Duration(milliseconds: 300));

    final authService = AuthService();
    final pinService = PinService();

    final isAuthenticated = authService.isAuthenticated;
    debugPrint('🔐 Resume - isAuthenticated: $isAuthenticated');

    if (!isAuthenticated) {
      debugPrint('🔐 Resume - Utilisateur non authentifié, pas de PIN demandé');
      return;
    }

    // ✅ hasPin() vérifie désormais isPinEnabled() en interne
    final hasPin = await pinService.hasPin();
    debugPrint('🔐 Resume - hasPin (enabled + configured): $hasPin');

    if (hasPin) {
      debugPrint('🔐 Resume - Navigation forcée vers /pin-login');
      _navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/pin-login',
        (route) => false,
      );
    } else {
      debugPrint('🔐 Resume - PIN désactivé ou non configuré, pas de redirection');
    }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final invoiceService = FirebaseInvoiceService();
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PremiumProvider()), // ← AJOUTER ICI
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
        navigatorObservers: [AnalyticsService().observer],
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

  /// BLOC 2 - Détermine la route initiale en fonction de l'état
  Future<String> _determineInitialRoute() async {
    final authService = AuthService();
    final pinService = PinService();

    final user = await authService.authStateChanges.first;
    final isAuthenticated = user != null;
    debugPrint('🔐 AppInitializer - isAuthenticated: $isAuthenticated (user: ${user?.email})');

    if (isAuthenticated) {
      try {
        await revenue_cat.login(user.uid);
        debugPrint('✅ RevenueCat synchronized with user: ${user.uid}');
      } catch (e) {
        debugPrint('⚠️ Failed to sync RevenueCat on startup: $e');
      }

      // ✅ hasPin() vérifie isPinEnabled() + PIN configuré en interne
      final hasPin = await pinService.hasPin();
      debugPrint('🔐 AppInitializer - hasPin (enabled + configured): $hasPin');

      if (hasPin) {
        debugPrint('🔐 AppInitializer - Navigation vers /pin-login');
        return '/pin-login';
      }

      // Pas de PIN actif — aller directement sur /home, même si le profil entreprise n'est pas configuré
      debugPrint('🔐 AppInitializer - Navigation vers /home (profil entreprise ignoré)');
      return '/home';
    } else {
      debugPrint('🔐 AppInitializer - Navigation vers /login');
      return '/login';
    }
  }
}