Point _subtract(Point a, Point b) => Point(a.x - b.x, a.y - b.y);

Point _add(Point a, Point b) => Point(a.x + b.x, a.y + b.y);

Point _scale(Point p, double value) => Point(p.x * value, p.y * value);

double _length(Point p) => sqrt(p.x * p.x + p.y * p.y);

double _cross(Point a, Point b) => a.x * b.y - a.y * b.x;

Point _normalize(Point p) {
  final len = _length(p);

  if (len < 1e-10) {
    return const Point(0, 0);
  }

  return Point(p.x / len, p.y / len);
}