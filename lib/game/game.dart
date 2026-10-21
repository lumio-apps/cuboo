import 'dart:math';

import 'shapes.dart';

/// The board is always [kBoardSize] x [kBoardSize].
const int kBoardSize = 8;

/// How many pieces wait in the tray.
const int kTraySize = 3;

/// How many different block colours exist.
const int kColorCount = 5;

/// A piece in the tray: a shape plus the colour it will have on the board.
class Piece {
  const Piece(this.shape, this.color);

  final Shape shape;
  final int color;

  Map<String, dynamic> toJson() => {'s': shape.id, 'c': color};

  static Piece fromJson(Map<String, dynamic> json) {
    final shape = shapeById(json['s'] as String);
    if (shape == null) {
      throw const FormatException('Unknown shape');
    }
    final color = json['c'] as int;
    if (color < 0 || color >= kColorCount) {
      throw const FormatException('Bad colour');
    }
    return Piece(shape, color);
  }
}

/// A cell that was cleared by a move (kept so the UI can animate it).
class ClearedCell {
  const ClearedCell(this.row, this.col, this.color);

  final int row;
  final int col;
  final int color;
}

/// What happened when a piece was placed.
class PlaceResult {
  const PlaceResult({
    required this.placed,
    required this.cleared,
    required this.lines,
    required this.gained,
    required this.combo,
  });

  final List<Pos> placed;
  final List<ClearedCell> cleared;

  /// Number of full rows and columns cleared by this move.
  final int lines;

  /// Points earned by this move.
  final int gained;

  /// The combo count after this move.
  final int combo;
}

/// What would happen if a piece were dropped at a position.
class Preview {
  const Preview({required this.cells, required this.rows, required this.cols});

  final List<Pos> cells;

  /// Rows and columns that would be completed.
  final Set<int> rows;
  final Set<int> cols;
}

class _Snapshot {
  _Snapshot({
    required this.board,
    required this.tray,
    required this.score,
    required this.combo,
  });

  final List<List<int>> board;
  final List<Piece?> tray;
  final int score;
  final int combo;
}

/// The rules of Cuboo. Pure Dart, no Flutter, so it is easy to test.
class CubooGame {
  CubooGame({Random? random})
      : _random = random ?? Random(),
        board = _emptyBoard(),
        tray = List<Piece?>.filled(kTraySize, null),
        score = 0,
        combo = 0,
        undosLeft = 1,
        over = false {
    _refill();
    over = !hasMove;
  }

  /// Builds a game from a given state. Used by tests and by [fromJson].
  CubooGame.withState({
    required List<List<int>> board,
    required List<Piece?> tray,
    this.score = 0,
    this.combo = 0,
    this.undosLeft = 1,
    Random? random,
  })  : _random = random ?? Random(),
        board = [for (final row in board) List<int>.of(row)],
        tray = List<Piece?>.of(tray),
        over = false {
    over = !hasMove;
  }

  factory CubooGame.fromJson(Map<String, dynamic> json, {Random? random}) {
    final flat = (json['board'] as List<dynamic>).cast<int>();
    if (flat.length != kBoardSize * kBoardSize) {
      throw const FormatException('Bad board');
    }
    final board = <List<int>>[];
    for (var r = 0; r < kBoardSize; r++) {
      final row = flat.sublist(r * kBoardSize, (r + 1) * kBoardSize);
      for (final v in row) {
        if (v < -1 || v >= kColorCount) {
          throw const FormatException('Bad cell');
        }
      }
      board.add(row);
    }
    final rawTray = json['tray'] as List<dynamic>;
    if (rawTray.length != kTraySize) {
      throw const FormatException('Bad tray');
    }
    final tray = <Piece?>[
      for (final p in rawTray)
        p == null ? null : Piece.fromJson(p as Map<String, dynamic>),
    ];
    return CubooGame.withState(
      board: board,
      tray: tray,
      score: json['score'] as int,
      combo: json['combo'] as int,
      undosLeft: json['undos'] as int,
      random: random,
    );
  }

  final Random _random;

  /// -1 for an empty cell, otherwise the colour index (0 to 4).
  final List<List<int>> board;

  /// The pieces waiting to be placed. A used piece is null.
  final List<Piece?> tray;

  int score;
  int combo;
  int undosLeft;
  bool over;

  _Snapshot? _snapshot;

  static List<List<int>> _emptyBoard() => [
        for (var r = 0; r < kBoardSize; r++)
          List<int>.filled(kBoardSize, -1),
      ];

  bool get canUndo => undosLeft > 0 && _snapshot != null;

  /// True when at least one piece in the tray fits somewhere.
  bool get hasMove {
    for (final piece in tray) {
      if (piece == null) continue;
      if (_fitsAnywhere(piece.shape)) return true;
    }
    return false;
  }

  bool _fitsAnywhere(Shape shape) {
    for (var r = 0; r <= kBoardSize - shape.height; r++) {
      for (var c = 0; c <= kBoardSize - shape.width; c++) {
        if (_fits(shape, r, c)) return true;
      }
    }
    return false;
  }

