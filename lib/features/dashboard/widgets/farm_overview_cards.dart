import 'dart:ui' show lerpDouble;

import 'package:material_ui/material_ui.dart';

import '../../../core/app_colors.dart';

/// Farm Overview cards: photo cards centred on the page. Hover (desktop/web)
/// or tap (mobile) expands one card over its neighbours and reveals details.
///
/// Performance notes (60fps): each card owns one AnimationController, only
/// that card's rect/opacities animate, every card sits in a RepaintBoundary,
/// and the images are decoded at a capped size.
class FarmOverviewCards extends StatefulWidget {
  final int farmCount;
  final double totalArea;
  final int cropCount;
  final String irrigationStatus;

  const FarmOverviewCards({
    super.key,
    required this.farmCount,
    required this.totalArea,
    required this.cropCount,
    required this.irrigationStatus,
  });

  @override
  State<FarmOverviewCards> createState() => _FarmOverviewCardsState();
}

class _CardData {
  final IconData icon;
  final String title;
  final String value;
  final String image;
  final List<List<String>> meta;

  const _CardData({
    required this.icon,
    required this.title,
    required this.value,
    required this.image,
    required this.meta,
  });
}

class _FarmOverviewCardsState extends State<FarmOverviewCards> {
  static const double _gap = 14;
  int? _active; // card currently expanded
  int _front = 0; // card painted on top (stays on top while collapsing)

  List<_CardData> get _cards {
    final farms = widget.farmCount;
    final area = widget.totalArea;
    final crops = widget.cropCount;
    final avg = farms == 0 ? 0.0 : area / farms;
    final hectares = area * 0.404686;
    final pending = widget.irrigationStatus.toLowerCase() == 'pending';

    return [
      _CardData(
        icon: Icons.agriculture_rounded,
        title: 'Total Farms',
        value: farms.toString(),
        image: 'assets/images/card_farms.webp',
        meta: [
          ['Registered', farms.toString()],
          ['Average size', '${avg.toStringAsFixed(1)} acres'],
          ['Crop fields', crops.toString()],
          ['Next step', farms == 0 ? 'Add a farm' : 'Review farms'],
        ],
      ),
      _CardData(
        icon: Icons.landscape_rounded,
        title: 'Total Land',
        value: '${area.toStringAsFixed(1)} acres',
        image: 'assets/images/card_land.jpg',
        meta: [
          ['In acres', area.toStringAsFixed(1)],
          ['In hectares', hectares.toStringAsFixed(2)],
          ['Per farm', '${avg.toStringAsFixed(1)} acres'],
          ['Farms', farms.toString()],
        ],
      ),
      _CardData(
        icon: Icons.grass_rounded,
        title: 'Crop Fields',
        value: crops.toString(),
        image: 'assets/images/card_crops.jpg',
        meta: [
          ['Active fields', crops.toString()],
          [
            'Per farm',
            farms == 0 ? '0' : (crops / farms).toStringAsFixed(1),
          ],
          ['Farms', farms.toString()],
          ['Next step', crops == 0 ? 'Add a crop' : 'Check growth'],
        ],
      ),
      _CardData(
        icon: Icons.water_drop_rounded,
        title: 'Irrigation',
        value: widget.irrigationStatus,
        image: 'assets/images/card_irrigation.webp',
        meta: [
          ['Status', widget.irrigationStatus],
          ['Land to water', '${area.toStringAsFixed(1)} acres'],
          ['Crop fields', crops.toString()],
          ['Next step', pending ? 'Open planner' : 'View schedule'],
        ],
      ),
    ];
  }

