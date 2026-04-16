import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MjpegView extends StatefulWidget {
  final String url;
  final BoxFit fit;

  const MjpegView({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
  });

  @override
  State<MjpegView> createState() => _MjpegViewState();
}

class _MjpegViewState extends State<MjpegView> {
  StreamController<Uint8List>? _frameController;
  http.Client? _client;
  StreamSubscription<List<int>>? _sub;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant MjpegView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _stop();
      _start();
    }
  }

  Future<void> _start() async {
    _hasError = false;
    _frameController = StreamController<Uint8List>();
    _client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(widget.url));
      request.headers['Accept'] = 'multipart/x-mixed-replace';
      final response = await _client!.send(request);
      if (response.statusCode != 200) {
        setState(() => _hasError = true);
        return;
      }

      final buffer = <int>[];
      _sub = response.stream.listen(
        (chunk) {
          buffer.addAll(chunk);

          while (true) {
            final start = _indexOfJpegStart(buffer);
            if (start == -1) break;
            final end = _indexOfJpegEnd(buffer, start + 2);
            if (end == -1) break;

            final frame = buffer.sublist(start, end + 2);
            _frameController?.add(Uint8List.fromList(frame));
            buffer.removeRange(0, end + 2);
          }
        },
        onError: (_) => setState(() => _hasError = true),
        onDone: () => setState(() => _hasError = true),
        cancelOnError: true,
      );
    } catch (_) {
      setState(() => _hasError = true);
    }
  }

  int _indexOfJpegStart(List<int> data) {
    for (int i = 0; i < data.length - 1; i++) {
      if (data[i] == 0xFF && data[i + 1] == 0xD8) return i;
    }
    return -1;
  }

  int _indexOfJpegEnd(List<int> data, int start) {
    for (int i = start; i < data.length - 1; i++) {
      if (data[i] == 0xFF && data[i + 1] == 0xD9) return i;
    }
    return -1;
  }

  void _stop() {
    _sub?.cancel();
    _client?.close();
    _frameController?.close();
    _frameController = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const SizedBox();
    }

    return StreamBuilder<Uint8List>(
      stream: _frameController?.stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }
        return Image.memory(
          snapshot.data!,
          fit: widget.fit,
          gaplessPlayback: true,
        );
      },
    );
  }
}
