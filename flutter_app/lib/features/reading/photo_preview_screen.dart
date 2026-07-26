import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../services/ai_models.dart';
import '../../services/app_strings.dart';
import 'processing_screen.dart';

const int _minDimension = 300;

enum _ValidationState { checking, valid, invalid }

class PhotoPreviewScreen extends ConsumerStatefulWidget {
  const PhotoPreviewScreen({
    super.key,
    required this.imagePath,
    required this.storyteller,
  });

  final String imagePath;
  final Storyteller storyteller;

  @override
  ConsumerState<PhotoPreviewScreen> createState() => _PhotoPreviewScreenState();
}

class _PhotoPreviewScreenState extends ConsumerState<PhotoPreviewScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  _ValidationState _state = _ValidationState.checking;
  String _errorKey = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _validateImage();
  }

  Future<void> _validateImage() async {
    try {
      final file = File(widget.imagePath);

      if (!await file.exists()) {
        _fail('error_not_found');
        return;
      }

      final length = await file.length();
      if (length == 0) {
        _fail('error_empty');
        return;
      }

      final Uint8List bytes = await file.readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      final image = frame.image;

      if (image.width < _minDimension || image.height < _minDimension) {
        _fail('error_too_small');
        return;
      }

      if (!mounted) return;
      setState(() => _state = _ValidationState.valid);
      _controller.forward();
    } catch (_) {
      _fail('error_unreadable');
    }
  }

  void _fail(String key) {
    if (!mounted) return;
    setState(() {
      _state = _ValidationState.invalid;
      _errorKey = key;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(ref.tr('your_cup_title')),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Expanded(child: _buildContent(context)),
              const SizedBox(height: AppSpacing.xl),
              if (_state == _ValidationState.valid) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => ProcessingScreen(
                            imagePath: widget.imagePath,
                            storyteller: widget.storyteller,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.auto_awesome),
                    label: Text(ref.tr('use_this_photo')),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.refresh),
                  label: Text(ref.tr('retake')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.warmCream,
                    side: const BorderSide(color: AppColors.warmCreamMuted),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (_state) {
      case _ValidationState.checking:
        return Container(
          decoration: BoxDecoration(
            color: AppColors.darkChocolate,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: const Center(child: CircularProgressIndicator()),
        );
      case _ValidationState.invalid:
        return Container(
          decoration: BoxDecoration(
            color: AppColors.darkChocolate,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.warmCreamMuted,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  ref.tr(_errorKey),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        );
      case _ValidationState.valid:
        return FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Image.file(
                  File(widget.imagePath),
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
          ),
        );
    }
  }
}
