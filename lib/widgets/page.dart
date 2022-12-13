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
import 'dart:async';

import 'package:decent_git/widgets/deferred_widget.dart';
import 'package:fluent_ui/fluent_ui.dart';

mixin PageMixin {
  Widget description({required Widget content}) {
    return Builder(builder: (context) {
      return Padding(
        padding: const EdgeInsetsDirectional.only(bottom: 4.0),
        child: DefaultTextStyle(
          style: FluentTheme.of(context).typography.body!,
          child: content,
        ),
      );
    });
  }

  Widget subtitle({required Widget content}) {
    return Builder(builder: (context) {
      return Padding(
        padding: const EdgeInsetsDirectional.only(top: 14.0, bottom: 2.0),
        child: DefaultTextStyle(
          style: FluentTheme.of(context).typography.subtitle!,
          child: content,
        ),
      );
    });
  }
}

abstract class Page extends StatelessWidget {
  Page({super.key}) {
    _pageIndex++;
  }

  final StreamController _controller = StreamController.broadcast();

  Stream get stateStream => _controller.stream;

  @override
  Widget build(BuildContext context);

  void setState(VoidCallback func) {
    func();
    _controller.add(null);
  }

  Widget description({required Widget content}) {
    return Builder(builder: (context) {
      return Padding(
        padding: const EdgeInsetsDirectional.only(bottom: 4.0),
        child: DefaultTextStyle(
          style: FluentTheme.of(context).typography.body!,
          child: content,
        ),
      );
    });
  }

  Widget subtitle({required Widget content}) {
    return Builder(builder: (context) {
      return Padding(
        padding: const EdgeInsetsDirectional.only(top: 14.0, bottom: 2.0),
        child: DefaultTextStyle(
          style: FluentTheme.of(context).typography.subtitle!,
          child: content,
        ),
      );
    });
  }
}

int _pageIndex = -1;

abstract class ScrollablePage extends Page {
  ScrollablePage({super.key});

  final scrollController = ScrollController();

  Widget buildHeader(BuildContext context) => const SizedBox.shrink();

  Widget buildBottomBar(BuildContext context) => const SizedBox.shrink();

  List<Widget> buildScrollable(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      key: PageStorageKey(_pageIndex),
      scrollController: scrollController,
      header: buildHeader(context),
      bottomBar: buildBottomBar(context),
      children: buildScrollable(context),
    );
  }
}

class EmptyPage extends Page {
  final Widget? child;

  EmptyPage({
    this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return child ?? const SizedBox.shrink();
  }
}

typedef DeferredPageBuilder = Page Function();

class DeferredPage extends Page {
  final LibraryLoader libraryLoader;
  final DeferredPageBuilder createPage;

  DeferredPage({
    super.key,
    required this.libraryLoader,
    required this.createPage,
  });

  @override
  Widget build(BuildContext context) {
    return DeferredWidget(libraryLoader, () => createPage().build(context));
  }
}

extension PageExtension on List<Page> {
  List<Widget> transform(BuildContext context) {
    return map((page) {
      return StreamBuilder(
        stream: page.stateStream,
        builder: (context, _) {
          return page.build(context);
        },
      );
    }).toList();
  }
}
