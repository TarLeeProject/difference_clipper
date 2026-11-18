List<Polygon> union(List<Polygon> p1, List<Polygon> p2) {
  return _Clipper.union(p1, p2);
}

List<Polygon> difference(List<Polygon> p1, List<Polygon> p2) {
  return _Clipper.difference(p1, p2);
}

List<Polygon> intersection(List<Polygon> p1, List<Polygon> p2) {
  return _Clipper.intersection(p1, p2);
}