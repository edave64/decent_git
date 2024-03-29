// Based on https://github.com/bdlukaa/fluent_ui/blob/5f2f9b787ba1f4801fc880d0786a271c9606bb0d/example/lib/main.dart
//
// Copyright 2020 Bruno D'Luka
// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
import 'package:decent_git/screens/history.dart';
import 'package:decent_git/screens/select_repo.dart';
import 'package:fluent_ui/fluent_ui.dart' hide Page;
import 'package:flutter/foundation.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart' as flutter_acrylic;
import 'package:provider/provider.dart';
import 'package:system_theme/system_theme.dart';
import 'package:url_launcher/link.dart';
import 'package:window_manager/window_manager.dart';

import 'known_repositories.dart';
import 'screens/settings.dart';
import 'theme.dart';

const String appTitle = 'Decent Git';

/// Checks if the current environment is a desktop environment.
bool get isDesktop {
  if (kIsWeb) return false;
  return [
    TargetPlatform.windows,
    TargetPlatform.linux,
    TargetPlatform.macOS,
  ].contains(defaultTargetPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // if it's not on the web, windows or android, load the accent color
  if ([TargetPlatform.windows].contains(defaultTargetPlatform)) {
    SystemTheme.accentColor.load();
  }
  await WindowManager.instance.ensureInitialized();
  await flutter_acrylic.Window.initialize();
  runApp(const DecentGit());
  await windowManager.waitUntilReadyToShow();
  await windowManager.setTitleBarStyle(
    TitleBarStyle.hidden,
    windowButtonVisibility: false,
  );
  //await windowManager.setSize(const Size(755, 545));
  //await windowManager.setMinimumSize(const Size(350, 600));
  //await windowManager.center();
  await windowManager.show();
  //await windowManager.setPreventClose(false);
  //await windowManager.setSkipTaskbar(false);
}

class DecentGit extends StatelessWidget {
  const DecentGit({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final focusTheme = FocusThemeData(
      glowFactor: is10footScreen() ? 2.0 : 0.0,
    );

    return ChangeNotifierProvider(
      create: (_) => AppTheme(),
      builder: (context, _) {
        final appTheme = context.watch<AppTheme>();
        return FluentApp(
          title: appTitle,
          themeMode: appTheme.mode,
          debugShowCheckedModeBanner: false,
          color: appTheme.color,
          darkTheme: FluentThemeData(
            brightness: Brightness.dark,
            accentColor: appTheme.color,
            visualDensity: VisualDensity.standard,
            focusTheme: focusTheme,
          ),
          theme: FluentThemeData(
            accentColor: appTheme.color,
            visualDensity: VisualDensity.standard,
            focusTheme: focusTheme,
          ),
          locale: appTheme.locale,
          builder: (context, child) {
            return Directionality(
              textDirection: appTheme.textDirection,
              child: child!,
            );
          },
          home: const MainPage(),
        );
      },
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  MainPageState createState() => MainPageState();
}

class MainPageState extends State<MainPage>
    with WindowListener, KnownRepositories {
  bool value = false;
  int index = 0;
  final viewKey = GlobalKey();

  final List<NavigationPaneItem> footerItems = [
    PaneItemSeparator(),
    PaneItem(
      icon: const Icon(FluentIcons.settings),
      title: const Text('Settings'),
      body: Settings(),
    ),
    LinkPaneItemAction(
      icon: const Icon(FluentIcons.open_source),
      title: const Text('Source code'),
      link: 'https://github.com/edave64/decent_git',
      body: const SizedBox.shrink(),
    ),
  ];

  @override
  void initState() {
    windowManager.addListener(this);
    super.initState();
    loadRepoNames();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = this.repo;
    return NavigationView(
      key: viewKey,
      appBar: NavigationAppBar(
        automaticallyImplyLeading: false,
        title: () {
          return const DragToMoveArea(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(appTitle),
            ),
          );
        }(),
        actions: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          ComboBox(
              items: [
                const ComboBoxItem(
                  value: KnownRepositories.newRepoPlaceholder,
                  child: Text("Add new Repository"),
                ),
                ...repoNames.keys.map((key) => ComboBoxItem(
                      value: key,
                      child: Text(key),
                    ))
              ],
              value: selectedRepo,
              onChanged: (val) {
                if (val == KnownRepositories.newRepoPlaceholder) {
                  setState(() {
                    this.repo = null;
                    selectedRepo = KnownRepositories.newRepoPlaceholder;
                  });
                } else {
                  onRepoSelect(context, val!);
                }
              }),
          const WindowButtons(),
        ]),
      ),
      pane: NavigationPane(
        selected: index,
        onChanged: (i) {
          setState(() => index = i);
        },
        displayMode: PaneDisplayMode.auto,
        indicator: const StickyNavigationIndicator(),
        items: [
          PaneItemHeader(header: const Text('Workspace')),
          PaneItem(
            icon: const Icon(FluentIcons.all_apps),
            title: const Text('History'),
            body: repo == null
                ? SelectRepo(
                    repos: repoNames,
                    onSelected: (String name, String path) {
                      onRepoAdded(context, name, path);
                    })
                : History(sourceRepo: repo),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.branch_commit),
            title: const Text('Commit'),
            body: /* History() */ const Text(""),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.open_folder_horizontal),
            title: const Text('Browse Repository'),
            body: const Text(""),
          ),
          PaneItemHeader(header: const Text('Branches')),
          PaneItemHeader(header: const Text('Tags')),
          PaneItemHeader(header: const Text('Remotes')),
          PaneItemHeader(header: const Text('Shelf')),
          PaneItemHeader(header: const Text('Sub-Repositories')),
        ],
        footerItems: footerItems,
      ),
    );
  }

  @override
  void onWindowClose() async {
    final navigator = Navigator.of(context);
    if (!await windowManager.isPreventClose()) return;

    if (!mounted) return; // Verify the context is still valid.
    await showDialog(
      context: context,
      builder: (_) {
        return ContentDialog(
          title: const Text('Confirm close'),
          content: const Text('Are you sure you want to close this window?'),
          actions: [
            FilledButton(
              child: const Text('Yes'),
              onPressed: () {
                windowManager.destroy();
              },
            ),
            Button(
              child: const Text('No'),
              onPressed: () {},
            ),
          ],
        );
      },
    );
    navigator.pop();
  }

  void openRepository() {}
}

class WindowButtons extends StatelessWidget {
  const WindowButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final FluentThemeData theme = FluentTheme.of(context);

    return SizedBox(
      width: 138,
      height: 50,
      child: WindowCaption(
        brightness: theme.brightness,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}

class LinkPaneItemAction extends PaneItem {
  LinkPaneItemAction({
    required super.icon,
    required this.link,
    required super.body,
    super.title,
  });

  final String link;

  @override
  Widget build(
    BuildContext context,
    bool selected,
    VoidCallback? onPressed, {
    PaneDisplayMode? displayMode,
    bool showTextOnTop = true,
    bool? autofocus,
    int? itemIndex,
  }) {
    return Link(
      uri: Uri.parse(link),
      builder: (context, followLink) => super.build(
        context,
        selected,
        followLink,
        displayMode: displayMode,
        showTextOnTop: showTextOnTop,
        itemIndex: itemIndex,
        autofocus: autofocus,
      ),
    );
  }
}
