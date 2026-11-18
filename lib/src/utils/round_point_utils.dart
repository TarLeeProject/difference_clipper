List<RoundPoint> roundCorner(List<Point> points, double radius) {
  if (points.length < 3 || radius <= 0) {
    return [];
  }

  final result = <RoundPoint>[];

  for (var i = 0; i < points.length; i++) {
    final prev = points[(i - 1 + points.length) % points.length];
    final current = points[i];
    final next = points[(i + 1) % points.length];

    final v1 = _subtract(prev, current);
    final v2 = _subtract(next, current);

    final len1 = _length(v1);
    final len2 = _length(v2);

    if (len1 < 1e-10 || len2 < 1e-10) {
      continue;
    }

    final dir1 = _scale(v1, 1 / len1);
    final dir2 = _scale(v2, 1 / len2);

    final dot = (dir1.x * dir2.x + dir1.y * dir2.y).clamp(-1.0, 1.0);

    final angle = acos(dot);
    // Distance from corner to tangent points.
    final distance = min(radius / tan(angle / 2), min(len1, len2) / 2);

    final p1 = _add(current, _scale(dir1, distance));
    final p2 = _add(current, _scale(dir2, distance));

    result.add(RoundPoint(originPoint: current, p1: p1, p2: p2));
  }

  return result;
}