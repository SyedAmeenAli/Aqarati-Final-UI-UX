import 'package:web/web.dart' as web;

import 'backend_mode.dart';

/// QA only (`REVIEW_TOOLS` builds): when the page's local storage has `aq_fail` = `1`, demo calls
/// fail like an offline request, so a browser test can walk the error and retry states. A normal
/// build never reads it.
bool qaCallsFail() {
  if (!kShowReviewTools) return false;
  try {
    return web.window.localStorage.getItem('aq_fail') == '1';
  } catch (_) {
    return false;
  }
}
