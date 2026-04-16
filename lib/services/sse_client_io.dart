import 'dart:async';
import 'package:flutter_client_sse/constants/sse_request_type_enum.dart';
import 'package:flutter_client_sse/flutter_client_sse.dart';

class SseClient {
  StreamSubscription? _sub;

  void connect(
    String url, {
    required void Function() onOpen,
    required void Function(String data) onMessage,
    required void Function(Object error) onError,
  }) {
    close();
    // ignore: avoid_print
    print('SSE(connect): $url');
    _sub = SSEClient.subscribeToSSE(
      method: SSERequestType.GET,
      url: url,
      header: {"Accept": "text/event-stream", "Cache-Control": "no-cache"},
    ).listen((event) {
      if (event.data == null || event.data!.isEmpty) return;
      // ignore: avoid_print
      print('SSE(message): ${event.data}');
      onOpen();
      onMessage(event.data!);
    }, onError: (err) {
      // ignore: avoid_print
      print('SSE(error): $err');
      onError(err);
    });
  }

  void close() {
    _sub?.cancel();
    _sub = null;
    SSEClient.unsubscribeFromSSE();
  }
}
