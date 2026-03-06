import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../../../common/widgets/curved_bottom_nav.dart';
import '../viewmodels/voice_recording_viewmodel.dart';
import '../../../common/widgets/app_logo.dart';
import '../../../common/utils/responsive_utils.dart';
import '../../../common/services/firebase_invoice_service.dart';
import 'text_preview_screen.dart';
import 'subscription_screen.dart';
import 'dart:math' as math;

class VoiceRecordingScreen extends StatefulWidget {
  const VoiceRecordingScreen({Key? key}) : super(key: key);

  @override
  State<VoiceRecordingScreen> createState() => _VoiceRecordingScreenState();
}

class _VoiceRecordingScreenState extends State<VoiceRecordingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;
  late List<Animation<double>> _barAnimations;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Contrôleur pour l'animation des vagues sonores
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _waveController,
        curve: Curves.easeInOut,
      ),
    );

    // Créer des animations individuelles pour chaque barre de l'onde sonore
    _barAnimations = List.generate(8, (index) {
      return Tween<double>(begin: 0.1, end: 1.0).animate(
        CurvedAnimation(
          parent: _waveController,
          curve: Interval(
            (index * 0.1).clamp(0.0, 0.7),
            ((index + 1) * 0.1).clamp(0.3, 1.0),
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _updateAnimations(bool isRecording) {
    if (isRecording) {
      _pulseController.repeat(reverse: true);
      _waveController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
      _waveController.stop();
      _waveController.reset();
    }
  }

  /// Gère le clic sur le bouton microphone
  /// Vérifie la permission avant de commencer l'enregistrement
  Future<void> _handleMicrophoneClick(VoiceRecordingViewModel viewModel) async {
    // Si déjà en enregistrement, juste mettre en pause
    if (viewModel.isRecording) {
      await viewModel.toggleRecording();
      return;
    }

    // Vérifier la permission au premier clic
    final hasPermission = await viewModel.requestMicrophonePermission();

    if (hasPermission) {
      // ✅ Permission accordée → démarrer l'enregistrement
      debugPrint('✅ Permission acceptée, démarrage enregistrement');
      await viewModel.toggleRecording();
    } else if (viewModel.permissionDenied) {
      // ❌ Permission refusée → afficher dialogue avec bénéfices
      if (mounted) {
        _showMicrophoneDialog();
      }
    }
  }

  /// Affiche un dialogue contextualisé avec les bénéfices du microphone
  void _showMicrophoneDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Permission Microphone'),
          content: const Text(
            'Activez le microphone pour enregistrer vos factures à la voix.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _openMicrophoneSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B5FC7),
              ),
              child: const Text(
                'Autoriser',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Ouvre directement les paramètres du microphone sur iOS
  Future<void> _openMicrophoneSettings() async {
    try {
      if (Platform.isIOS) {
        // Sur iOS 16+, ouvrir automatiquement est très limité
        // Essayer tout de même avec openAppSettings()
        debugPrint('Ouverture des parametres de l\'app...');
        final bool opened = await openAppSettings();
        debugPrint('openAppSettings result: $opened');
        
        if (opened) {
          debugPrint('Parametres ouverts');
          if (mounted) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Microphone: Activez le microphone pour Facture Zen'),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            });
          }
        }
      } else {
        // Android
        await openAppSettings();
      }
    } catch (e) {
      debugPrint('Exception: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Parametres > Facture Zen > Microphone'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _handleValidation(VoiceRecordingViewModel viewModel) async {
    // Vérifier la limite AVANT la transcription
    final invoiceService = FirebaseInvoiceService();
    final canCreate = await invoiceService.canCreateInvoice();
    final remainingInvoices = await invoiceService.getRemainingInvoices();
    
    if (!canCreate) {
      // Limite atteinte -> Afficher le paywall
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SubscriptionScreen(remainingInvoices: remainingInvoices),
          ),
        );
      }
      return; // Ne pas continuer
    }

    final transcribedText = await viewModel.validate();

    if (transcribedText != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TextPreviewScreen(
            transcribedText: transcribedText,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<VoiceRecordingViewModel>(
          builder: (context, viewModel, child) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _updateAnimations(viewModel.isRecording);
            });

            return Stack(
              children: [
                // Contenu principal
                Column(
                  children: [
                    SizedBox(height: responsive.getAdaptiveSpacing(24)),
                    AppLogo(fontSize: responsive.getAdaptiveTextSize(28)),

                    // Animation d'onde sonore moderne
                    if (viewModel.isRecording)
                      _buildModernSoundWave(responsive),

                    Expanded(
                      child: Center(
                        child: _buildModernTimer(viewModel, responsive),
                      ),
                    ),

                    // Boutons de contrôle
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.horizontalPadding,
                      ),
                      child: _buildControlButtons(viewModel, responsive),
                    ),

                    SizedBox(height: responsive.getAdaptiveSpacing(32)),
                  ],
                ),

                // Modal de génération
                if (viewModel.isGenerating)
                  _buildGeneratingModal(responsive),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const CurvedBottomNav(currentIndex: 1),
    );
  }

  Widget _buildModernSoundWave(ResponsiveUtils responsive) {
    return Padding(
      padding: EdgeInsets.only(
        top: responsive.getAdaptiveSpacing(20),
        bottom: responsive.getAdaptiveSpacing(40),
      ),
      child: AnimatedBuilder(
        animation: _waveController,
        builder: (context, child) {
          return SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(8, (index) {
                final animation = _barAnimations[index];
                final height = animation.value * 60;
                final opacity = 0.3 + (animation.value * 0.7);

                // Alternance de couleurs pour un effet plus dynamique
                final color = index % 2 == 0
                    ? const Color(0xFF5B5FC7) // Violet principal
                    : const Color(0xFF9C9FE8); // Violet clair

                return Container(
                  width: 6,
                  height: height,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        color.withOpacity(opacity * 0.8),
                        color.withOpacity(opacity),
                        Colors.white.withOpacity(opacity * 0.3),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(opacity * 0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernTimer(VoiceRecordingViewModel viewModel, ResponsiveUtils responsive) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Anneaux de fond animés
            if (viewModel.isRecording) ...[
              _buildAnimatedRing(300 + (_pulseAnimation.value * 30), 0.08),
              _buildAnimatedRing(260 + (_pulseAnimation.value * 20), 0.15),
            ],

            // Timer central ultra-moderne
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: viewModel.isRecording
                      ? [
                    const Color(0xFF6B6FC7),
                    const Color(0xFF494D9F),
                    const Color(0xFF5B5FC7),
                  ]
                      : [
                    const Color(0xFF8B8FD7),
                    const Color(0xFF696DC7),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5B5FC7).withOpacity(0.4),
                    blurRadius: 40,
                    offset: const Offset(0, 15),
                    spreadRadius: viewModel.isRecording ? 5 : 0,
                  ),
                  if (viewModel.isRecording)
                    BoxShadow(
                      color: const Color(0xFF9C9FE8).withOpacity(0.3),
                      blurRadius: 60,
                      offset: const Offset(0, 0),
                      spreadRadius: 10,
                    ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        viewModel.formattedDuration,
                        style: TextStyle(
                          fontSize: responsive.getAdaptiveTextSize(36),
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 3,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.2),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      if (viewModel.isRecording)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildPulsingDot(0),
                              _buildPulsingDot(200),
                              _buildPulsingDot(400),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnimatedRing(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF9C9FE8).withOpacity(opacity),
          width: 2,
        ),
      ),
    );
  }

  Widget _buildPulsingDot(int delay) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final offset = (delay / 600);
        final value = ((_pulseAnimation.value + offset) % 1.0);
        final opacity = (math.sin(value * math.pi) * 0.8).clamp(0.2, 1.0);

        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(opacity),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(opacity * 0.5),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlButtons(VoiceRecordingViewModel viewModel, ResponsiveUtils responsive) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildActionButton(
          icon: Icons.refresh,
          size: 56,
          onPressed: viewModel.canReset ? viewModel.reset : null,
          backgroundColor: const Color(0xFFF3F4F6),
          iconColor: const Color(0xFF6B7280),
        ),
        SizedBox(width: responsive.getAdaptiveSpacing(40)),
        _buildActionButton(
          icon: viewModel.isRecording ? Icons.pause : Icons.mic,
          size: 80,
          onPressed: () => _handleMicrophoneClick(viewModel),
          backgroundColor: const Color(0xFF5B5FC7),
          iconColor: Colors.white,
          hasShadow: true,
        ),
        SizedBox(width: responsive.getAdaptiveSpacing(40)),
        _buildActionButton(
          icon: Icons.check,
          size: 56,
          onPressed: viewModel.canValidate
              ? () => _handleValidation(viewModel)
              : null,
          backgroundColor: viewModel.canValidate
              ? const Color(0xFF5B5FC7) // Violet quand activé
              : const Color(0xFFE5E7EB), // Gris quand désactivé
          iconColor: viewModel.canValidate
              ? Colors.white // Blanc quand activé
              : const Color(0xFF6B7280), // Gris foncé quand désactivé
          hasShadow: viewModel.canValidate, // Ombre uniquement quand activé
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required double size,
    required VoidCallback? onPressed,
    required Color backgroundColor,
    required Color iconColor,
    bool hasShadow = false,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        boxShadow: hasShadow
            ? [
          BoxShadow(
            color: const Color(0xFF5B5FC7).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Center(
            child: Icon(
              icon,
              size: size * 0.45,
              color: onPressed == null ? iconColor.withOpacity(0.4) : iconColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGeneratingModal(ResponsiveUtils responsive) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding * 2),
            padding: EdgeInsets.all(responsive.getAdaptiveSpacing(32)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5B5FC7)),
                ),
                SizedBox(height: responsive.getAdaptiveSpacing(20)),
                Text(
                  'Transcription en cours',
                  style: TextStyle(
                    fontSize: responsive.getAdaptiveTextSize(18),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: responsive.getAdaptiveSpacing(12)),
                Text(
                  'Groq Whisper analyse votre audio...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: responsive.getAdaptiveTextSize(14),
                    color: const Color(0xFF6B7280),
                    height: 1.5,
                  ),
                ),
                SizedBox(height: responsive.getAdaptiveSpacing(24)),
                TextButton(
                  onPressed: () {
                    context.read<VoiceRecordingViewModel>().cancelGeneration();
                  },
                  child: Text(
                    'Annuler',
                    style: TextStyle(
                      fontSize: responsive.getAdaptiveTextSize(16),
                      color: const Color(0xFF5B5FC7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}