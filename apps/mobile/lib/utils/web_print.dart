import 'dart:js_interop';
import 'dart:js_interop_unsafe';

void triggerWebPrint() {}

void printReceiptHtml(String html) {
  // Inject the iframe-based print helper and call it
  final helperScript = '''
    window._printReceiptViaIframe = function(h) {
      var old = document.getElementById('__receipt_print_frame');
      if (old) old.remove();

      var iframe = document.createElement('iframe');
      iframe.id = '__receipt_print_frame';
      iframe.style.position = 'fixed';
      iframe.style.right = '0';
      iframe.style.bottom = '0';
      iframe.style.width = '0';
      iframe.style.height = '0';
      iframe.style.border = 'none';
      iframe.style.opacity = '0';
      document.body.appendChild(iframe);

      var doc = iframe.contentDocument || iframe.contentWindow.document;
      doc.open();
      doc.write(h);
      doc.close();

      setTimeout(function() {
        iframe.contentWindow.focus();
        iframe.contentWindow.print();
      }, 500);
    };
  '''.toJS;
  globalContext.callMethod('eval'.toJS, helperScript);
  globalContext.callMethod('_printReceiptViaIframe'.toJS, html.toJS);
}
