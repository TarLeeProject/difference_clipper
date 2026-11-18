class Polygon {
  final List<Point> outer;
  final List<List<Point>> holes;

  const Polygon({required this.outer, this.holes = const []});

  @override
  String toString() {
    return '''outer: [${outer.map((point) => point.toString()).join(', ')}]
holes:
${holes.map((hole) => '\t[${hole.map((point) => point.toString()).join(', ')}]').join('\n')}''';
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != Polygon) return false;
    final o = other as Polygon;
    return outer == o.outer &&
        holes.length == o.holes.length &&
        holes.every((h) => o.holes.contains(h));
  }
}