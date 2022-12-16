import 'package:fluent_ui/fluent_ui.dart';
import 'package:libgit2dart/libgit2dart.dart';

import '../commit_tree.dart';
import '../widgets/page.dart' as PageWidget;

class History extends PageWidget.Page {
  History({super.key, required this.sourceRepo});

  final Repository? sourceRepo;

  @override
  Widget buildHeader(BuildContext context) {
    return const PageHeader(title: Text('History'));
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final repo = sourceRepo;
    if (repo == null) {
      return Text("No Repository selected!");
    } else {
      return CommitTree(sourceRepo: repo);
    }
  }
}
