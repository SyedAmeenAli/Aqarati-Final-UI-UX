import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/widgets.dart';

/// Lets `web/index.html` hand keyboard focus from a text field to the next control: Flutter keeps a
/// focused text field's input active, so the page asks the app to let go of it first.
void installWebKeyboardSupport() {
  globalContext.setProperty(
    'aqReleaseTextFocus'.toJS,
    (() => FocusManager.instance.primaryFocus?.unfocus()).toJS,
  );
}
