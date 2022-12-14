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

// ignore_for_file: constant_identifier_names

import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../theme.dart';
import '../widgets/page.dart';

const List<String> accentColorNames = [
  'System',
  'Yellow',
  'Orange',
  'Red',
  'Magenta',
  'Purple',
  'Blue',
  'Teal',
  'Green',
];

class Settings extends ScrollablePage {
  Settings({super.key});

  @override
  Widget buildHeader(BuildContext context) {
    return const PageHeader(title: Text('Settings'));
  }

  @override
  List<Widget> buildScrollable(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final appTheme = context.watch<AppTheme>();
    const spacer = SizedBox(height: 10.0);
    const biggerSpacer = SizedBox(height: 40.0);

    const supportedLocales = FluentLocalizations.supportedLocales;
    final currentLocale =
        appTheme.locale ?? Localizations.maybeLocaleOf(context);

    return [
      Text('Theme mode', style: FluentTheme.of(context).typography.subtitle),
      spacer,
      ...List.generate(ThemeMode.values.length, (index) {
        final mode = ThemeMode.values[index];
        return Padding(
          padding: const EdgeInsetsDirectional.only(bottom: 8.0),
          child: RadioButton(
            checked: appTheme.mode == mode,
            onChanged: (value) {
              if (value) {
                appTheme.mode = mode;
              }
            },
            content: Text('$mode'.replaceAll('ThemeMode.', '')),
          ),
        );
      }),
      biggerSpacer,
      Text('Accent Color', style: FluentTheme.of(context).typography.subtitle),
      spacer,
      Wrap(children: [
        Tooltip(
          message: accentColorNames[0],
          child: _buildColorBlock(appTheme, systemAccentColor),
        ),
        ...List.generate(Colors.accentColors.length, (index) {
          final color = Colors.accentColors[index];
          return Tooltip(
            message: accentColorNames[index + 1],
            child: _buildColorBlock(appTheme, color),
          );
        }),
      ]),
      biggerSpacer,
      Text('Text Direction',
          style: FluentTheme.of(context).typography.subtitle),
      spacer,
      ...List.generate(TextDirection.values.length, (index) {
        final direction = TextDirection.values[index];
        return Padding(
          padding: const EdgeInsetsDirectional.only(bottom: 8.0),
          child: RadioButton(
            checked: appTheme.textDirection == direction,
            onChanged: (value) {
              if (value) {
                appTheme.textDirection = direction;
              }
            },
            content: Text(
              '$direction'
                  .replaceAll('TextDirection.', '')
                  .replaceAll('rtl', 'Right to left')
                  .replaceAll('ltr', 'Left to right'),
            ),
          ),
        );
      }).reversed,
      Text('Locale', style: FluentTheme.of(context).typography.subtitle),
      spacer,
      Wrap(
        spacing: 15.0,
        runSpacing: 10.0,
        children: List.generate(
          supportedLocales.length,
          (index) {
            final locale = supportedLocales[index];

            return Padding(
              padding: const EdgeInsetsDirectional.only(bottom: 8.0),
              child: RadioButton(
                checked: currentLocale == locale,
                onChanged: (value) {
                  if (value) {
                    appTheme.locale = locale;
                  }
                },
                content: Text('$locale'),
              ),
            );
          },
        ),
      ),
    ];
  }

  Widget _buildColorBlock(AppTheme appTheme, AccentColor color) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Button(
        onPressed: () {
          appTheme.color = color;
        },
        style: ButtonStyle(
          padding: ButtonState.all(EdgeInsets.zero),
          backgroundColor: ButtonState.resolveWith((states) {
            if (states.isPressing) {
              return color.light;
            } else if (states.isHovering) {
              return color.lighter;
            }
            return color;
          }),
        ),
        child: Container(
          height: 40,
          width: 40,
          alignment: AlignmentDirectional.center,
          child: appTheme.color == color
              ? Icon(
                  FluentIcons.check_mark,
                  color: color.basedOnLuminance(),
                  size: 22.0,
                )
              : null,
        ),
      ),
    );
  }
}
