import 'package:decent_git/widgets/page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';

class SelectRepo extends ScrollablePage {
  SelectRepo({super.key, required this.onSelected});

  final Function(String path) onSelected;

  @override
  Widget buildHeader(BuildContext context) {
    return const PageHeader(title: Text('Select repo'));
  }

  @override
  List<Widget> buildScrollable(BuildContext context) {
    final text = TextEditingController();
    return [
      Row(children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: 8.0),
            child: TextBox(controller: text),
          ),
        ),
        const SizedBox(width: 10.0),
        IconButton(
            icon: const Icon(FluentIcons.folder_open, size: 16),
            onPressed: () async {
              var path = await FilePicker.platform
                  .getDirectoryPath(dialogTitle: "Select repository");
              if (path != null) {
                text.text = path;
              }
            }),
        const SizedBox(width: 10.0),
        SizedBox(
          width: 100.0,
          child: FilledButton(
              child: Text("Open"),
              onPressed: () {
                onSelected(text.text);
              }),
        ),
      ])
    ];
  }
}
