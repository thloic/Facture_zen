import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common/widgets/curved_bottom_nav.dart';
import '../viewmodels/voice_recording_viewmodel.dart';
import '../../../common/widgets/app_logo.dart';
import '../../../common/utils/responsive_utils.dart';
import 'dart:math' as math;

/// VoiceRecordingScreen
/// Écran principal de création de facture par dictée vocale
/// Permet d'enregistrer, mettre en pause et valider l'enregistrement
/// Respecte l'architecture MVVM - cette classe est la View
class VoiceRecordingScreen extends StatefulWidget {
  const VoiceRecordingScreen({Key? key}) : super(key: key);

  @override
  State<VoiceRecordingScreen> createState() => _VoiceRecordingScreenState();
}

class _VoiceRecordingScreenState extends State<VoiceRecordingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Animation du pulse quand on enregistre
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Animation des ondes sonores
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  /// Démarre ou arrête l'animation selon l'état d'enregistrement
  void _updateAnimations(bool isRecording) {
    if (isRecording) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
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
            // Met à jour les animations selon l'état
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _updateAnimations(viewModel.isRecording);
            });

            return Column(
              children: [
                SizedBox(height: responsive.getAdaptiveSpacing(32)),

                // Logo
                AppLogo(fontSize: responsive.getAdaptiveTextSize(28)),

                // Zone centrale avec le timer et les contrôles
                Expanded(
                  child: Stack(
                    children: [
                      // Timer central
                      Center(
                        child: _buildTimerCircle(viewModel, responsive),
                      ),

                      // Boutons de contrôle
                      Positioned(
                        bottom: responsive.getAdaptiveSpacing(120),
                        left: 0,
                        right: 0,
                        child: _buildControlButtons(viewModel, responsive),
                      ),

                      // Modal de génération (si visible)
                      if (viewModel.isGenerating)
                        _buildGeneratingModal(responsive),
                    ],
                  ),
                ),


              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const CurvedBottomNav(
        currentIndex: 1, // Index 1 = Facture
      ),
    );
  }

  /// Widget - Timer circulaire central avec animations
  Widget _buildTimerCircle(VoiceRecordingViewModel viewModel, ResponsiveUtils responsive) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Cercle de pulse externe (quand on enregistre)
            if (viewModel.isRecording)
              Container(
                width: 280 + (_pulseAnimation.value * 40),
                height: 280 + (_pulseAnimation.value * 40),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF9C9FE8).withOpacity(
                    0.2 * (1 - _pulseAnimation.value),
                  ),
                ),
              ),

            // Cercle intermédiaire (quand on enregistre)
            if (viewModel.isRecording)
              Container(
                width: 260 + (_pulseAnimation.value * 20),
                height: 260 + (_pulseAnimation.value * 20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF9C9FE8).withOpacity(
                    0.3 * (1 - _pulseAnimation.value),
                  ),
                ),
              ),

            // Cercle principal
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6B6FC7),
                    Color(0xFF494D9F),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5B5FC7).withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  viewModel.formattedDuration,
                  style: TextStyle(
                    fontSize: responsive.getAdaptiveTextSize(32),
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Widget - Boutons de contrôle (refresh, record/pause, validate)
  Widget _buildControlButtons(VoiceRecordingViewModel viewModel, ResponsiveUtils responsive) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Bouton Refresh/Recommencer
        _buildActionButton(
          icon: Icons.refresh,
          size: 56,
          onPressed: viewModel.canReset ? viewModel.reset : null,
          backgroundColor: const Color(0xFFE5E7EB),
          iconColor: const Color(0xFF6B7280),
        ),

        SizedBox(width: responsive.getAdaptiveSpacing(40)),

        // Bouton central Record/Pause
        _buildActionButton(
          icon: viewModel.isRecording ? Icons.pause : Icons.mic,
          size: 80,
          onPressed: viewModel.toggleRecording,
          backgroundColor: const Color(0xFF5B5FC7),
          iconColor: Colors.white,
          hasShadow: true,
        ),

        SizedBox(width: responsive.getAdaptiveSpacing(40)),

        // Bouton Validate/Terminer
        _buildActionButton(
          icon: Icons.check,
          size: 56,
          onPressed: viewModel.canValidate ? viewModel.validate : null,
          backgroundColor: const Color(0xFFE5E7EB),
          iconColor: const Color(0xFF6B7280),
        ),
      ],
    );
  }

  /// Widget - Bouton d'action circulaire
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
              color: onPressed == null
                  ? iconColor.withOpacity(0.4)
                  : iconColor,
            ),
          ),
        ),
      ),
    );
  }

  /// Widget - Modal de génération de texte
  Widget _buildGeneratingModal(ResponsiveUtils responsive) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: responsive.horizontalPadding * 2,
          ),
          padding: EdgeInsets.all(responsive.getAdaptiveSpacing(32)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animation des ondes sonores
              AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  return CustomPaint(
                    size: const Size(60, 40),
                    painter: SoundWavePainter(
                      animationValue: _waveController.value,
                    ),
                  );
                },
              ),

              SizedBox(height: responsive.getAdaptiveSpacing(20)),

              Text(
                'Génération du texte',
                style: TextStyle(
                  fontSize: responsive.getAdaptiveTextSize(18),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),

              SizedBox(height: responsive.getAdaptiveSpacing(12)),

              Text(
                'Patientez pendant que nous convertissons\nvotre audio en texte',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: responsive.getAdaptiveTextSize(14),
                  color: const Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),

              SizedBox(height: responsive.getAdaptiveSpacing(24)),

              // Bouton Annuler
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
    );
  }


  /// Widget - Item de navigation
  Widget _buildNavItem(IconData icon, String label, bool isActive, ResponsiveUtils responsive) {
    return InkWell(
      onTap: () {
        // TODO: Navigation vers les autres écrans
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 24,
            color: isActive ? const Color(0xFF5B5FC7) : const Color(0xFF9CA3AF),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: responsive.getAdaptiveTextSize(12),
              color: isActive ? const Color(0xFF5B5FC7) : const Color(0xFF9CA3AF),
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          if (isActive)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF5B5FC7),
              ),
            ),
        ],
      ),
    );
  }
}

/// CustomPainter pour les ondes sonores animées
class SoundWavePainter extends CustomPainter {
  final double animationValue;

  SoundWavePainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF5B5FC7)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final centerY = size.height / 2;
    final spacing = size.width / 6;

    // Dessine 5 barres avec des hauteurs animées
    for (int i = 0; i < 5; i++) {
      final x = spacing * (i + 1);
      final progress = (animationValue + (i * 0.2)) % 1.0;
      final height = size.height * 0.3 * (0.5 + 0.5 * math.sin(progress * math.pi * 2));

      canvas.drawLine(
        Offset(x, centerY - height),
        Offset(x, centerY + height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(SoundWavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}