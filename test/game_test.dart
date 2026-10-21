import 'dart:convert';
import 'dart:math';

import 'package:cuboo/game/game.dart';
import 'package:cuboo/game/mode.dart';
import 'package:cuboo/game/shapes.dart';
import 'package:flutter_test/flutter_test.dart';

List<List<int>> emptyBoard() => [
      for (var r = 0; r < kBoardSize; r++) List<int>.filled(kBoardSize, -1),
    ];

Piece piece(String id, [int color = 0]) => Piece(shapeById(id)!, color);

List<Piece?> dots() => [piece('dot'), piece('dot'), piece('dot')];

/// Places the first piece that fits, scanning the board from the top left.
bool playOne(CubooGame game) {
  for (var i = 0; i < kTraySize; i++) {
    for (var r = 0; r < kBoardSize; r++) {
      for (var c = 0; c < kBoardSize; c++) {
        if (game.canPlace(i, r, c)) {
          game.place(i, r, c);
          return true;
        }
      }
    }
  }
  return false;
}

void main() {
  group('shapes', () {
    test('ids are unique and cells start at the top left', () {
      final ids = <String>{};
      for (final shape in kShapes) {
        expect(ids.add(shape.id), isTrue, reason: 'duplicate ${shape.id}');
        expect(shape.cells, isNotEmpty);
        var minR = 99;
        var minC = 99;
        for (final p in shape.cells) {
          if (p.r < minR) minR = p.r;
          if (p.c < minC) minC = p.c;
        }
        expect(minR, 0, reason: shape.id);
        expect(minC, 0, reason: shape.id);
        expect(shape.width <= 5 && shape.height <= 5, isTrue);
        expect(shape.weight, greaterThan(0));
      }
    });

    test('shapeById finds shapes and returns null for unknown ids', () {
      expect(shapeById('dot')?.size, 1);
      expect(shapeById('sq3')?.size, 9);
      expect(shapeById('nope'), isNull);
    });
  });

  group('new game', () {
    test('starts empty with three pieces', () {
      final game = CubooGame(random: Random(1));
      expect(game.score, 0);
      expect(game.combo, 0);
      expect(game.over, isFalse);
      expect(game.undosLeft, 1);
      expect(game.canUndo, isFalse);
      expect(game.tray.where((p) => p != null).length, kTraySize);
      for (final row in game.board) {
        expect(row.every((v) => v == -1), isTrue);
      }
    });

    test('is never over at the start, whatever the seed', () {
      for (var seed = 0; seed < 100; seed++) {
        expect(CubooGame(random: Random(seed)).over, isFalse);
      }
    });
  });

  group('placing', () {
    test('a dot scores one point and uses up its tray slot', () {
      final game = CubooGame.withState(
        board: emptyBoard(),
        tray: [piece('dot', 2), piece('h2'), piece('v2')],
      );
      final result = game.place(0, 3, 3);
      expect(result, isNotNull);
      expect(result!.gained, 1);
      expect(result.lines, 0);
      expect(game.score, 1);
      expect(game.board[3][3], 2);
      expect(game.tray[0], isNull);
      expect(game.canPlace(0, 4, 4), isFalse);
    });

    test('cannot overlap filled cells or leave the board', () {
      final board = emptyBoard();
      board[0][0] = 1;
      final game = CubooGame.withState(
        board: board,
        tray: [piece('dot'), piece('h2'), piece('sq2')],
      );
      expect(game.canPlace(0, 0, 0), isFalse);
      expect(game.place(0, 0, 0), isNull);
      expect(game.canPlace(1, 0, kBoardSize - 1), isFalse);
      expect(game.canPlace(1, 0, kBoardSize - 2), isTrue);
      expect(game.canPlace(2, kBoardSize - 1, 0), isFalse);
      expect(game.canPlace(0, -1, 0), isFalse);
      expect(game.canPlace(3, 0, 0), isFalse);
    });

    test('a full row is cleared and scored', () {
      final board = emptyBoard();
      for (var c = 0; c < kBoardSize - 1; c++) {
        board[0][c] = 1;
      }
      final game = CubooGame.withState(board: board, tray: dots());
      final result = game.place(0, 0, kBoardSize - 1)!;
      expect(result.lines, 1);
      expect(result.cleared.length, kBoardSize);
      expect(result.combo, 1);
      expect(result.gained, 1 + 10);
      expect(game.board[0].every((v) => v == -1), isTrue);
    });

    test('a row and a column cleared together count the shared cell once', () {
      final board = emptyBoard();
      for (var c = 1; c < kBoardSize; c++) {
        board[0][c] = 1;
      }
      for (var r = 1; r < kBoardSize; r++) {
        board[r][0] = 2;
      }
      final game = CubooGame.withState(board: board, tray: dots());
      final result = game.place(0, 0, 0)!;
      expect(result.lines, 2);
      expect(result.cleared.length, kBoardSize * 2 - 1);
      expect(result.gained, 1 + 2 * 2 * 10);
      for (final row in game.board) {
        expect(row.every((v) => v == -1), isTrue);
      }
    });

    test('combo grows while moves keep clearing lines, then resets', () {
      final board = emptyBoard();
      for (var c = 0; c < kBoardSize - 1; c++) {
        board[0][c] = 1;
        board[1][c] = 1;
      }
      final game = CubooGame.withState(
        board: board,
        tray: dots(),
        random: Random(3),
      );
      final first = game.place(0, 0, kBoardSize - 1)!;
      expect(first.combo, 1);
      expect(first.gained, 11);
      final second = game.place(1, 1, kBoardSize - 1)!;
      expect(second.combo, 2);
      expect(second.gained, 1 + 10 * 2);
      final third = game.place(2, 5, 5)!;
      expect(third.lines, 0);
      expect(third.combo, 0);
      expect(third.gained, 1);
    });

    test('the tray is refilled after the third piece', () {
      final game = CubooGame.withState(
        board: emptyBoard(),
        tray: [piece('dot'), null, null],
        random: Random(7),
      );
      game.place(0, 0, 0);
      expect(game.tray.every((p) => p != null), isTrue);
    });
  });

  group('preview', () {
    test('reports the lines a drop would complete', () {
      final board = emptyBoard();
      for (var c = 0; c < kBoardSize - 1; c++) {
        board[0][c] = 1;
      }
      final game = CubooGame.withState(board: board, tray: dots());
      final preview = game.preview(0, 0, kBoardSize - 1)!;
      expect(preview.rows, {0});
      expect(preview.cols, isEmpty);
      expect(preview.cells, [const Pos(0, kBoardSize - 1)]);
      expect(game.preview(0, 3, 3), isNotNull);
      expect(game.preview(0, 0, 0), isNull); // already filled
      expect(game.preview(0, 0, -1), isNull); // off the board
    });

    test('does not change the game', () {
      final game = CubooGame.withState(board: emptyBoard(), tray: dots());
      game.preview(0, 2, 2);
      expect(game.score, 0);
      expect(game.board[2][2], -1);
      expect(game.tray[0], isNotNull);
    });
  });

  group('undo', () {
    test('takes back the last move once', () {
      final game = CubooGame.withState(board: emptyBoard(), tray: dots());
      game.place(0, 3, 3);
      expect(game.canUndo, isTrue);
      expect(game.undo(), isTrue);
      expect(game.board[3][3], -1);
      expect(game.tray[0], isNotNull);
      expect(game.score, 0);
      expect(game.undosLeft, 0);
      expect(game.undo(), isFalse);
      expect(game.canUndo, isFalse);
    });

    test('brings back cleared lines', () {
      final board = emptyBoard();
      for (var c = 0; c < kBoardSize - 1; c++) {
        board[0][c] = 4;
      }
      final game = CubooGame.withState(board: board, tray: dots());
      game.place(0, 0, kBoardSize - 1);
      expect(game.board[0][0], -1);
      game.undo();
      expect(game.board[0][0], 4);
      expect(game.board[0][kBoardSize - 1], -1);
      expect(game.combo, 0);
    });

    test('does nothing before the first move', () {
      final game = CubooGame(random: Random(2));
      expect(game.undo(), isFalse);
      expect(game.undosLeft, 1);
    });
  });

  group('game over', () {
    List<List<int>> almostFull() {
      final board = [
        for (var r = 0; r < kBoardSize; r++) List<int>.filled(kBoardSize, 0),
      ];
      board[0][0] = -1;
      return board;
    }

    test('is over when no piece fits anywhere', () {
      final game = CubooGame.withState(
        board: almostFull(),
        tray: [piece('h2'), piece('v2'), piece('sq2')],
      );
      expect(game.over, isTrue);
      expect(game.hasMove, isFalse);
      expect(game.canPlace(0, 0, 0), isFalse);
      expect(game.place(0, 0, 0), isNull);
    });

    test('is not over while one piece still fits', () {
      final game = CubooGame.withState(
        board: almostFull(),
        tray: [piece('dot'), piece('h2'), null],
      );
      expect(game.over, isFalse);
      final result = game.place(0, 0, 0)!;
      // Every other cell is filled, so the dot completes all rows and columns.
      expect(result.lines, kBoardSize * 2);
      expect(result.cleared.length, kBoardSize * kBoardSize);
      expect(game.over, isFalse);
    });

    test('undo works after the game ended', () {
      // A checkerboard: only single cells are free, so only the dot fits and
      // placing it never completes a line.
      final board = [
        for (var r = 0; r < kBoardSize; r++)
          [for (var c = 0; c < kBoardSize; c++) (r + c) % 2 == 0 ? -1 : 0],
      ];
      final game = CubooGame.withState(
        board: board,
        tray: [piece('dot'), piece('h2'), piece('v2')],
      );
      expect(game.over, isFalse);
      game.place(0, 0, 0);
      expect(game.over, isTrue);
      expect(game.undo(), isTrue);
      expect(game.over, isFalse);
      expect(game.board[0][0], -1);
    });
  });

  group('saving', () {
    test('a game survives a trip through JSON', () {
      final game = CubooGame(random: Random(5));
      for (var i = 0; i < 6; i++) {
        playOne(game);
      }
      final copy = CubooGame.fromJson(
        jsonDecode(jsonEncode(game.toJson())) as Map<String, dynamic>,
      );
      expect(copy.score, game.score);
      expect(copy.combo, game.combo);
      expect(copy.undosLeft, game.undosLeft);
      expect(copy.over, game.over);
      expect(copy.board, game.board);
      for (var i = 0; i < kTraySize; i++) {
        expect(copy.tray[i]?.shape.id, game.tray[i]?.shape.id);
        expect(copy.tray[i]?.color, game.tray[i]?.color);
      }
    });

    test('broken data is rejected', () {
      expect(
        () => CubooGame.fromJson({
          'board': [1, 2, 3],
          'tray': [null, null, null],
          'score': 0,
          'combo': 0,
          'undos': 1,
        }),
        throwsFormatException,
      );
      final good = CubooGame(random: Random(1)).toJson();
      final bad = Map<String, dynamic>.of(good);
      bad['tray'] = [
        {'s': 'does-not-exist', 'c': 0},
        null,
        null,
      ];
      expect(() => CubooGame.fromJson(bad), throwsFormatException);
    });
  });

  test('a long game keeps the rules intact', () {
    final game = CubooGame(random: Random(11));
    var moves = 0;
    var lastScore = 0;
    while (!game.over && moves < 2000) {
      expect(playOne(game), isTrue);
      moves++;
      expect(game.score, greaterThan(lastScore));
      lastScore = game.score;
      for (final row in game.board) {
        for (final v in row) {
          expect(v >= -1 && v < kColorCount, isTrue);
        }
      }
    }
    expect(moves, greaterThan(5));
    if (game.over) {
      expect(game.hasMove, isFalse);
    }
  });

  group('hints, modes and the daily challenge', () {
    test('the hint picks a move that clears a line', () {
      final board = emptyBoard();
      for (var c = 0; c < kBoardSize - 1; c++) {
        board[0][c] = 0;
      }
      final game = CubooGame.withState(
        board: board,
        tray: [piece('dot'), piece('h2'), piece('sq2')],
      );
      final hint = game.findHint()!;
      expect(hint.index, 0);
      expect(hint.r, 0);
      expect(hint.c, kBoardSize - 1);
      expect(game.preview(hint.index, hint.r, hint.c)!.rows, {0});
    });

    test('there is no hint when nothing fits', () {
      final board = [
        for (var r = 0; r < kBoardSize; r++) List<int>.filled(kBoardSize, 0),
      ];
      board[0][0] = -1;
      final game = CubooGame.withState(
        board: board,
        tray: [piece('h2'), null, null],
      );
      expect(game.findHint(), isNull);
    });

    test('clearBoard empties the board and keeps the score', () {
      final board = [
        for (var r = 0; r < kBoardSize; r++) List<int>.filled(kBoardSize, 1),
      ];
      board[0][0] = -1;
      final game = CubooGame.withState(
        board: board,
        tray: [piece('h2'), piece('v2'), null],
        score: 120,
      );
      expect(game.over, isTrue);
      game.clearBoard();
      expect(game.over, isFalse);
      expect(game.score, 120);
      for (final row in game.board) {
        expect(row.every((v) => v == -1), isTrue);
      }
    });

    test('the same seed gives the same pieces', () {
      final a = CubooGame(random: Random(20261021));
      final b = CubooGame(random: Random(20261021));
      expect(
        [for (final p in a.tray) p!.shape.id],
        [for (final p in b.tray) p!.shape.id],
      );
    });

    test('dailySeed is the date as a number', () {
      expect(dailySeed(DateTime(2026, 10, 21)), 20261021);
      expect(dailySeed(DateTime(2027, 1, 5)), 20270105);
    });

    test('mode names are parsed, unknown ones fall back to classic', () {
      expect(GameModeInfo.parse('timed'), GameMode.timed);
      expect(GameModeInfo.parse('nope'), GameMode.classic);
      expect(GameModeInfo.parse(null), GameMode.classic);
    });
  });
}
