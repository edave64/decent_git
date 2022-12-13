import 'package:fluent_ui/fluent_ui.dart';

import '../commit_tree.dart';
import '../widgets/page.dart' as PageWidget;

class History extends PageWidget.Page {
  History({super.key});

  @override
  Widget buildHeader(BuildContext context) {
    return const PageHeader(title: Text('History'));
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    return CommitTree();
  }
}
