import 'package:flutter/material.dart';

/// Lebar layar mulai dianggap "lebar" (laptop/desktop/tablet landscape):
/// navigasi pindah ke sidebar dan konten dibatasi lebarnya.
const kWideBreakpoint = 900.0;

/// Lebar maksimum area konten di layar lebar.
const kContentMaxWidth = 960.0;

extension Responsive on BuildContext {
  bool get isWide => MediaQuery.sizeOf(this).width >= kWideBreakpoint;
}

/// Taruh [child] di tengah dengan lebar maksimum [max]; sisi kiri-kanan
/// diisi warna latar tema. Di layar sempit nggak ada bedanya.
class MaxWidth extends StatelessWidget {
  final double max;
  final Widget child;
  const MaxWidth({super.key, this.max = kContentMaxWidth, required this.child});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: max),
          child: child,
        ),
      ),
    );
  }
}
