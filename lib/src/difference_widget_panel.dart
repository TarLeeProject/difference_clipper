
class DifferenceWidget extends StatefulWidget {
  const DifferenceWidget({
    super.key,
    required this.child,
    this.isFloating = false,
  });
  final Widget child;
  final bool isFloating;

  @override
  State<StatefulWidget> createState() => _DifferenceWidgetState();
}

class _DifferenceWidgetState extends State<DifferenceWidget> {
  final _key = GlobalKey();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final _DifferenceWidgetPanelState? diffPanel = context
            .findAncestorStateOfType<_DifferenceWidgetPanelState>();
        if (diffPanel != null) {
          final panelRenderBox =
              diffPanel._key.currentContext?.findRenderObject() as RenderBox?;
          if (panelRenderBox != null) {
            final size = renderBox.size;
            final pos = renderBox.localToGlobal(
              Offset.zero,
              ancestor: panelRenderBox,
            );
            diffPanel._addBound(
              Polygon(
                outer: [
                  Point(pos.dx, pos.dy),
                  Point(pos.dx + size.width, pos.dy),
                  Point(pos.dx + size.width, pos.dy + size.height),
                  Point(pos.dx, pos.dy + size.height),
                ],
              ),
              isFloating: widget.isFloating,
            );
          }
        }
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: _key, child: widget.child);
  }
}

class DifferenceWidgetPanel extends StatefulWidget {
  const DifferenceWidgetPanel({
    super.key,
    required this.children,
    this.spacing = 8.0,
    this.radius = 8.0,
  });

  final List<Widget> children;
  final double spacing;
  final double radius;

  @override
  State<StatefulWidget> createState() => _DifferenceWidgetPanelState();
}

class _DifferenceWidgetPanelState extends State<DifferenceWidgetPanel> {
  final _key = GlobalKey();

  final _bounds = <Polygon, bool>{};
  final _boundsNotifier = ValueNotifier<List<Polygon>>([]);

  void _addBound(Polygon polygon, {bool isFloating = false}) {
    if (_bounds.keys.contains(polygon)) return;
    _bounds[polygon] = isFloating;
    _updateClipper();
  }

  void _updateClipper() {
    final bases = _bounds.entries
        .where((e) => e.value == false)
        .map((e) => e.key)
        .toList();
    final floating = _bounds.entries
        .where((e) => e.value == true)
        .map((e) => e.key)
        .toList();
    if (bases.isNotEmpty && floating.isNotEmpty) {
      final spacedFloating = floating
          .map((p) => addSpacing(p, widget.spacing))
          .toList();
      _boundsNotifier.value = difference(bases, spacedFloating);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: _key,
      children: [
        for (final child in widget.children)
          child is DifferenceWidget && !child.isFloating
              ? ValueListenableBuilder(
                  valueListenable: _boundsNotifier,
                  child: child,
                  builder: (context, value, _) {
                    if (value.isEmpty) {
                      return child;
                    }
                    return ClipPath(
                      clipper: BooleanWidgetPainter(
                        polygons: value,
                        radius: widget.radius,
                      ),
                      child: child,
                    );
                  },
                )
              : child,
      ],
    );
  }
}

class BooleanWidgetPainter extends CustomClipper<Path> {
  final List<Polygon> polygons;
  final double radius;

  const BooleanWidgetPainter({required this.polygons, required this.radius});

  @override
  Path getClip(Size size) {
    final path = Path()..fillType = PathFillType.evenOdd;

    for (final polygon in polygons) {
      if (polygon.outer.length <= 2) continue;

      // Outer polygon.
      _addRoundedPolygon(path, polygon.outer);

      // Holes.
      for (final hole in polygon.holes) {
        if (hole.length <= 2) continue;

        _addRoundedPolygon(path, hole);
      }
    }

    return path;
  }

  void _addRoundedPolygon(Path path, List<Point> points) {
    if (radius <= 0) {
      path.moveTo(points.first.x, points.first.y);

      for (final point in points.skip(1)) {
        path.lineTo(point.x, point.y);
      }

      path.close();
      return;
    }

    final roundedPoints = roundCorner(points, radius);

    if (roundedPoints.isEmpty) return;

    final first = roundedPoints.first;

    path.moveTo(first.p1.x, first.p1.y);

    for (var i = 0; i < roundedPoints.length; i++) {
      final corner = roundedPoints[i];

      path.quadraticBezierTo(
        corner.originPoint.x,
        corner.originPoint.y,
        corner.p2.x,
        corner.p2.y,
      );

      final next = roundedPoints[(i + 1) % roundedPoints.length];

      path.lineTo(next.p1.x, next.p1.y);
    }

    path.close();
  }

  @override
  bool shouldReclip(covariant BooleanWidgetPainter oldClipper) =>
      polygons.length != oldClipper.polygons.length ||
      polygons.any((p) => !oldClipper.polygons.contains(p)) ||
      radius != oldClipper.radius;
}