  void _setActive(int? i) {
    setState(() {
      _active = i;
      if (i != null) _front = i;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cards = _cards;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;

        // Fit 4 in a row if possible, otherwise 2 x 2.
        double w = 190;
        double h = 230;
        int cols = 4;
        if (4 * w + 3 * _gap > maxW) {
          cols = 2;
          w = ((maxW - _gap) / 2).clamp(130.0, 230.0);
          h = w * 1.25;
        }
        final rows = (cards.length / cols).ceil();

        final ew = (w + 110).clamp(w, maxW);
        final eh = h + 120;
        final padV = (eh - h) / 2;

        final gridW = cols * w + (cols - 1) * _gap;
        final left0 = (maxW - gridW) / 2; // centre the whole group
        final totalH = rows * h + (rows - 1) * _gap + 2 * padV;

        // Paint order: everyone else first, the front card last.
        final order = [
          for (var i = 0; i < cards.length; i++)
            if (i != _front) i,
          _front,
        ];

        return SizedBox(
          width: maxW,
          height: totalH,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final i in order)
                _OverviewCard(
                  key: ValueKey(i),
                  data: cards[i],
                  expanded: _active == i,
                  cx: left0 + (i % cols) * (w + _gap) + w / 2,
                  cy: padV + (i ~/ cols) * (h + _gap) + h / 2,
                  baseW: w,
                  baseH: h,
                  expW: ew,
                  expH: eh,
                  maxW: maxW,
                  onEnter: () => _setActive(i),
                  onExit: () {
                    if (_active == i) _setActive(null);
                  },
                  onTap: () => _setActive(_active == i ? null : i),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _OverviewCard extends StatefulWidget {
  final _CardData data;
  final bool expanded;
  final double cx, cy, baseW, baseH, expW, expH, maxW;
  final VoidCallback onEnter, onExit, onTap;

  const _OverviewCard({
    super.key,
    required this.data,
    required this.expanded,
    required this.cx,
    required this.cy,
    required this.baseW,
    required this.baseH,
    required this.expW,
    required this.expH,
    required this.maxW,
    required this.onEnter,
    required this.onExit,
    required this.onTap,
  });

  @override
  State<_OverviewCard> createState() => _OverviewCardState();
}

class _OverviewCardState extends State<_OverviewCard>
    with SingleTickerProviderStateMixin {
  static const double _detailsH = 4 * 27.0;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
    reverseDuration: const Duration(milliseconds: 300),
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  late final Animation<double> _detailsOpacity = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
    reverseCurve: const Interval(0.0, 0.4, curve: Curves.easeIn),
  );

  @override
  void didUpdateWidget(covariant _OverviewCard old) {
    super.didUpdateWidget(old);
    if (widget.expanded != old.expanded) {
      widget.expanded ? _c.forward() : _c.reverse();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _t.value;
        final w = lerpDouble(widget.baseW, widget.expW, t)!;
        final h = lerpDouble(widget.baseH, widget.expH, t)!;
        final left = (widget.cx - w / 2).clamp(0.0, widget.maxW - w);
        final top = widget.cy - h / 2;
        final dOpacity = _detailsOpacity.value;

        return Positioned(
          left: left,
          top: top,
          width: w,
          height: h,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => widget.onEnter(),
            onExit: (_) => widget.onExit(),
            child: GestureDetector(
              onTap: widget.onTap,
              child: RepaintBoundary(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.darkGreen
                            .withValues(alpha: 0.10 + 0.20 * t),
                        blurRadius: 10 + 20 * t,
                        offset: Offset(0, 4 + 8 * t),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Photo always fills the card.
                        Image.asset(
                          d.image,
                          fit: BoxFit.cover,
                          cacheWidth: 700,
                          filterQuality: FilterQuality.medium,
                        ),
                        // Bottom gradient for text legibility.
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.05),
                                Colors.black.withValues(
                                    alpha: 0.30 + 0.35 * t),
                                Colors.black.withValues(
                                    alpha: 0.72 + 0.20 * t),
                              ],
                              stops: const [0.0, 0.55, 1.0],
                            ),
                          ),
                        ),
                        // Icon chip.
                        Positioned(
                          left: 14,
                          top: 14,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(d.icon,
                                color: AppColors.green, size: 22),
                          ),
                        ),
                        // Title + value; slides up as details appear.
                        Positioned(
                          left: 16,
                          right: 12,
                          bottom: lerpDouble(16, 28 + _detailsH, t)!,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                d.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                d.value,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Meta details.
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 14,
                          height: _detailsH,
                          child: Opacity(
                            opacity: dOpacity,
                            child: Transform.translate(
                              offset: Offset(0, 14 * (1 - dOpacity)),
                              child: Column(
                                children: [
                                  for (final m in d.meta)
                                    SizedBox(
                                      height: 27,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border(
                                            top: BorderSide(
                                              color: Colors.white
                                                  .withValues(alpha: 0.22),
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              m[0],
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white
                                                    .withValues(alpha: 0.78),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                m[1],
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
