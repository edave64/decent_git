import 'dart:collection';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'package:shared_preferences/shared_preferences.dart';

mixin KnownRepositories<T extends StatefulWidget> on State<T> {
  static const newRepoPlaceholder = "#new";
  static const repoSettingsCollection = "repos";
  static const repoSettingsPrefix = "repos.";
  Map<String, String> repoNames = {};
  Repository? repo;
  String selectedRepo = newRepoPlaceholder;

  loadRepoNames() async {
    final prefs = await SharedPreferences.getInstance();
    final repos = prefs.getStringList(repoSettingsCollection);
    if (repos == null) return;

    setState(() {
      for (final repo in repos) {
        final path = prefs.getString("$repoSettingsPrefix$repo");
        if (path == null) continue;
        repoNames[repo] = path;
      }
    });
  }

  onRepoAdded(BuildContext context, String name, String path) {
    final Repository repo;
    try {
      repo = Repository.open(path);
      selectedRepo = name;
    } catch (e) {
      errorMessage(
          context, "Failed to open repository '$path'\n\n${e.toString()}");
      return;
    }
    setState(() {
      repoNames[name] = path;
      this.repo = repo;
    });

    SharedPreferences.getInstance().then((prefs) {
      final list = HashSet<String>.from(repoNames.keys).toList();
      prefs.setStringList(repoSettingsCollection, list);
      prefs.setString("$repoSettingsPrefix$name", path);
    });
  }

  onRepoSelect(BuildContext context, String name) {
    if (repoNames.containsKey(name)) {
      onRepoAdded(context, name, repoNames[name]!);
    } else {
      errorMessage(context, "No known repository called '$name'");
    }
  }
}

void errorMessage(BuildContext context, String content) {
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return ContentDialog(
          title: const Text("Error"),
          content: Text(content),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      });
}
