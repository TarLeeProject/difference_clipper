class _Clipper {
  static const double epsilon = 1e-9;

  static List<Polygon> union(List<Polygon> p1, List<Polygon> p2) {
    return _execute(p1, p2, _BooleanOperation.union);
  }

  static List<Polygon> difference(List<Polygon> p1, List<Polygon> p2) {
    return _execute(p1, p2, _BooleanOperation.difference);
  }

  static List<Polygon> intersection(List<Polygon> p1, List<Polygon> p2) {
    return _execute(p1, p2, _BooleanOperation.intersection);
  }

  static List<Polygon> _execute(
    List<Polygon> p1,
    List<Polygon> p2,
    _BooleanOperation operation,
  ) {
    final a = _normalize(p1);
    final b = _normalize(p2);

    final segments = <_Segment>[];

    _collectSegments(a, b, operation, true, segments);

    _collectSegments(b, a, operation, false, segments);

    final rings = _buildRings(segments);

    return _buildPolygons(rings);
  }

  // Normalize outer rings to CCW and holes to CW.
  static List<Polygon> _normalize(List<Polygon> polygons) {
    return polygons
        .map((polygon) {
          return Polygon(
            outer: _normalizeRing(polygon.outer, true),
            holes: polygon.holes
                .map((hole) => _normalizeRing(hole, false))
                .where((hole) => hole.length >= 3)
                .toList(),
          );
        })
        .where((p) => p.outer.length >= 3)
        .toList();
  }

  static List<Point> _normalizeRing(List<Point> points, bool counterClockwise) {
    final result = <Point>[];

    for (final point in points) {
      if (result.isEmpty || !_same(result.last, point)) {
        result.add(point);
      }
    }

    if (result.length > 1 && _same(result.first, result.last)) {
      result.removeLast();
    }

    if (result.length < 3) return result;

    final area = _signedArea(result);

    if ((area > 0) != counterClockwise) {
      return result.reversed.toList();
    }

    return result;
  }

  static double _signedArea(List<Point> points) {
    double area = 0;

    for (int i = 0; i < points.length; i++) {
      final a = points[i];
      final b = points[(i + 1) % points.length];

      area += a.x * b.y - b.x * a.y;
    }

    return area / 2;
  }

  static bool _same(Point a, Point b) {
    return (a.x - b.x).abs() <= epsilon && (a.y - b.y).abs() <= epsilon;
  }

  static List<List<Point>> _getRings(List<Polygon> polygons) {
    final result = <List<Point>>[];

    for (final polygon in polygons) {
      result.add(polygon.outer);
      result.addAll(polygon.holes);
    }

    return result;
  }

  static void _collectSegments(
    List<Polygon> source,
    List<Polygon> other,
    _BooleanOperation operation,
    bool isFirst,
    List<_Segment> output,
  ) {
    final sourceRings = _getRings(source);
    final otherRings = _getRings(other);

    final edges = <_Segment>[];

    for (final ring in otherRings) {
      for (int i = 0; i < ring.length; i++) {
        edges.add(_Segment(ring[i], ring[(i + 1) % ring.length]));
      }
    }

    final polygonsA = isFirst ? source : other;
    final polygonsB = isFirst ? other : source;

    for (final ring in sourceRings) {
      for (int i = 0; i < ring.length; i++) {
        final a = ring[i];
        final b = ring[(i + 1) % ring.length];

        final dx = b.x - a.x;
        final dy = b.y - a.y;
        final length = sqrt(dx * dx + dy * dy);

        if (length <= epsilon) continue;

        final ts = <double>[0, 1];

        for (final edge in edges) {
          ts.addAll(_intersectionParameters(a, b, edge.a, edge.b));
        }

        ts.sort();

        final unique = <double>[];

        for (final t in ts) {
          final value = t.clamp(0.0, 1.0).toDouble();

          if (unique.isEmpty || (unique.last - value).abs() > epsilon) {
            unique.add(value);
          }
        }

        for (int j = 0; j < unique.length - 1; j++) {
          final t1 = unique[j];
          final t2 = unique[j + 1];

          if (t2 - t1 <= epsilon) continue;

          final start = _interpolate(a, b, t1);
          final end = _interpolate(a, b, t2);
          final midpoint = _interpolate(a, b, (t1 + t2) / 2);

          final segmentLength = length * (t2 - t1);

          final offset = max(epsilon * 10, segmentLength * 1e-7);

          // Unit normal pointing to the left.
          final nx = -dy / length;
          final ny = dx / length;

          final left = Point(
            midpoint.x + nx * offset,
            midpoint.y + ny * offset,
          );

          final right = Point(
            midpoint.x - nx * offset,
            midpoint.y - ny * offset,
          );

          final leftInside = _resultContains(
            left,
            polygonsA,
            polygonsB,
            operation,
          );

          final rightInside = _resultContains(
            right,
            polygonsA,
            polygonsB,
            operation,
          );

          if (leftInside == rightInside) continue;

          final segment = leftInside
              ? _Segment(start, end)
              : _Segment(end, start);

          // Avoid duplicate directed edges.
          final duplicate = output.any((existing) {
            return _key(existing.a) == _key(segment.a) &&
                _key(existing.b) == _key(segment.b);
          });

          if (!duplicate) {
            output.add(segment);
          }
        }
      }
    }
  }

  static bool _resultContains(
    Point point,
    List<Polygon> a,
    List<Polygon> b,
    _BooleanOperation operation,
  ) {
    final insideA = _pointInRegion(point, a) == 1;
    final insideB = _pointInRegion(point, b) == 1;

    switch (operation) {
      case _BooleanOperation.union:
        return insideA || insideB;

      case _BooleanOperation.difference:
        return insideA && !insideB;

      case _BooleanOperation.intersection:
        return insideA && insideB;
    }
  }

  // Returns intersection parameters along segment AB.
  // Also splits at endpoints of collinear overlaps.
  static List<double> _intersectionParameters(
    Point a,
    Point b,
    Point c,
    Point d,
  ) {
    final rx = b.x - a.x;
    final ry = b.y - a.y;

    final sx = d.x - c.x;
    final sy = d.y - c.y;

    final denominator = _cross(rx, ry, sx, sy);

    final qx = c.x - a.x;
    final qy = c.y - a.y;

    if (denominator.abs() <= epsilon) {
      if (_cross(qx, qy, rx, ry).abs() > epsilon) {
        return [];
      }

      final lengthSquared = rx * rx + ry * ry;

      if (lengthSquared <= epsilon * epsilon) return [];

      final t1 = (qx * rx + qy * ry) / lengthSquared;

      final t2 = ((d.x - a.x) * rx + (d.y - a.y) * ry) / lengthSquared;

      return [
        if (t1 >= -epsilon && t1 <= 1 + epsilon) t1,
        if (t2 >= -epsilon && t2 <= 1 + epsilon) t2,
      ];
    }

    final t = _cross(qx, qy, sx, sy) / denominator;
    final u = _cross(qx, qy, rx, ry) / denominator;

    if (t >= -epsilon &&
        t <= 1 + epsilon &&
        u >= -epsilon &&
        u <= 1 + epsilon) {
      return [t];
    }

    return [];
  }

  static double _cross(double ax, double ay, double bx, double by) {
    return ax * by - ay * bx;
  }

  static Point _interpolate(Point a, Point b, double t) {
    return Point(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t);
  }

  // -1 = outside, 0 = boundary, 1 = inside.
  static int _pointInRing(Point point, List<Point> ring) {
    bool inside = false;

    for (int i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      final a = ring[j];
      final b = ring[i];

      final cross = _cross(b.x - a.x, b.y - a.y, point.x - a.x, point.y - a.y);

      final dot =
          (point.x - a.x) * (point.x - b.x) + (point.y - a.y) * (point.y - b.y);

      if (cross.abs() <= epsilon && dot <= epsilon) {
        return 0;
      }

      if ((a.y > point.y) != (b.y > point.y)) {
        final x = a.x + (point.y - a.y) * (b.x - a.x) / (b.y - a.y);

        if (point.x < x) {
          inside = !inside;
        }
      }
    }

    return inside ? 1 : -1;
  }

  static int _pointInRegion(Point point, List<Polygon> polygons) {
    for (final polygon in polygons) {
      final outer = _pointInRing(point, polygon.outer);

      if (outer == 0) return 0;
      if (outer == -1) continue;

      bool inHole = false;

      for (final hole in polygon.holes) {
        final result = _pointInRing(point, hole);

        if (result == 0) return 0;
        if (result == 1) {
          inHole = true;
          break;
        }
      }

      if (!inHole) return 1;
    }

    return -1;
  }

  // Reconstruct closed boundaries from directed segments.
  static List<_Ring> _buildRings(List<_Segment> segments) {
    final remaining = List<_Segment>.from(segments);
    final rings = <_Ring>[];

    while (remaining.isNotEmpty) {
      final first = remaining.removeAt(0);

      final points = <Point>[first.a, first.b];

      final startKey = _key(first.a);

      var current = first.b;
      var previous = first.a;

      int safety = segments.length + 1;

      while (safety-- > 0) {
        if (_key(current) == startKey) {
          points.removeLast();

          if (points.length >= 3 && _signedArea(points).abs() > epsilon) {
            rings.add(_Ring(points));
          }

          break;
        }

        final candidates = <_Segment>[];

        for (final segment in remaining) {
          if (_key(segment.a) == _key(current)) {
            candidates.add(segment);
          }
        }

        if (candidates.isEmpty) break;

        final next = _chooseNext(previous, current, candidates);

        remaining.remove(next);

        previous = current;
        current = next.b;

        points.add(current);
      }
    }

    return rings;
  }

  static _Segment _chooseNext(
    Point previous,
    Point current,
    List<_Segment> candidates,
  ) {
    if (candidates.length == 1) return candidates.first;

    final incoming = _angle(previous, current);

    var best = candidates.first;
    var bestTurn = double.infinity;

    for (final candidate in candidates) {
      final outgoing = _angle(candidate.a, candidate.b);

      var turn = outgoing - incoming;

      while (turn < 0) {
        turn += 2 * 3.141592653589793;
      }

      if (turn < bestTurn) {
        bestTurn = turn;
        best = candidate;
      }
    }

    return best;
  }

  static double _angle(Point a, Point b) {
    return _atan2(b.y - a.y, b.x - a.x);
  }

  static double _atan2(double y, double x) {
    // This implementation uses a simple approximation-free
    // angle calculation without importing dart:math.
    if (x == 0) {
      if (y > 0) return 3.141592653589793 / 2;
      if (y < 0) return -3.141592653589793 / 2;
      return 0;
    }

    final z = y / x;
    final absZ = z.abs();

    double angle;

    if (absZ <= 1) {
      angle = z / (1 + 0.28 * z * z);
    } else {
      final inv = 1 / z;
      angle =
          (z > 0 ? 1 : -1) *
          (1.5707963267948966 - inv / (1 + 0.28 * inv * inv));
    }

    if (x < 0) {
      angle += y >= 0 ? 3.141592653589793 : -3.141592653589793;
    }

    return angle;
  }

  static String _key(Point point) {
    return '${(point.x / epsilon).round()}:'
        '${(point.y / epsilon).round()}';
  }

  // Separate positive outer rings and negative hole rings.
  static List<Polygon> _buildPolygons(List<_Ring> rings) {
    final outers = <List<Point>>[];
    final holes = <List<Point>>[];

    for (final ring in rings) {
      if (_signedArea(ring.points) > 0) {
        outers.add(ring.points);
      } else {
        holes.add(ring.points);
      }
    }

    final result = outers.map((outer) {
      return Polygon(outer: outer, holes: []);
    }).toList();

    final assignedHoles = List<List<List<Point>>>.generate(
      result.length,
      (_) => [],
    );

    for (final hole in holes) {
      int bestIndex = -1;
      double bestArea = double.infinity;

      for (int i = 0; i < result.length; i++) {
        if (_pointInRing(hole.first, result[i].outer) == 1) {
          final area = _signedArea(result[i].outer).abs();

          if (area < bestArea) {
            bestArea = area;
            bestIndex = i;
          }
        }
      }

      if (bestIndex != -1) {
        assignedHoles[bestIndex].add(hole);
      }
    }

    return [
      for (int i = 0; i < result.length; i++)
        Polygon(outer: result[i].outer, holes: assignedHoles[i]),
    ];
  }
}

class _Segment {
  final Point a;
  final Point b;

  _Segment(this.a, this.b);
}

class _Ring {
  final List<Point> points;

  _Ring(this.points);
}