import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class RealtimeEvent {
  final String type;
  final Map<String, dynamic> data;

  RealtimeEvent(this.type, this.data);
}

class TransactionRealtimeService {
  final String wsUrl;
  WebSocketChannel? _channel;
  final _controller = StreamController<RealtimeEvent>.broadcast();
  Timer? _reconnectTimer;

  TransactionRealtimeService(this.wsUrl);

  Stream<RealtimeEvent> get events => _controller.stream;

  void connect() {
    if (_channel != null) return;

    try {
      debugPrint('Connecting to WebSocket: $wsUrl');
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
        (message) {
          try {
            final decoded = jsonDecode(message) as Map<String, dynamic>;
            final event = decoded['event'] as String;
            final data = decoded['data'] as Map<String, dynamic>;
            _controller.add(RealtimeEvent(event, data));
          } catch (e) {
            debugPrint('Error parsing WebSocket message: $e');
          }
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _reconnect();
        },
        onDone: () {
          debugPrint('WebSocket closed');
          _reconnect();
        },
      );
    } catch (e) {
      debugPrint('Error connecting to WebSocket: $e');
      _reconnect();
    }
  }

  void _reconnect() {
    _channel = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      debugPrint('Reconnecting WebSocket...');
      connect();
    });
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
    _controller.close();
  }
}
