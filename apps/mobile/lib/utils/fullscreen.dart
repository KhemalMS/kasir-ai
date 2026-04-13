import 'dart:js_interop';
import 'dart:js_interop_unsafe';

void toggleFullScreen() {
  final script = '''
    if (!document.fullscreenElement) {
      document.documentElement.requestFullscreen().catch((err) => {
        console.log(`Error attempting to enable fullscreen: \${err.message}`);
      });
    } else {
      if (document.exitFullscreen) {
        document.exitFullscreen();
      }
    }
  '''.toJS;
  globalContext.callMethod('eval'.toJS, script);
}

bool isFullScreen() {
  final script = '''
    (function() { return !!document.fullscreenElement; })();
  '''.toJS;
  final result = globalContext.callMethod('eval'.toJS, script);
  return result != null && result.toString() == 'true';
}