  bool _fits(Shape shape, int r, int c) {
    for (final p in shape.cells) {
      final rr = p.r + r;
      final cc = p.c + c;
      if (rr < 0 || cc < 0 || rr >= kBoardSize || cc >= kBoardSize) {
        return false;
      }
      if (board[rr][cc] != -1) return false;
    }
    return true;
  }

  /// Whether tray piece [index] can be dropped with its top-left corner at
  /// ([r], [c]).
  bool canPlace(int index, int r, int c) {
    if (over || index < 0 || index >= kTraySize) return false;
    final piece = tray[index];
    if (piece == null) return false;
    return _fits(piece.shape, r, c);
  }

  /// Shows what dropping piece [index] at ([r], [c]) would do, or null when it
  /// does not fit.
  Preview? preview(int index, int r, int c) {
    if (!canPlace(index, r, c)) return null;
    final piece = tray[index]!;
    final cells = piece.shape.at(r, c);
    final taken = <int>{for (final p in cells) p.r * kBoardSize + p.c};
    bool filled(int rr, int cc) =>
        board[rr][cc] != -1 || taken.contains(rr * kBoardSize + cc);

    final rows = <int>{};
    final cols = <int>{};
    for (var i = 0; i < kBoardSize; i++) {
      var rowFull = true;
      var colFull = true;
      for (var j = 0; j < kBoardSize; j++) {
        if (!filled(i, j)) rowFull = false;
        if (!filled(j, i)) colFull = false;
      }
      if (rowFull) rows.add(i);
      if (colFull) cols.add(i);
    }
    return Preview(cells: cells, rows: rows, cols: cols);
  }

  /// Places tray piece [index]. Returns null when the move is not allowed.
  PlaceResult? place(int index, int r, int c) {
    if (!canPlace(index, r, c)) return null;
    final piece = tray[index]!;

    _snapshot = _Snapshot(
      board: [for (final row in board) List<int>.of(row)],
      tray: List<Piece?>.of(tray),
      score: score,
      combo: combo,
    );

    final placed = piece.shape.at(r, c);
    for (final p in placed) {
      board[p.r][p.c] = piece.color;
    }

    final fullRows = <int>[];
    final fullCols = <int>[];
    for (var i = 0; i < kBoardSize; i++) {
      var rowFull = true;
      var colFull = true;
      for (var j = 0; j < kBoardSize; j++) {
        if (board[i][j] == -1) rowFull = false;
        if (board[j][i] == -1) colFull = false;
      }
      if (rowFull) fullRows.add(i);
      if (colFull) fullCols.add(i);
    }

    final cleared = <ClearedCell>[];
    final seen = <int>{};
    void collect(int rr, int cc) {
      if (seen.add(rr * kBoardSize + cc)) {
        cleared.add(ClearedCell(rr, cc, board[rr][cc]));
      }
    }

    for (final row in fullRows) {
      for (var cc = 0; cc < kBoardSize; cc++) {
        collect(row, cc);
      }
    }
    for (final col in fullCols) {
      for (var rr = 0; rr < kBoardSize; rr++) {
        collect(rr, col);
      }
    }
    for (final cell in cleared) {
      board[cell.row][cell.col] = -1;
    }

    final lines = fullRows.length + fullCols.length;
    combo = lines > 0 ? combo + 1 : 0;
    var gained = piece.shape.size;
    if (lines > 0) {
      gained += lines * lines * 10 * combo;
    }
    score += gained;

    tray[index] = null;
    var allUsed = true;
    for (final p in tray) {
      if (p != null) allUsed = false;
    }
    if (allUsed) _refill();

    over = !hasMove;

    return PlaceResult(
      placed: placed,
      cleared: cleared,
      lines: lines,
      gained: gained,
      combo: combo,
    );
  }

  /// Takes back the last move. Allowed once per game.
  bool undo() {
    final snap = _snapshot;
    if (snap == null || undosLeft <= 0) return false;
    for (var r = 0; r < kBoardSize; r++) {
      for (var c = 0; c < kBoardSize; c++) {
        board[r][c] = snap.board[r][c];
      }
    }
    for (var i = 0; i < kTraySize; i++) {
      tray[i] = snap.tray[i];
    }
    score = snap.score;
    combo = snap.combo;
    undosLeft -= 1;
    _snapshot = null;
    over = !hasMove;
    return true;
  }

  Piece _randomPiece() {
    var total = 0;
    for (final s in kShapes) {
      total += s.weight;
    }
    var pick = _random.nextInt(total);
    var chosen = kShapes.first;
    for (final s in kShapes) {
      if (pick < s.weight) {
        chosen = s;
        break;
      }
      pick -= s.weight;
    }
    return Piece(chosen, _random.nextInt(kColorCount));
  }

  /// Fills the tray with three new pieces. Tries a few times so that at least
  /// one of them fits on the board, which keeps the game fair.
  void _refill() {
    for (var attempt = 0; attempt < 30; attempt++) {
      for (var i = 0; i < kTraySize; i++) {
        tray[i] = _randomPiece();
      }
      if (hasMove) return;
    }
  }

  Map<String, dynamic> toJson() => {
        'v': 1,
        'board': [
          for (final row in board) ...row,
        ],
        'tray': [
          for (final p in tray) p?.toJson(),
        ],
        'score': score,
        'combo': combo,
        'undos': undosLeft,
      };
}
