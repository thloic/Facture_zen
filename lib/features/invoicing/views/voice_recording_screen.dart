import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common/widgets/curved_bottom_nav.dart';
import '../viewmodels/voice_recording_viewmodel.dart';
import '../../../common/widgets/app_logo.dart';
import '../../../common/utils/responsive_utils.dart';
import 'text_preview_screen.dart';
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

  // Historique des amplitudes pour l'effet circulaire
  final List<double> _amplitudeHistory = List.generate(60, (_) => 0.0);

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _updateAnimations(bool isRecording) {
    if (isRecording) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  Future<void> _handleValidation(VoiceRecordingViewModel viewModel) async {
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

            return Column(
              children: [
                SizedBox(height: responsive.getAdaptiveSpacing(32)),

                AppLogo(fontSize: responsive.getAdaptiveTextSize(28)),

                Expanded(
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Timer circulaire avec effet audio autour
                            _buildTimerWithAudioEffect(viewModel, responsive),
                          ],
                        ),
                      ),

                      Positioned(
                        bottom: responsive.getAdaptiveSpacing(120),
                        left: 0,
                        right: 0,
                        child: _buildControlButtons(viewModel, responsive),
                      ),

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
      bottomNavigationBar: const CurvedBottomNav(currentIndex: 1),
    );
  }

  /// Widget - Timer avec effet audio circulaire
  Widget _buildTimerWithAudioEffect(VoiceRecordingViewModel viewModel, ResponsiveUtils responsive) {
    return StreamBuilder<double>(
      stream: viewModel.amplitudeStream,
      builder: (context, snapshot) {
        // Mettre à jour l'historique des amplitudes
        if (snapshot.hasData && snapshot.data != null) {
          _amplitudeHistory.removeAt(0);
          _amplitudeHistory.add(snapshot.data!);
        }

        return AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Effet audio circulaire autour du cercle
                if (viewModel.isRecording)
                  SizedBox(
                    width: 320,
                    height: 320,
                    child: CustomPaint(
                      painter: CircularWaveformPainter(
                        amplitudes: _amplitudeHistory,
                        isRecording: viewModel.isRecording,
                      ),
                    ),
                  ),

                // Pulse d'arrière-plan
                if (viewModel.isRecording)
                  Container(
                    width: 280 + (_pulseAnimation.value * 40),
                    height: 280 + (_pulseAnimation.value * 40),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF9C9FE8).withOpacity(
                        0.15 * (1 - _pulseAnimation.value),
                      ),
                    ),
                  ),

                if (viewModel.isRecording)
                  Container(
                    width: 260 + (_pulseAnimation.value * 20),
                    height: 260 + (_pulseAnimation.value * 20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF9C9FE8).withOpacity(
                        0.25 * (1 - _pulseAnimation.value),
                      ),
                    ),
                  ),

                // Cercle principal avec timer
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF6B6FC7), Color(0xFF494D9F)],
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
          backgroundColor: const Color(0xFFE5E7EB),
          iconColor: const Color(0xFF6B7280),
        ),

        SizedBox(width: responsive.getAdaptiveSpacing(40)),

        _buildActionButton(
          icon: viewModel.isRecording ? Icons.pause : Icons.mic,
          size: 80,
          onPressed: viewModel.toggleRecording,
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
          backgroundColor: const Color(0xFFE5E7EB),
          iconColor: const Color(0xFF6B7280),
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
              color: onPressed == null
                  ? iconColor.withOpacity(0.4)
                  : iconColor,
            ),
          ),
        ),
      ),
    );
  }

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
    );
  }
}

/// CustomPainter pour la visualisation circulaire autour du timer (effet Siri)
class CircularWaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final bool isRecording;

  CircularWaveformPainter({
    required this.amplitudes,
    required this.isRecording,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2.3;

    final paint = Paint()
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final int barCount = amplitudes.length;
    final double angleStep = (2 * math.pi) / barCount;

    for (int i = 0; i < barCount; i++) {
      final angle = i * angleStep - math.pi / 2; // Commencer en haut
      final amplitude = amplitudes[i];

      // Longueur de la barre basée sur l'amplitude (entre 8 et 45)
      final barLength = 8 + (amplitude * 37);

      // Point de départ (sur le cercle de base)
      final startX = center.dx + baseRadius * math.cos(angle);
      final startY = center.dy + baseRadius * math.sin(angle);

      // Point d'arrivée (vers l'extérieur)
      final endRadius = baseRadius + barLength;
      final endX = center.dx + endRadius * math.cos(angle);
      final endY = center.dy + endRadius * math.sin(angle);

      // Couleur avec gradient basé sur l'amplitude
      final opacity = isRecording ? (0.6 + amplitude * 0.4) : 0.2;
      final color = Color.lerp(
        const Color(0xFF9C9FE8),
        const Color(0xFF5B5FC7),
        amplitude * 0.7,
      )!.withOpacity(opacity);

      paint.color = color;

      // Dessiner la barre radiale
      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CircularWaveformPainter oldDelegate) {
    return oldDelegate.amplitudes != amplitudes ||
        oldDelegate.isRecording != isRecording;
  }
}