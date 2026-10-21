/// A position on the board (row, column).
class Pos {
  const Pos(this.r, this.c);

  final int r;
  final int c;

  @override
  bool operator ==(Object other) =>
      other is Pos && other.r == r && other.c == c;

  @override
  int get hashCode => r * 31 + c;

  @override
  String toString() => 'Pos($r, $c)';
}

/// A block shape: a set of cells whose top-left corner is at (0, 0).
class Shape {
  const Shape(this.id, this.cells, this.weight);

  final String id;
  final List<Pos> cells;

  /// How often the shape shows up (higher = more often).
  final int weight;

  int get size => cells.length;

  int get height {
    var m = 0;
    for (final p in cells) {
      if (p.r > m) m = p.r;
    }
    return m + 1;
  }

  int get width {
    var m = 0;
    for (final p in cells) {
      if (p.c > m) m = p.c;
    }
    return m + 1;
  }

  /// The cells of this shape when its top-left corner sits at ([r], [c]).
  List<Pos> at(int r, int c) =>
      [for (final p in cells) Pos(p.r + r, p.c + c)];
}

List<Pos> _normalize(List<Pos> cells) {
  var minR = cells.first.r;
  var minC = cells.first.c;
  for (final p in cells) {
    if (p.r < minR) minR = p.r;
    if (p.c < minC) minC = p.c;
  }
  final out = [for (final p in cells) Pos(p.r - minR, p.c - minC)];
  out.sort((a, b) => a.r != b.r ? a.r.compareTo(b.r) : a.c.compareTo(b.c));
  return out;
}

List<Pos> _rotate(List<Pos> cells) {
  var maxR = 0;
  for (final p in cells) {
    if (p.r > maxR) maxR = p.r;
  }
  return _normalize([for (final p in cells) Pos(p.c, maxR - p.r)]);
}

String _signature(List<Pos> cells) =>
    [for (final p in cells) '${p.r},${p.c}'].join(';');

List<Shape> _family(String name, List<Pos> base, int weight) {
  final seen = <String>{};
  final out = <Shape>[];
  var current = _normalize(base);
  for (var i = 0; i < 4; i++) {
    final sig = _signature(current);
    if (seen.add(sig)) {
      out.add(Shape('$name$i', current, weight));
    }
    current = _rotate(current);
  }
  return out;
}

List<Pos> _line(int length, {required bool horizontal}) => [
      for (var i = 0; i < length; i++)
        horizontal ? Pos(0, i) : Pos(i, 0),
    ];

List<Pos> _rect(int rows, int cols) => [
      for (var r = 0; r < rows; r++)
        for (var c = 0; c < cols; c++) Pos(r, c),
    ];

List<Shape> _buildShapes() {
  final out = <Shape>[
    const Shape('dot', [Pos(0, 0)], 3),
    Shape('h2', _line(2, horizontal: true), 5),
    Shape('v2', _line(2, horizontal: false), 5),
    Shape('h3', _line(3, horizontal: true), 5),
    Shape('v3', _line(3, horizontal: false), 5),
    Shape('h4', _line(4, horizontal: true), 3),
    Shape('v4', _line(4, horizontal: false), 3),
    Shape('h5', _line(5, horizontal: true), 2),
    Shape('v5', _line(5, horizontal: false), 2),
    Shape('sq2', _rect(2, 2), 5),
    Shape('sq3', _rect(3, 3), 2),
    Shape('r23', _rect(2, 3), 3),
    Shape('r32', _rect(3, 2), 3),
  ];
  // Small corner (3 cells).
  out.addAll(_family('corner', const [Pos(0, 0), Pos(1, 0), Pos(1, 1)], 4));
  // Big corner (5 cells).
  out.addAll(_family(
    'bigcorner',
    const [Pos(0, 0), Pos(1, 0), Pos(2, 0), Pos(2, 1), Pos(2, 2)],
    2,
  ));
  // L and J (4 cells).
  out.addAll(_family(
    'ell',
    const [Pos(0, 0), Pos(1, 0), Pos(2, 0), Pos(2, 1)],
    3,
  ));
  out.addAll(_family(
    'jay',
    const [Pos(0, 1), Pos(1, 1), Pos(2, 1), Pos(2, 0)],
    3,
  ));
  // T (4 cells).
  out.addAll(_family(
    'tee',
    const [Pos(0, 0), Pos(0, 1), Pos(0, 2), Pos(1, 1)],
    3,
  ));
  // S and Z (4 cells).
  out.addAll(_family(
    'ess',
    const [Pos(0, 1), Pos(0, 2), Pos(1, 0), Pos(1, 1)],
    2,
  ));
  out.addAll(_family(
    'zed',
    const [Pos(0, 0), Pos(0, 1), Pos(1, 1), Pos(1, 2)],
    2,
  ));
  return out;
}

/// Every shape the game can hand out.
final List<Shape> kShapes = _buildShapes();

/// The shape that [shape] becomes when turned a quarter turn. Shapes that
/// look the same turned (like the 2x2 square) come back unchanged.
Shape rotateShape(Shape shape) {
  final wanted = _signature(_rotate(shape.cells));
  for (final s in kShapes) {
    if (_signature(s.cells) == wanted) return s;
  }
  return shape;
}

/// Looks a shape up by its id, or returns null when it does not exist.
Shape? shapeById(String id) {
  for (final s in kShapes) {
    if (s.id == id) return s;
  }
  return null;
}
