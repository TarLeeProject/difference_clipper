class Point {
  final double x;
  final double y;

  const Point(this.x, this.y);

  @override
  String toString() => '($x, $y)';

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != Point) return false;
    final o = other as Point;
    return x == o.x && y == o.y;
  }
}