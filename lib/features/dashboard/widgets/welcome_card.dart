import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/app_colors.dart';

class WelcomeCard extends StatefulWidget {
  final VoidCallback onAddFarm;

  const WelcomeCard({super.key, required this.onAddFarm});

  @override
  State<WelcomeCard> createState() => _WelcomeCardState();
}

class _WelcomeCardState extends State<WelcomeCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;

  // Normalized tilt coordinates (-1.0 to 1.0)
  double _tiltX = 0.0;
  double _tiltY = 0.0;

  // Values before starting the reset animation
  double _fromTiltX = 0.0;
  double _fromTiltY = 0.0;

  late final AnimationController _resetController;
  late final Animation<double> _resetAnimation;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _resetAnimation = CurvedAnimation(
      parent: _resetController,
      curve: Curves.easeOutCubic,
    )..addListener(() {
        setState(() {
          final t = _resetAnimation.value;
          _tiltX = _fromTiltX * (1.0 - t);
          _tiltY = _fromTiltY * (1.0 - t);
        });
      });
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _onEnter(PointerEnterEvent event) {
    _resetController.stop();
    setState(() {
      _isHovered = true;
    });
  }

  void _onHover(PointerHoverEvent event, Size size) {
    if (size.width == 0 || size.height == 0) return;

    final normX = ((event.localPosition.dx / size.width) - 0.5) * 2.0;
    final normY = ((event.localPosition.dy / size.height) - 0.5) * 2.0;

    setState(() {
      _tiltX = normX.clamp(-1.0, 1.0);
      _tiltY = normY.clamp(-1.0, 1.0);
    });
  }

  void _onExit(PointerExitEvent event) {
    _fromTiltX = _tiltX;
    _fromTiltY = _tiltY;
    setState(() {
      _isHovered = false;
    });
    _resetController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 640;

        // Subtle 3D perspective matrix for depth on hover
        // Max tilt angles: ~4.5 degrees
        const maxAngleX = 0.08;
        const maxAngleY = 0.08;

        final perspectiveMatrix = Matrix4.identity()
          ..setEntry(3, 2, 0.0012) // 3D Perspective
          ..rotateX(-_tiltY * maxAngleX)
          ..rotateY(_tiltX * maxAngleY);

        return MouseRegion(
          onEnter: _onEnter,
          onHover: (e) =>
              _onHover(e, Size(constraints.maxWidth, isCompact ? 320 : 220)),
          onExit: _onExit,
          cursor: SystemMouseCursors.basic,
          child: AnimatedContainer(
            duration: _isHovered
                ? const Duration(milliseconds: 70)
                : const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            transform: perspectiveMatrix,
            transformAlignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2E8658), AppColors.darkGreen],
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: _isHovered
                    ? Colors.white.withValues(alpha: 0.32)
                    : Colors.white.withValues(alpha: 0.12),
                width: 1.5,
              ),
              boxShadow: _isHovered
                  ? [
                      // Deep ground shadow shifting dynamically opposite to mouse tilt
                      BoxShadow(
                        color: const Color(0xFF091E12).withValues(alpha: 0.40),
                        blurRadius: 36,
                        offset: Offset(-_tiltX * 12, 20 - _tiltY * 8),
                        spreadRadius: 2,
                      ),
                      // Vibrant emerald green glow
                      BoxShadow(
                        color: const Color(0xFF2E8658).withValues(alpha: 0.28),
                        blurRadius: 22,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Stack(
                children: [
                  // Specular glare / sheen that moves across the card surface
                  Positioned.fill(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _isHovered ? 1.0 : 0.0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment(_tiltX, _tiltY),
                            radius: 1.1,
                            colors: [
                              Colors.white.withValues(alpha: 0.15),
                              Colors.white.withValues(alpha: 0.03),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.45, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Main card content
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 22,
                    ),
                    child: isCompact
                        ? _buildCompactLayout()
                        : _buildWideLayout(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left text & action
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: Color(0xFFB9F6CA),
                      size: 14,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'AI Precision Agriculture',
                      style: TextStyle(
                        color: Color(0xFFE8F5E9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'Welcome, Farmer 👋',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Grow smarter. Save water. Harvest better.',
                style: TextStyle(
                  color: Color(0xFFD6EAD8),
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 20),
              _buildRegisterButton(),
            ],
          ),
        ),

        const SizedBox(width: 20),

        // Right side: 3D Parallax Picture
        Expanded(
          flex: 4,
          child: _buildParallaxImage(height: 165),
        ),
      ],
    );
  }

  Widget _buildCompactLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image at top on compact screens
        Center(
          child: _buildParallaxImage(height: 150),
        ),
        const SizedBox(height: 16),
        const Text(
          'Welcome, Farmer 👋',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Grow smarter. Save water. Harvest better.',
          style: TextStyle(
            color: Color(0xFFD6EAD8),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 18),
        _buildRegisterButton(),
      ],
    );
  }

  Widget _buildParallaxImage({required double height}) {
    // Parallax depth: The image shifts slightly with mouse movement,
    // producing a stereoscopic 3D floating effect.
    final parallaxOffset = Offset(_tiltX * 12, _tiltY * 8);

    return Transform.translate(
      offset: parallaxOffset,
      child: Transform.scale(
        scale: _isHovered ? 1.05 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isHovered ? 0.38 : 0.22),
                blurRadius: _isHovered ? 26 : 16,
                offset: Offset(-_tiltX * 6, _isHovered ? 12 : 6),
              ),
              if (_isHovered)
                BoxShadow(
                  color: const Color(0xFFB9F6CA).withValues(alpha: 0.20),
                  blurRadius: 16,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Image.asset(
                  'assets/images/farm_illustration.png',
                  height: height,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: height,
                      color: Colors.white.withValues(alpha: 0.1),
                      child: const Center(
                        child: Icon(
                          Icons.eco_rounded,
                          color: Colors.white70,
                          size: 48,
                        ),
                      ),
                    );
                  },
                ),
                // Subtle ambient border rim around the picture
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white
                            .withValues(alpha: _isHovered ? 0.35 : 0.18),
                        width: 1.2,
                      ),
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

  Widget _buildRegisterButton() {
    return SizedBox(
      height: 48,
      child: FilledButton.icon(
        onPressed: widget.onAddFarm,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Register a Farm',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.darkGreen,
          elevation: _isHovered ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
      ),
    );
  }
}
