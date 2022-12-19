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
  static const batchSize = 1000;

  String selectedContact = '';
  Map<String, List<String>> commitsToBranchNames = {};

  RevWalk? Walk;
  CommitGraphBuilder? graphBuilder;

  bool _endReached = false;
  EasyTableModel<CommitEntry>? _model;

  @override
  void initState() {
    super.initState();
    final repo = widget.sourceRepo;
    final walker = RevWalk(repo);
    Walk = walker;
    for (var branch in repo.branches) {
      final sha = branch.target.sha;
      if (commitsToBranchNames.containsKey(sha)) {
        commitsToBranchNames[sha]!.add(branch.name);
      } else {
        commitsToBranchNames[sha] = [branch.name];
      }
      if (branch.target.pointer.address != 0) {
        walker.push(branch.target);
      } else {
        print(branch);
      }
    }

    _model = EasyTableModel<CommitEntry>(columns: [
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
            final text = Text(
              getCommitMessage(row.row.commit),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              softWrap: false,
              textWidthBasis: TextWidthBasis.parent,
            );
            final branches = row.row.branches;

            if (branches.isEmpty) return text;
            return ClipRect(
                clipBehavior: Clip.antiAlias,
                child: Row(children: [
                  text,
                  ...branches.map((String branch) {
                    return Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Chip(
                          text: Text(branch),
                        ));
                  })
                ]));
          }),
      EasyTableColumn(
          name: 'Commit', weight: 1, stringValue: (row) => row.commit.oid.sha),
      EasyTableColumn(
          name: 'Author',
          weight: 1,
          stringValue: (row) => row.commit.author.name),
      EasyTableColumn(
          name: 'Date', weight: 1, intValue: (row) => row.commit.time)
    ]);

    walker.sorting({GitSort.topological, GitSort.time});
    graphBuilder = CommitGraphBuilder();
    loadNextBatch();
  }

  void loadNextBatch() {
    if (_endReached) return;
    List<CommitEntry> commits = [];
    for (final commit in Walk!.walk(limit: batchSize)) {
      commits.add(CommitEntry(commit, graphBuilder!.buildGraphRow(commit),
          commitsToBranchNames[commit.oid.sha] ?? List.empty()));
    }
    _endReached = commits.length < batchSize;
    _model!.addRows(commits);
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
          _model,
          columnsFit: true,
          lastRowWidget: _endReached ? null : const ProgressBar(),
          onLastRowWidget: _onLastRowWidget,
        ));
  }

  void _onLastRowWidget(bool visible) {
    if (!visible) return;
    setState(() {
      loadNextBatch();
    });
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
