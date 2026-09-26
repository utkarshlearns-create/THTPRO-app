import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs before every test in this package.
///
/// Its only job is to put the real typeface in front of the golden tests. A
/// widget test otherwise draws every glyph in Ahem — the black-box placeholder
/// font — so a golden would happily lock in a wall of rectangles and then pass
/// forever while the actual type broke. Loading the bundled faces means the
/// goldens record letterforms, weights and the letter-spacing the brand lockup
/// depends on.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadBundledFonts();
  return testMain();
}

Future<void> _loadBundledFonts() async {
  const files = <String>[
    'assets/fonts/PlusJakartaSans-Regular.ttf',
    'assets/fonts/PlusJakartaSans-Medium.ttf',
    'assets/fonts/PlusJakartaSans-SemiBold.ttf',
    'assets/fonts/PlusJakartaSans-Bold.ttf',
    'assets/fonts/PlusJakartaSans-ExtraBold.ttf',
  ];

  await _loadMaterialIcons();

  final loader = FontLoader('PlusJakartaSans');
  var loaded = 0;
  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) continue;
    loader.addFont(file.readAsBytes().then(ByteData.sublistView));
    loaded++;
  }
  // A missing font is not worth failing the whole suite over — the non-golden
  // tests do not care, and a golden mismatch will say so loudly enough.
  if (loaded > 0) await loader.load();
}

/// Material's icon font, which a widget test otherwise draws as empty squares.
///
/// It is the app's own bundle the font is read from, not the SDK's install
/// path — `uses-material-design: true` puts it there, so this works on a CI
/// machine that has Flutter somewhere else entirely.
Future<void> _loadMaterialIcons() async {
  try {
    final data = await rootBundle.load(
      'fonts/MaterialIcons-Regular.otf',
    );
    await (FontLoader('MaterialIcons')..addFont(Future.value(data))).load();
  } catch (_) {
    // Same reasoning as the bundled faces: a missing icon font is a golden
    // diff, not a reason to fail every test in the package.
  }
}
