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

  // ✅ CORRECTION : Liste MODIFIABLE pour la waveform
  final List<double> _amplitudeHistory = List.generate(50, (_) => 0.0);

  @override
  void initState() {
    super.initState();

    // Animation du pulse
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
                            // Timer circulaire
                            _buildTimerCircle(viewModel, responsive),

                            SizedBox(height: responsive.getAdaptiveSpacing(40)),

                            // 🎵 VISUALISATION AUDIO EN TEMPS RÉEL
                            _buildAudioWaveform(viewModel, responsive),
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

  /// Widget - Visualisation audio (waveform en temps réel)
  Widget _buildAudioWaveform(VoiceRecordingViewModel viewModel, ResponsiveUtils responsive) {
    return StreamBuilder<double>(
      stream: viewModel.amplitudeStream,
      builder: (context, snapshot) {
        // Mettre à jour l'historique des amplitudes
        if (snapshot.hasData && snapshot.data != null) {
          // ✅ Maintenant ça fonctionne car la liste est modifiable
          _amplitudeHistory.removeAt(0);
          _amplitudeHistory.add(snapshot.data!);
        }

        return Container(
          height: 80,
          width: responsive.screenWidth * 0.8,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: CustomPaint(
            painter: WaveformPainter(
              amplitudes: _amplitudeHistory,
              isRecording: viewModel.isRecording,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimerCircle(VoiceRecordingViewModel viewModel, ResponsiveUtils responsive) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
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

/// CustomPainter pour la visualisation waveform
class WaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final bool isRecording;

  WaveformPainter({
    required this.amplitudes,
    required this.isRecording,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final barWidth = size.width / amplitudes.length;
    final centerY = size.height / 2;

    for (int i = 0; i < amplitudes.length; i++) {
      final x = i * barWidth;
      final amplitude = amplitudes[i];

      // Hauteur de la barre (max 80% de la hauteur)
      final barHeight = (amplitude * size.height * 0.8).clamp(2.0, size.height);

      // Couleur : gradient selon la position et l'amplitude
      final opacity = isRecording ? 1.0 : 0.3;
      final color = Color.lerp(
        const Color(0xFF9C9FE8),
        const Color(0xFF5B5FC7),
        amplitude,
      )!.withOpacity(opacity);

      paint.color = color;

      // Dessiner la barre verticale centrée
      canvas.drawLine(
        Offset(x, centerY - barHeight / 2),
        Offset(x, centerY + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.amplitudes != amplitudes ||
        oldDelegate.isRecording != isRecording;
  }
}