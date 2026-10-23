import 'dart:async';

enum HandoffTarget { nahwu, quran }

class HandoffMessage {
  final HandoffTarget target;
  final String text;
  const HandoffMessage(this.target, this.text);
}

/// Event bus kecil buat "kirim teks ke fitur lain" tanpa fitur saling kenal.
/// Pengirim: handoff.send(...). Penerima (provider fitur & NavProvider)
/// subscribe ke [stream] dan ambil pesan yang ditujukan ke mereka.
class HandoffService {
  final _controller = StreamController<HandoffMessage>.broadcast();

  Stream<HandoffMessage> get stream => _controller.stream;

  void send(HandoffTarget target, String text) {
    _controller.add(HandoffMessage(target, text));
  }

  void dispose() => _controller.close();
}
