Polygon addSpacing(Polygon polygon, double spacing) {
  return Polygon(
    outer: _offsetRing(polygon.outer, spacing),
    holes: polygon.holes.map((hole) => _offsetRing(hole, -spacing)).toList(),
  );
}

List<Point> _offsetRing(List<Point> points, double distance) {
  if (points.length < 3 || distance == 0) {
    return List<Point>.from(points);
  }

  // Determine polygon winding direction.
  final area = _signedArea(points);
  if (area.abs() < 1e-10) {
    throw ArgumentError('Polygon area is zero.');
  }

  // Positive area: outward normal is to the right.
  final direction = area > 0 ? 1.0 : -1.0;

  final result = <Point>[];

  for (var i = 0; i < points.length; i++) {
    final prev = points[(i - 1 + points.length) % points.length];
    final current = points[i];
    final next = points[(i + 1) % points.length];

    final edge1 = _subtract(current, prev);
    final edge2 = _subtract(next, current);

    final len1 = _length(edge1);
    final len2 = _length(edge2);

    if (len1 < 1e-10 || len2 < 1e-10) {
      continue;
    }

    // Outward unit normals.
    final normal1 = Point(
      direction * edge1.y / len1,
      -direction * edge1.x / len1,
    );

    final normal2 = Point(
      direction * edge2.y / len2,
      -direction * edge2.x / len2,
    );

    // Points on the two offset edges.
    final p1 = _add(current, _scale(normal1, distance));
    final p2 = _add(current, _scale(normal2, distance));

    // Intersection of the two offset lines.
    final denominator = _cross(edge1, edge2);

    if (denominator.abs() < 1e-10) {
      // Parallel edges: use the average normal.
      final normal = _normalize(_add(normal1, normal2));

      result.add(_add(current, _scale(normal, distance)));
      continue;
    }

    final t = _cross(_subtract(p2, p1), edge2) / denominator;

    result.add(_add(p1, _scale(edge1, t)));
  }

  return result;
}

double _signedArea(List<Point> points) {
  var area = 0.0;

  for (var i = 0; i < points.length; i++) {
    final a = points[i];
    final b = points[(i + 1) % points.length];

    area += a.x * b.y - b.x * a.y;
  }

  return area / 2;
}