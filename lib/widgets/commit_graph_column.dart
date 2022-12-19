import 'package:fluent_ui/fluent_ui.dart';
import 'package:libgit2dart/libgit2dart.dart';

class CommitGraphBuilder {
  var colorPool = ColorPool();
  var lines = List<LinePainterBuilder?>.empty(growable: true);

  CommitGraphRow buildGraphRow(Commit commit) {
    final sha = commit.oid.sha;
    final List<LinePainter?> linePainters =
        List.filled(lines.length, null, growable: true);
    var mainLineFound = false;
    final parents = commit.parents;
    final parentsHandled = List.filled(parents.length, false);
    final mergeableLines = List.filled(parents.length, -1);

    int? dotPosition;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line == null) {
        linePainters[i] = null;
        continue;
      }
      if (line.nextCommit == sha) {
        if (!mainLineFound) {
          mainLineFound = true;
          dotPosition = i;
          if (parents.isNotEmpty) {
            line.nextCommit = parents[0].sha;
            linePainters[i] = line.straight();
            parentsHandled[0] = true;
          } else {
            colorPool.relinquishColor(line.color);
            linePainters[i] = line.start();
            lines[i] = null;
          }
        } else {
          linePainters[i] = line.fork();
          colorPool.relinquishColor(line.color);
          lines[i] = null;
        }
        continue;
      }
      if (parents.length > 1) {
        var fittingNextIdx =
            parents.indexWhere((e) => e.sha == line.nextCommit);
        if (fittingNextIdx != -1) {
          mergeableLines[fittingNextIdx] = i;
        }
      }
      linePainters[i] = line.straight();
    }
    for (int i = 0; i < parents.length; i++) {
      if (parentsHandled[i]) continue;
      if (mainLineFound && mergeableLines[i] != -1) {
        final targetI = mergeableLines[i];
        linePainters[targetI] = lines[targetI]!.mergeAndStraight();
      } else {
        var line = LinePainterBuilder(colorPool.requestColor());
        line.nextCommit = parents[i].sha;
        LinePainter linePainter;
        var needDot = false;
        if (!mainLineFound) {
          linePainter = line.stop();
          needDot = true;
          mainLineFound = true;
        } else {
          linePainter = line.merge();
        }
        var gapIdx = linePainters.indexOf(null);
        if (gapIdx != -1) {
          if (needDot) {
            dotPosition = gapIdx;
          }
          lines[gapIdx] = line;
          linePainters[gapIdx] = linePainter;
        } else {
          if (needDot) {
            dotPosition = lines.length;
          }
          lines.add(line);
          linePainters.add(linePainter);
        }
      }
    }
    for (var i = linePainters.length - 1;
        i <= 0 && linePainters[i] == null;
        i--) {
      linePainters.removeLast();
    }

    return CommitGraphRow(linePainters, dotPosition!);
  }
}

class CommitGraphRow {
  final List<LinePainter?> linePainters;
  final int dotPosition;

  CommitGraphRow(this.linePainters, this.dotPosition);
}

const double lineWidth = 2;
const double linePadding = 2;
const double dotRadius = 7;

class GraphRowPainter extends CustomPainter {
  final CommitGraphRow row;

  const GraphRowPainter(this.row);

  @override
  void paint(Canvas canvas, Size size) {
    var dotIdx = row.dotPosition;
    var dotColor = row.linePainters[dotIdx]!.color;
    paintDotBackground(canvas, size, dotIdx, dotColor);
    for (var i = 0; i < row.linePainters.length; ++i) {
      final painter = row.linePainters[i];
      painter?.paint(canvas, size, i, dotIdx);
    }
    paintDot(canvas, size, dotIdx, dotColor);
  }

  @override
  bool shouldRepaint(GraphRowPainter oldDelegate) => false;

  @override
  bool shouldRebuildSemantics(GraphRowPainter oldDelegate) => false;
}

class LinePainter {
  static const typeNone = 0;
  static const typeStraight = 1;
  static const typeStart = 2;
  static const typeStop = 4;
  static const typeMerge = 8;
  static const typeFork = 16;

  final int color;
  int type;

  LinePainter(this.color, this.type);

