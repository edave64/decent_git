import 'package:decent_git/widgets/commit_graph_column.dart';
import 'package:easy_table/easy_table.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:libgit2dart/libgit2dart.dart';

class CommitHistoryTable extends StatefulWidget {
  const CommitHistoryTable({key, required this.sourceRepo}) : super(key: key);
  final Repository sourceRepo;

  @override
  CommitHistoryTableState createState() => CommitHistoryTableState();
}

class CommitHistoryTableState extends State<CommitHistoryTable> {
  String selectedContact = '';
  List<CommitEntry>? commits;
  Map<String, List<String>> map = {};

  @override
  void initState() {
    super.initState();
    final repo = widget.sourceRepo;

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
    final graphBuild = CommitGraphBuilder();
    commits = List.empty(growable: true);
    for (final commit in walker.walk(limit: 1000)) {
      commits!.add(CommitEntry(commit, graphBuild.buildGraphRow(commit),
          map[commit.oid.sha] ?? List.empty()));
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
                    painter: GraphRowPainter(row.row.graphRow),
                    // Provide a the graph painter with the full width of the column
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

String getCommitMessage(Commit commit) {
  final pos = commit.message.indexOf('\n');
  if (pos == -1) return commit.message;
  return commit.message.substring(0, pos);
}

class CommitEntry {
  final Commit commit;
  final CommitGraphRow graphRow;
  final List<String> branches;

  CommitEntry(this.commit, this.graphRow, this.branches);
}
