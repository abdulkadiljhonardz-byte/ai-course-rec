import 'dart:io';

Future<bool> hasInternetConnection() async {
  Socket? socket;
  try {
    socket = await Socket.connect(
      'api.groq.com',
      443,
      timeout: const Duration(seconds: 4),
    );
    return true;
  } on Object {
    return false;
  } finally {
    socket?.destroy();
  }
}
