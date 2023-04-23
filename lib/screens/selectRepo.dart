import 'package:decent_git/widgets/page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';

class SelectRepo extends ScrollablePage {
  SelectRepo({super.key, required this.onSelected, required this.repos});

  final Function(String name, String path) onSelected;
  final Map<String, String> repos;

  final name = TextEditingController();
  final path = TextEditingController();

  bool userModifiedProjectName = false;

  @override
  Widget buildHeader(BuildContext context) {
    return const PageHeader(title: Text('Select repo'));
  }

  @override
  List<Widget> buildScrollable(BuildContext context) {
    return [
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: 8.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: InfoLabel(
                          label: "Path to the git folder",
                          child: TextBox(
                              controller: path,
                              onChanged: (text) => autocompleteName(text))),
                    ),
                    const SizedBox(width: 10.0),
                    IconButton(
                        icon: const Icon(FluentIcons.folder_open, size: 16),
                        onPressed: () async {
                          var newPath = await FilePicker.platform
                              .getDirectoryPath(
                                  dialogTitle: "Select repository");
                          if (newPath != null) {
                            path.text = newPath;
                            autocompleteName(newPath);
                          }
                        }),
                  ],
                ),
                const SizedBox(height: 10.0),
                Row(children: [
                  Expanded(
                      child: InfoLabel(
                          label: "Project name",
                          child: TextBox(
                            controller: name,
                            onChanged: (val) {
                              userModifiedProjectName = true;
                            },
                          )))
                ])
              ],
            ),
          ),
        ),
        const SizedBox(width: 10.0),
        SizedBox(
          width: 100.0,
          child: FilledButton(
              child: const Text("Open"),
              onPressed: () {
                onSelected(name.text, path.text);
              }),
        ),
      ])
    ];
  }

  void autocompleteName(String path) {
    const MapEntry<String, String> placeholder = MapEntry("#none#", "#none#");
    final lookup = repos.entries.firstWhere((element) => element.value == path,
        orElse: () => placeholder);
    if (lookup != placeholder) {
      name.text = lookup.key;
    } else if (!userModifiedProjectName) {
      final parts = path.split(RegExp("[/\\\\]"));
      int lastPart = parts.length - 1;
      while (lastPart > 0 &&
          (parts[lastPart].isEmpty || parts[lastPart] == ".git")) {
        lastPart--;
      }
      name.text = parts[lastPart];
    }
  }
}
