import 'package:easy_table/easy_table.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:libgit2dart/libgit2dart.dart';

class CommitTree extends StatefulWidget {
  const CommitTree({key}) : super(key: key);

  @override
  CommitTreeState createState() => CommitTreeState();
}

class CommitTreeState extends State<CommitTree> {
  String selectedContact = '';
  List<CommitEntry>? commits;
  Map<String, List<String>> map = {};

  @override
  void initState() {
    super.initState();

    final repo = Repository.open('/home/edave/Documents/projects/dddg/.git/');
    final walker = RevWalk(repo);
    for (var branch in repo.branches) {
      final sha = branch.target.sha;
      if (map.containsKey(sha)) {
        map[sha]!.add(branch.name);
      } else {
        map[sha] = [branch.name];
      }
      if (branch.target.pointer.address != 0) {
        walker.push(branch.target);
      } else {
        print(branch);
      }
    }

    walker.sorting({GitSort.topological, GitSort.time});
    var colorPool = ColorPool();
    var lines = List<LinePainterBuilder?>.empty(growable: true);
    commits = List.empty(growable: true);
    for (final commit in walker.walk(limit: 1000)) {
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

        /*var fittingNextIdx =
            commit.parents.indexWhere((e) => e.sha == line.nextCommit);
        if (fittingNextIdx != -1) {
          linePainters[i] = line.straight();
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
      commits!.add(CommitEntry(
          commit, linePainters, map[commit.oid.sha] ?? List.empty()));
      for (var i = linePainters.length - 1;
          i <= 0 && linePainters[i] == null;
          i--) {
        linePainters.removeLast();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return EasyTableTheme(
        data: const EasyTableThemeData(
            columnDividerFillHeight: false,
            columnDividerThickness: 0,
            decoration: BoxDecoration(border: null),
            row: RowThemeData(dividerThickness: 0)),
        child: EasyTable<CommitEntry>(
          EasyTableModel<CommitEntry>(rows: commits!, columns: [
            EasyTableColumn(
                name: 'Graph',
                weight: 1,
                cellBuilder: (context, row) {
                  return CustomPaint(
                    painter: Sky(row.row),
                    child: const SizedBox.expand(child: Text("")),
                  );
                }),
            EasyTableColumn(
                name: 'Description',
                weight: 5,
                cellBuilder: (context, row) {
                  final text = Text(getCommitMessage(row.row.commit));
                  final branches = row.row.branches;

                  if (branches.isEmpty) return text;
                  return Row(children: [
                    text,
                    ...branches.map((String branch) {
                      return Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Chip(
                            text: Text(branch),
                          ));
                    })
                  ]);
                },
                stringValue: (row) => ""),
            EasyTableColumn(
                name: 'Commit',
                weight: 1,
                stringValue: (row) => row.commit.oid.sha),
            EasyTableColumn(
                name: 'Author',
                weight: 1,
                stringValue: (row) => row.commit.author.name),
            EasyTableColumn(
                name: 'Date', weight: 1, intValue: (row) => row.commit.time)
          ]),
          columnsFit: true,
        ));
  }
}

const double lineWidth = 2;
const double linePadding = 2;
const double dotRadius = 7;

String getCommitMessage(Commit commit) {
  final pos = commit.message.indexOf('\n');
  if (pos == -1) return commit.message;
  return commit.message.substring(0, pos);
}

class Sky extends CustomPainter {
  final CommitEntry row;

  const Sky(this.row);

  @override
  void paint(Canvas canvas, Size size) {
    var dotIdx =
        row.linePainters.indexWhere((element) => element is DotPainter);
    if (dotIdx >= 0) {
      (row.linePainters[dotIdx] as DotPainter)
          .paintBackground(canvas, size, dotIdx);
    }
    for (var i = 0; i < row.linePainters.length; ++i) {
      if (i == dotIdx) continue;
      final painter = row.linePainters[i];
      painter?.paint(canvas, size, i, dotIdx);
    }
    if (dotIdx >= 0) {
      (row.linePainters[dotIdx] as DotPainter)
          .paint(canvas, size, dotIdx, dotIdx);
    }
/*    final Rect rect = Offset.zero & Size(lineWidth, size.height);
    final paint = Paint()..color = Colors.blue;
    final gradientRect = Offset(2, size.height / 2 - dotRadius) &
        Size(size.width, dotRadius * 2);
    final gradient = Paint()
      ..shader = LinearGradient(
          colors: [Colors.blue.withAlpha(20), Colors.blue.withAlpha(80)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          stops: const [0.0, 1.0]).createShader(gradientRect);
    canvas.drawRect(rect, paint);
    canvas.drawRect(gradientRect, gradient);
    canvas.drawRect(
        Offset(size.width, gradientRect.top) & Size(2, gradientRect.height),
        paint);
    canvas.drawCircle(size.centerLeft(const Offset(2, 0)), dotRadius, paint);
 */
  }

  // Since this Sky painter has no fields, it always paints
  // the same thing and semantics information is the same.
  // Therefore we return false here. If we had fields (set
  // from the constructor) then we would return true if any
  // of them differed from the same fields on the oldDelegate.
  @override
  bool shouldRepaint(Sky oldDelegate) => false;

  @override
  bool shouldRebuildSemantics(Sky oldDelegate) => false;
}

class CommitEntry {
  final Commit commit;
  final List<LinePainter?> linePainters;
  final List<String> branches;

  CommitEntry(this.commit, this.linePainters, this.branches);
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
  var lastAssignment = 0;
  var highestAssignments = 0;

  int requestColor() {
    var leastAssignmentsI = -1;
    var leastAssignments = highestAssignments + 1;
    for (var i = 0; i < COLORS.length; i++) {
      final j = (i + lastAssignment) % COLORS.length;
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
