import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Decodes and displays an MJPEG HTTP stream.
///
/// MJPEG streams consist of sequential JPEG frames separated by
/// multipart boundaries. This widget connects via HTTP, splits
/// on JPEG SOI/EOI markers, and renders each frame.
class MjpegViewer extends StatefulWidget {
  final String streamUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const MjpegViewer({
    super.key,
    required this.streamUrl,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  @override
  State<MjpegViewer> createState() => _MjpegViewerState();
}

class _MjpegViewerState extends State<MjpegViewer> {
  Uint8List? _currentFrame;
  bool _isConnected = false;
  String? _error;
  StreamSubscription<List<int>>? _subscription;
  http.Client? _client;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  @override
  void didUpdateWidget(MjpegViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streamUrl != widget.streamUrl) {
      _disconnect();
      _connect();
    }
  }

  @override
  void dispose() {
    _disconnect();
    super.dispose();
  }

  void _connect() {
    if (widget.streamUrl.isEmpty) return;

    setState(() {
      _error = null;
      _isConnected = false;
    });

    _client = http.Client();
    final request = http.Request('GET', Uri.parse(widget.streamUrl));

    _client!.send(request).then((response) {
      if (response.statusCode != 200) {
        if (mounted) {
          setState(() {
            _error = 'HTTP ${response.statusCode}';
          });
        }
        return;
      }

      if (mounted) {
        setState(() => _isConnected = true);
      }

      final buffer = BytesBuilder(copy: false);

      _subscription = response.stream.listen(
        (chunk) {
          buffer.add(chunk);
          _extractFrames(buffer);
        },
        onError: (Object error) {
          if (mounted) {
            setState(() {
              _isConnected = false;
              _error = 'Stream error';
            });
          }
        },
        onDone: () {
          if (mounted) {
            setState(() {
              _isConnected = false;
              _error = 'Stream ended';
            });
          }
        },
      );
    }).catchError((Object error) {
      if (mounted) {
        setState(() {
          _error = 'Connection failed';
        });
      }
    });
  }

  void _extractFrames(BytesBuilder buffer) {
    // JPEG SOI = 0xFF 0xD8, EOI = 0xFF 0xD9
    final data = buffer.toBytes();
    int soiIndex = -1;

    for (int i = 0; i < data.length - 1; i++) {
      if (data[i] == 0xFF && data[i + 1] == 0xD8) {
        soiIndex = i;
      }
      if (soiIndex >= 0 && data[i] == 0xFF && data[i + 1] == 0xD9) {
        // Found complete JPEG frame
        final frame = Uint8List.fromList(
          data.sublist(soiIndex, i + 2),
        );

        if (mounted) {
          setState(() {
            _currentFrame = frame;
          });
        }

        // Keep remaining bytes after this frame
        final remaining = data.sublist(i + 2);
        buffer.clear();
        if (remaining.isNotEmpty) {
          buffer.add(remaining);
        }
        return;
      }
    }

    // Prevent unbounded buffer growth (max ~2MB)
    if (data.length > 2 * 1024 * 1024) {
      buffer.clear();
    }
  }

  void _disconnect() {
    _subscription?.cancel();
    _subscription = null;
    _client?.close();
    _client = null;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_error != null) {
      return _buildStatus(
        context,
        Icons.videocam_off,
        _error!,
        showRetry: true,
      );
    }

    if (!_isConnected || _currentFrame == null) {
      return _buildStatus(
        context,
        Icons.hourglass_empty,
        'Connecting...',
      );
    }

    return Image.memory(
      _currentFrame!,
      fit: widget.fit,
      gaplessPlayback: true,
    );
  }

  Widget _buildStatus(
    BuildContext context,
    IconData icon,
    String message, {
    bool showRetry = false,
  }) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 40,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            if (showRetry) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  _disconnect();
                  _connect();
                },
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
