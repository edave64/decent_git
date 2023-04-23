import 'package:fluent_ui/fluent_ui.dart';
import 'package:libgit2dart/libgit2dart.dart';

import '../widgets/commit_history.dart';
import '../widgets/page.dart' as page_widget;

class History extends page_widget.Page {
  History({super.key, required this.sourceRepo});

  final Repository? sourceRepo;

  Widget buildHeader(BuildContext context) {
    return const PageHeader(title: Text('History'));
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final repo = sourceRepo;

    return ScaffoldPage(
      padding: const EdgeInsets.all(0),
      header: CommandBar(
        primaryItems: [
          CommandBarButton(
              icon: const Icon(FluentIcons.download),
              label: const Text("Fetch"),
              onPressed: () {
                if (repo == null) return;
                for (final name in repo.remotes) {
                  final remote = Remote.lookup(repo: repo, name: name);
                  remote.fetch(
                      callbacks: Callbacks(transferProgress: (progess) {}));
                }
                setState(() {});
              })
        ],
      ),
      content: repo == null
          ? const Text("No Repository selected!")
          : CommitHistoryTable(sourceRepo: repo),
    );
  }
}
