// GENERATED CODE - DO NOT MODIFY BY HAND
// Consider adding this file to your .gitignore.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';


import 'drawer/cubit/drawer_cubit_test.dart' as _a;
import 'drawer/view/drawer_page_test.dart' as _b;
import 'app/view/app_test.dart' as _c;
import 'progress/cubit/progress_cubit_test.dart' as _d;
import 'progress/view/progress_page_test.dart' as _e;
import 'complex_text/view/complex_text_page_test.dart' as _f;
import 'simple_menu/view/simple_menu_test.dart' as _g;
import 'text/cubit/text_cubit_test.dart' as _h;
import 'text/view/text_page_test.dart' as _i;
import 'counter/cubit/counter_cubit_test.dart' as _j;
import 'counter/view/counter_page_test.dart' as _k;
import 'scrollable_list/view/scrollable_list_test.dart' as _l;

void main() {
  goldenFileComparator = _TestOptimizationAwareGoldenFileComparator();
  group('drawer&#x2_f;cubit&#x2_f;drawer_cubit_test_dart', () { _a.main(); });
  group('drawer&#x2_f;view&#x2_f;drawer_page_test_dart', () { _b.main(); });
  group('app&#x2_f;view&#x2_f;app_test_dart', () { _c.main(); });
  group('progress&#x2_f;cubit&#x2_f;progress_cubit_test_dart', () { _d.main(); });
  group('progress&#x2_f;view&#x2_f;progress_page_test_dart', () { _e.main(); });
  group('complex_text&#x2_f;view&#x2_f;complex_text_page_test_dart', () { _f.main(); });
  group('simple_menu&#x2_f;view&#x2_f;simple_menu_test_dart', () { _g.main(); });
  group('text&#x2_f;cubit&#x2_f;text_cubit_test_dart', () { _h.main(); });
  group('text&#x2_f;view&#x2_f;text_page_test_dart', () { _i.main(); });
  group('counter&#x2_f;cubit&#x2_f;counter_cubit_test_dart', () { _j.main(); });
  group('counter&#x2_f;view&#x2_f;counter_page_test_dart', () { _k.main(); });
  group('scrollable_list&#x2_f;view&#x2_f;scrollable_list_test_dart', () { _l.main(); });
}


class _TestOptimizationAwareGoldenFileComparator extends LocalFileComparator {
  final List<String> goldenFilePaths;

  _TestOptimizationAwareGoldenFileComparator()
      : goldenFilePaths = _goldenFilePaths,
        super(_testFile);

  static Uri get _testFile {
    final basedir =
        (goldenFileComparator as LocalFileComparator).basedir.toString();
    return Uri.parse("$basedir/.test_optimizer.dart");
  }

  static List<String> get _goldenFilePaths =>
      Directory.fromUri((goldenFileComparator as LocalFileComparator).basedir)
          .listSync(recursive: true, followLinks: true)
          .whereType<File>()
          .map((file) => file.path)
          .where((path) => path.endsWith('.png'))
          .toList();

  @override
  Uri getTestUri(Uri key, int? version) {
    final keyString = key.path;
    return Uri.parse(goldenFilePaths
        .singleWhere((goldenFilePath) => goldenFilePath.endsWith(keyString)));
  }
}
