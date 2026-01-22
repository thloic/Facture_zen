import 'package:flutter/material.dart';

class ToastUtils {
  static void show(BuildContext context, {required String message, required bool isError}) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        isError: isError,
        onDismiss: () {
          overlayEntry.remove();
        },
      ),
    );

    overlay.insert(overlayEntry);

    // Auto-remove après 2 secondes
    Future.delayed(const Duration(seconds: 2), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const _ToastWidget({
    Key? key,
    required this.message,
    required this.isError,
    required this.onDismiss,
  }) : super(key: key);

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
      reverseCurve: Curves.easeInBack,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.isError ? Colors.red.shade600 : Colors.green.shade600;
    final contentColor = Colors.white;
    final icon = widget.isError ? Icons.error_outline : Icons.check_circle_outline;

    return Material(
      color: Colors.transparent,
      child: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: backgroundColor.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: contentColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.isError ? 'Oups !' : 'Succès',
                    style: TextStyle(
                      color: contentColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'SF Pro Display',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: contentColor.withOpacity(0.95),
                      fontSize: 14,
                      height: 1.4,
                      fontFamily: 'SF Pro Display',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
