// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class SseClient {
  html.EventSource? _source;

  void connect(
    String url, {
    required void Function() onOpen,
    required void Function(String data) onMessage,
    required void Function(Object error) onError,
  }) {
    close();
    // ignore: avoid_print
    print('SSE(connect): $url');
    _source = html.EventSource(url, withCredentials: false);
    _source!.onOpen.listen((_) {
      // ignore: avoid_print
      print('SSE(open)');
      onOpen();
    });
    _source!.onMessage.listen((event) {
      if (event.data != null) {
        // ignore: avoid_print
        print('SSE(message): ${event.data}');
        onMessage(event.data as String);
      }
    });
    _source!.onError.listen((event) {
      // ignore: avoid_print
      print('SSE(error): $event');
      onError(event);
    });
  }

  void close() {
    _source?.close();
    _source = null;
  }
}