  void paint(Canvas canvas, Size size, int i, int dotIdx) {
    const offsetXFactor = dotRadius + lineWidth + linePadding;
    final colorPainter = ColorPool.PAINT[color]..strokeWidth = lineWidth;
    final offsetX = offsetXFactor * i;
    if (type & typeStraight != 0) {
      canvas.drawLine(
          Offset(offsetX, 0), Offset(offsetX, size.height), colorPainter);
    }
    if (type & typeStart != 0) {
      canvas.drawLine(
          Offset(offsetX, 0), Offset(offsetX, size.height / 2), colorPainter);
    }
    if (type & typeStop != 0) {
      canvas.drawLine(Offset(offsetX, size.height / 2),
          Offset(offsetX, size.height), colorPainter);
    }
    if (type & typeMerge != 0) {
      canvas.drawLine(Offset(offsetX, size.height),
          Offset(offsetXFactor * dotIdx, size.height / 2), colorPainter);
    }
    if (type & typeFork != 0) {
      canvas.drawLine(Offset(offsetX, 0),
          Offset(offsetXFactor * dotIdx, size.height / 2), colorPainter);
    }
  }
}

void paintDot(Canvas canvas, Size size, int i, int color) {
  Offset circleMid =
      Offset((dotRadius + lineWidth + linePadding) * i, size.height / 2);
  //canvas.drawCircle(circleMid, dotRadius + 1, Paint()..color = Colors.white);
  canvas.drawCircle(circleMid, dotRadius, ColorPool.PAINT[color]);
}

void paintDotBackground(Canvas canvas, Size size, int i, int color) {
  Offset circleMid =
      Offset((dotRadius + lineWidth + linePadding) * i, size.height / 2);
  canvas.drawRect(
      Offset(circleMid.dx, circleMid.dy - dotRadius) &
          Size(size.width - circleMid.dx, dotRadius * 2),
      ColorPool.PAINT_TRANSPARENT[color]);
  canvas.drawRect(
      Offset(size.width - 1, circleMid.dy - dotRadius) &
          const Size(1, dotRadius * 2),
      ColorPool.PAINT[color]);
}

class LinePainterBuilder {
  final int color;
  String? nextCommit;

  LinePainterBuilder(this.color);

  LinePainter start() => LinePainter(color, LinePainter.typeStart);

  LinePainter stop() => LinePainter(color, LinePainter.typeStop);

  LinePainter merge() => LinePainter(color, LinePainter.typeMerge);

  LinePainter mergeAndStraight() =>
      LinePainter(color, LinePainter.typeMerge | LinePainter.typeStraight);

  LinePainter fork() => LinePainter(color, LinePainter.typeFork);

  LinePainter straight() => LinePainter(color, LinePainter.typeStraight);
}

/// Manages the colors of the commit tree.
/// Should always return the currently least used colors.
/// Secondarily, it tries to cycle colors make branches more distinct.
class ColorPool {
  static final COLORS = <Color>[
    Colors.blue,
    Colors.purple,
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.teal
  ];

  static final PAINT =
      COLORS.map((color) => Paint()..color = color).toList(growable: false);
  static final PAINT_TRANSPARENT = COLORS
      .map((color) => Paint()..color = color.withAlpha(50))
      .toList(growable: false);

  var activeAssignments = List<int>.filled(COLORS.length, 0);
  var lastAssignment = -1;
  var highestAssignments = 0;

  int requestColor() {
    var leastAssignmentsI = -1;
    var leastAssignments = highestAssignments + 1;
    for (var i = 0; i < COLORS.length; i++) {
      final j = (i + lastAssignment + 1) % COLORS.length;
      if (activeAssignments[j] < leastAssignments) {
        leastAssignments = activeAssignments[j];
        leastAssignmentsI = j;
      }
    }
    lastAssignment = leastAssignmentsI;
    activeAssignments[leastAssignmentsI]++;
    if (activeAssignments[leastAssignmentsI] > highestAssignments) {
      highestAssignments++;
    }
    return leastAssignmentsI;
  }

  void relinquishColor(int color) {
    activeAssignments[color]--;
  }
}
