import 'package:flutter/material.dart';

/// Jembatan antara state teks di provider dan TextEditingController di UI.
///
/// Provider cuma nyimpen `String` + `version` (naik tiap teks diubah dari luar,
/// mis. hasil OCR / handoff). Controller dimiliki widget ini, jadi provider
/// bebas dari objek UI.
class BoundText extends StatefulWidget {
  final Listenable source;
  final String Function() read;
  final int Function() version;
  final ValueChanged<String> onChanged;
  final Widget Function(BuildContext context, TextEditingController controller) builder;

  const BoundText({
    super.key,
    required this.source,
    required this.read,
    required this.version,
    required this.onChanged,
    required this.builder,
  });

  @override
  State<BoundText> createState() => _BoundTextState();
}

class _BoundTextState extends State<BoundText> {
  late final TextEditingController _c;
  late int _seen;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.read());
    _seen = widget.version();
    _c.addListener(_onControllerChanged);
    widget.source.addListener(_sync);
  }

  void _onControllerChanged() => widget.onChanged(_c.text);

  void _sync() {
    final v = widget.version();
    if (v == _seen) return;
    _seen = v;
    final t = widget.read();
    if (_c.text != t) {
      _c.value = TextEditingValue(
        text: t,
        selection: TextSelection.collapsed(offset: t.length),
      );
    }
  }

  @override
  void dispose() {
    widget.source.removeListener(_sync);
    _c.removeListener(_onControllerChanged);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _c);
}
