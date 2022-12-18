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
    final parentsHandled = List.filled(commit.parents.length, false);
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line == null) {
        linePainters[i] = null;
        continue;
      }
      if (line.nextCommit == sha) {
        if (!mainLineFound) {
          mainLineFound = true;
          linePainters[i] = commit.parents.isNotEmpty
              ? line.dotAndStraight()
              : line.startDot();
          if (commit.parents.isNotEmpty) {
            line.nextCommit = commit.parents[0].sha;
            parentsHandled[0] = true;
          } else {
            colorPool.relinquishColor(line.color);
            lines[i] = null;
          }
        } else {
          linePainters[i] = line.fork();
          colorPool.relinquishColor(line.color);
          lines[i] = null;
        }
        continue;
      }
      // FIXME: This step is important to avoid strange commit-free lines,
      //        but also might mark all parents of a commit as handled,
      //        without giving it a dot.
      //        Also, such a shortcut line shouldn't be the default, and
      //        should only be created if it would otherwise force the
      //        existence of a new line.

      /*var fittingNextIdx =
            commit.parents.indexWhere((e) => e.sha == line.nextCommit);
        if (fittingNextIdx != -1) {
          linePainters[i] = line.straightAndMerge();
          parentsHandled[fittingNextIdx] = true;
          continue;
        }*/
      linePainters[i] = line.straight();
    }
    for (int i = 0; i < commit.parents.length; i++) {
      if (parentsHandled[i]) continue;
      var gapIdx = linePainters.indexOf(null);
      var line = LinePainterBuilder(colorPool.requestColor());
      line.nextCommit = commit.parents[i].sha;
      LinePainter linePainter;
      if (!mainLineFound) {
        linePainter = line.stopDot();
        mainLineFound = true;
      } else {
        linePainter = line.merge();
      }
      if (gapIdx != -1) {
        lines[gapIdx] = line;
        linePainters[gapIdx] = linePainter;
      } else {
        lines.add(line);
        linePainters.add(linePainter);
      }
    }
    if (!mainLineFound) {
      print("No main line found!");
    }
    for (var i = linePainters.length - 1;
        i <= 0 && linePainters[i] == null;
        i--) {
      linePainters.removeLast();
    }

    return CommitGraphRow(linePainters);
  }
}

class CommitGraphRow {
  final List<LinePainter?> linePainters;

  CommitGraphRow(this.linePainters);
}

const double lineWidth = 2;
const double linePadding = 2;
const double dotRadius = 7;

class GraphRowPainter extends CustomPainter {
  final CommitGraphRow row;

  const GraphRowPainter(this.row);

  @override
  void paint(Canvas canvas, Size size) {
    // FIXME: Double iteration of this loop. Since we expect every line to
    //        contain a dot pointer, maybe we should already construct them
    //        outside of the list.
    var dotIdx =
        row.linePainters.indexWhere((element) => element is DotPainter);
    var dot = row.linePainters[dotIdx] as DotPainter;
    dot.paintBackground(canvas, size, dotIdx);
    for (var i = 0; i < row.linePainters.length; ++i) {
      if (i == dotIdx) continue;
      final painter = row.linePainters[i];
      painter?.paint(canvas, size, i, dotIdx);
    }
    dot.paint(canvas, size, dotIdx, dotIdx);
  }

  @override
  bool shouldRepaint(GraphRowPainter oldDelegate) => false;

  @override
  bool shouldRebuildSemantics(GraphRowPainter oldDelegate) => false;
}

abstract class LinePainter {
  final int color;

  LinePainter(this.color);

  void paint(Canvas canvas, Size size, int i, int dotIdx) {}
}

class MergeLinePainter extends LinePainter {
  MergeLinePainter(super.color);

  @override
  void paint(Canvas canvas, Size size, int i, int dotIdx) {
    canvas.drawLine(
        Offset((dotRadius + lineWidth + linePadding) * i, size.height),
        Offset((dotRadius + lineWidth + linePadding) * dotIdx, size.height / 2),
        ColorPool.PAINT[color]..strokeWidth = lineWidth);
  }
}

class ForkLinePainter extends LinePainter {
  ForkLinePainter(super.color);

  @override
  void paint(Canvas canvas, Size size, int i, int dotIdx) {
    canvas.drawLine(
        Offset((dotRadius + lineWidth + linePadding) * i, 0),
        Offset((dotRadius + lineWidth + linePadding) * dotIdx, size.height / 2),
        ColorPool.PAINT[color]..strokeWidth = lineWidth);
  }
}

class StraightLinePainter extends LinePainter {
  StraightLinePainter(super.color);

  @override
  void paint(Canvas canvas, Size size, int i, int dotIdx) {
    canvas.drawRect(
        Offset((dotRadius + lineWidth + linePadding) * i - lineWidth / 2, 0) &
            Size(lineWidth, size.height),
        ColorPool.PAINT[color]);
  }
}

class DotPainter extends LinePainter {
  DotPainter(super.color);

  @override
  void paint(Canvas canvas, Size size, int i, int dotIdx) {
    Offset circleMid =
        Offset((dotRadius + lineWidth + linePadding) * i, size.height / 2);
    //canvas.drawCircle(circleMid, dotRadius + 1, Paint()..color = Colors.white);
    canvas.drawCircle(circleMid, dotRadius, ColorPool.PAINT[color]);
  }

  void paintBackground(Canvas canvas, Size size, int i) {
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
}

class StraightDotPainter extends DotPainter {
  StraightDotPainter(super.color);

  @override
  void paint(Canvas canvas, Size size, int i, int dotIdx) {
    canvas.drawRect(
        Offset((dotRadius + lineWidth + linePadding) * i - lineWidth / 2, 0) &
            Size(lineWidth, size.height),
        ColorPool.PAINT[color]);
    super.paint(canvas, size, i, dotIdx);
  }
}

class StartDotPainter extends DotPainter {
  StartDotPainter(super.color);

  @override
  void paint(Canvas canvas, Size size, int i, int dotIdx) {
    canvas.drawRect(
        Offset((dotRadius + lineWidth + linePadding) * i - lineWidth / 2, 0) &
            Size(lineWidth, size.height / 2),
        ColorPool.PAINT[color]);
    super.paint(canvas, size, i, dotIdx);
  }
}

class StopDotPainter extends DotPainter {
  StopDotPainter(super.color);

  @override
  void paint(Canvas canvas, Size size, int i, int dotIdx) {
    canvas.drawRect(
        Offset((dotRadius + lineWidth + linePadding) * i - lineWidth / 2,
                size.height / 2) &
            Size(lineWidth, size.height / 2),
        ColorPool.PAINT[color]);
    super.paint(canvas, size, i, dotIdx);
  }
}

class LinePainterBuilder {
  final int color;
  String? nextCommit;

  LinePainterBuilder(this.color);

  StraightDotPainter dotAndStraight() => StraightDotPainter(color);

  DotPainter dot() => DotPainter(color);

  StartDotPainter startDot() => StartDotPainter(color);

  StopDotPainter stopDot() => StopDotPainter(color);

  MergeLinePainter merge() => MergeLinePainter(color);

  ForkLinePainter fork() => ForkLinePainter(color);

  StraightLinePainter straight() => StraightLinePainter(color);
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
