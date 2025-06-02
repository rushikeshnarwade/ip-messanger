import 'dart:async';
import 'webrtc_service.dart';

class MessageService {
  final WebRTCService _webRTCService;
  final _messageErrorController = StreamController<String>.broadcast();
  bool _isDisposed = false;

  Stream<String> get messageErrors => _messageErrorController.stream;

  MessageService(this._webRTCService);

  void _safeAddError(String error) {
    if (!_isDisposed && !_messageErrorController.isClosed) {
      _messageErrorController.add(error);
    }
  }

  Future<bool> sendMessage(String message) async {
    if (_isDisposed) return false;

    if (message.trim().isEmpty) {
      _safeAddError('Message cannot be empty');
      return false;
    }

    try {
      if (!_webRTCService.isReadyForCommunication()) {
        _safeAddError('Connection not ready. Please wait or reconnect.');
        return false;
      }

      final success = await _webRTCService.sendMessage(message);
      if (!success) {
        _safeAddError('Failed to send message. Please try again.');
      }
      return success;
    } catch (e) {
      _safeAddError('Error sending message: $e');
      return false;
    }
  }

  void dispose() {
    _isDisposed = true;
    if (!_messageErrorController.isClosed) {
      _messageErrorController.close();
    }
  }
}
