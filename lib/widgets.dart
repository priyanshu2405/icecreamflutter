import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

// ---------------------------------------------------------------------------
// Navigation + feedback helpers
// ---------------------------------------------------------------------------

Future<T?> push<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => page));

void toast(
  BuildContext context,
  String msg, {
  String? action,
  VoidCallback? onAction,
}) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(
    SnackBar(
      content: Text(msg),
      duration: const Duration(milliseconds: 2200),
      action: action == null
          ? null
          : SnackBarAction(
              label: action,
              textColor: C.yellow,
              onPressed: onAction ?? () {},
            ),
    ),
  );
}

Future<T?> showSheet<T>(
  BuildContext context, {
  required String title,
  required Widget child,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: C.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        bottom:
            MediaQuery.of(ctx).viewInsets.bottom +
            MediaQuery.of(ctx).padding.bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: C.line,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(title, style: fred(24)),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Buttons
// ---------------------------------------------------------------------------

enum BtnStyle { pink, dark, outline, blush, white }

class Btn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final BtnStyle style;
  final double height;
  final double fontSize;
  final String? trailing;
  final bool expand;
  final IconData? icon;

  const Btn(
    this.label, {
    super.key,
    this.onTap,
    this.style = BtnStyle.pink,
    this.height = 56,
    this.fontSize = 17,
    this.trailing,
    this.expand = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    switch (style) {
      case BtnStyle.pink:
        bg = C.deep;
        fg = Colors.white;
      case BtnStyle.dark:
        bg = C.ink;
        fg = Colors.white;
      case BtnStyle.outline:
        bg = Colors.white;
        fg = C.ink;
      case BtnStyle.blush:
        bg = C.blush;
        fg = C.ink;
      case BtnStyle.white:
        bg = Colors.white;
        fg = C.deep;
    }
    final shape = StadiumBorder(
      side: style == BtnStyle.outline
          ? const BorderSide(color: C.ink, width: 2)
          : BorderSide.none,
    );
    final text = Text(
      label,
      style: dm(fontSize, color: fg, weight: FontWeight.w700),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    return SizedBox(
      width: expand ? double.infinity : null,
      height: height,
      child: Material(
        color: onTap == null ? bg.withValues(alpha: 0.5) : bg,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: trailing == null
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.spaceBetween,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: fg, size: 20),
                  const SizedBox(width: 8),
                ],
                if (expand) Flexible(child: text) else text,
                if (trailing != null)
                  Text(
                    trailing!,
                    style: dm(fontSize, color: fg, weight: FontWeight.w700),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  final Color iconColor;
  final double size;

  const CircleBtn({
    super.key,
    this.icon = Icons.chevron_left_rounded,
    this.onTap,
    this.color = Colors.white,
    this.iconColor = C.ink,
    this.size = 46,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: CircleBorder(
        side: color == Colors.white
            ? const BorderSide(color: C.line, width: 1.2)
            : BorderSide.none,
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap ?? () => Navigator.of(context).maybePop(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: iconColor, size: size * 0.55),
        ),
      ),
    );
  }
}

/// Back button + big title, used on most inner screens.
class ScreenHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final IconData icon;

  const ScreenHeader(
    this.title, {
    super.key,
    this.subtitle,
    this.trailing,
    this.icon = Icons.chevron_left_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          CircleBtn(icon: icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: fred(26)),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: dm(
                      12,
                      color: C.pink,
                      weight: FontWeight.w700,
                      spacing: 1.2,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chips, cards, tiles
// ---------------------------------------------------------------------------

class PillChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color? dot;
  final double fontSize;
  final EdgeInsets padding;

  const PillChip(
    this.label, {
    super.key,
    this.selected = false,
    this.onTap,
    this.dot,
    this.fontSize = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: padding,
        decoration: BoxDecoration(
          color: selected ? C.ink : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: C.ink, width: 1.6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot != null) ...[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: dot,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? Colors.white : Colors.transparent,
                    width: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: dm(
                fontSize,
                color: selected ? Colors.white : C.ink,
                weight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CardBox extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final Color border;
  final double radius;
  final VoidCallback? onTap;
  final double borderWidth;

  const CardBox({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = Colors.white,
    this.border = C.line,
    this.radius = 20,
    this.onTap,
    this.borderWidth = 1.2,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: border, width: borderWidth),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Placeholder product photo tile (the design leaves food photos as tiles).
class FoodTile extends StatelessWidget {
  final Color color;
  final double size;
  final double? height;
  final double radius;
  final IconData? icon;

  const FoodTile({
    super.key,
    required this.color,
    this.size = 72,
    this.height,
    this.radius = 16,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: height ?? size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: icon == null
          ? null
          : Icon(
              icon,
              size: math.min(size, height ?? size) * 0.4,
              color: C.ink.withValues(alpha: 0.12),
            ),
    );
  }
}

class QtyStepper extends StatelessWidget {
  final int qty;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final bool large;

  const QtyStepper({
    super.key,
    required this.qty,
    required this.onMinus,
    required this.onPlus,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = large ? 46.0 : 30.0;
    Widget b(IconData i, VoidCallback f) => Material(
      color: Colors.white,
      shape: const CircleBorder(side: BorderSide(color: C.line)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: f,
        child: SizedBox(
          width: s,
          height: s,
          child: Icon(i, size: s * 0.5),
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: large ? Colors.white : C.cream,
        borderRadius: BorderRadius.circular(40),
        border: large ? Border.all(color: C.line, width: 1.2) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          b(Icons.remove_rounded, onMinus),
          SizedBox(
            width: large ? 34 : 26,
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: dm(large ? 18 : 16, weight: FontWeight.w700),
            ),
          ),
          b(Icons.add_rounded, onPlus),
        ],
      ),
    );
  }
}

class PinkSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const PinkSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 52,
        height: 30,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? C.deep : const Color(0xFFDCCFD4),
          borderRadius: BorderRadius.circular(20),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class PinkCheck extends StatelessWidget {
  final bool value;
  const PinkCheck(this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: value ? C.deep : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: value ? C.deep : const Color(0xFFBDB2B6),
          width: 1.6,
        ),
      ),
      child: value
          ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
          : null,
    );
  }
}

class RadioDot extends StatelessWidget {
  final bool value;
  const RadioDot(this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 26,
      height: 26,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: value ? C.deep : const Color(0xFFBDB2B6),
          width: 1.8,
        ),
      ),
      child: value
          ? Container(
              decoration: const BoxDecoration(
                color: C.deep,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }
}

/// Small rounded label like "VISA", "LICK", "PAY".
class MiniBadge extends StatelessWidget {
  final String text;
  final Color color;
  const MiniBadge(this.text, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: dm(
          9.5,
          color: Colors.white,
          weight: FontWeight.w700,
          spacing: 0.4,
        ),
      ),
    );
  }
}

class Logo extends StatelessWidget {
  final double size;
  final bool shadow;
  const Logo({super.key, this.size = 120, this.shadow = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: size * 0.12,
                  offset: Offset(0, size * 0.05),
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
      ),
    );
  }
}

/// Full "Lick it" logo (Waffle Buddy + lettering) in white, for pink backgrounds.
class LogoStacked extends StatelessWidget {
  final double width;
  const LogoStacked({super.key, this.width = 200});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo_stacked_white.png',
      width: width,
      fit: BoxFit.contain,
      semanticLabel: 'Lick it Ice Cream & Waffle',
    );
  }
}

class Blob extends StatelessWidget {
  final double size;
  final Color color;
  const Blob(this.size, this.color, {super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class Row2 extends StatelessWidget {
  final String left;
  final String right;
  final TextStyle? style;
  final TextStyle? rightStyle;
  const Row2(this.left, this.right, {super.key, this.style, this.rightStyle});

  @override
  Widget build(BuildContext context) {
    final s = style ?? dm(15, color: C.ink);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(left, style: s)),
          Text(right, style: rightStyle ?? s),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Painters & clippers
// ---------------------------------------------------------------------------

/// Wavy top edge (used for the cream wave on splash and the pink header).
class WaveTopClipper extends CustomClipper<Path> {
  final double amp;
  const WaveTopClipper({this.amp = 40});

  @override
  Path getClip(Size s) {
    final p = Path()..moveTo(0, amp * 0.8);
    p.cubicTo(
      s.width * 0.25,
      -amp * 0.2,
      s.width * 0.45,
      amp * 1.6,
      s.width * 0.7,
      amp * 0.9,
    );
    p.cubicTo(
      s.width * 0.85,
      amp * 0.5,
      s.width * 0.95,
      amp * 0.1,
      s.width,
      amp * 0.3,
    );
    p.lineTo(s.width, s.height);
    p.lineTo(0, s.height);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Wavy bottom edge.
class WaveBottomClipper extends CustomClipper<Path> {
  final double amp;
  const WaveBottomClipper({this.amp = 36});

  @override
  Path getClip(Size s) {
    final h = s.height;
    final p = Path()..lineTo(0, h - amp * 0.4);
    p.cubicTo(
      s.width * 0.3,
      h - amp * 1.6,
      s.width * 0.6,
      h + amp * 0.4,
      s.width,
      h - amp,
    );
    p.lineTo(s.width, 0);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;
  const DashedBorderPainter({
    this.color = C.pink,
    this.radius = 20,
    this.strokeWidth = 1.6,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 7), paint);
        d += 12;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter old) => old.color != color;
}

class Dashed extends StatelessWidget {
  final Widget child;
  final Color color;
  final double radius;
  final Color fill;
  final VoidCallback? onTap;
  const Dashed({
    super.key,
    required this.child,
    this.color = C.pink,
    this.radius = 20,
    this.fill = Colors.transparent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: DashedBorderPainter(color: color, radius: radius),
        child: Container(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: child,
        ),
      ),
    );
  }
}

class BarcodePainter extends CustomPainter {
  const BarcodePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(2047);
    final paint = Paint()..color = C.ink;
    var x = 0.0;
    var bar = true;
    while (x < size.width) {
      final w = (rnd.nextInt(3) + 1) * 1.6;
      if (bar) canvas.drawRect(Rect.fromLTWH(x, 0, w, size.height), paint);
      x += w;
      bar = !bar;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Barcode extends StatelessWidget {
  final String number;
  final double height;
  const Barcode({super.key, this.number = 'LI 2047 0142 88', this.height = 64});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          SizedBox(
            height: height,
            width: double.infinity,
            child: const CustomPaint(painter: BarcodePainter()),
          ),
          const SizedBox(height: 6),
          Text(number, style: dm(13, weight: FontWeight.w700, spacing: 3)),
        ],
      ),
    );
  }
}

/// Simple illustrated street map used on Stores and Delivery tracking.
class MapPainter extends CustomPainter {
  final List<Offset>? route; // fractional coordinates
  const MapPainter({this.route});

  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawRect(Offset.zero & s, Paint()..color = C.map);
    final park = Paint()..color = C.park;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          s.width * 0.08,
          s.height * 0.55,
          s.width * 0.3,
          s.height * 0.18,
        ),
        const Radius.circular(14),
      ),
      park,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          s.width * 0.62,
          s.height * 0.05,
          s.width * 0.28,
          s.height * 0.2,
        ),
        const Radius.circular(14),
      ),
      park,
    );
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(
      Offset(s.width * 0.62, -20),
      Offset(s.width * 0.5, s.height + 20),
      road,
    );
    canvas.drawLine(
      Offset(-20, s.height * 0.3),
      Offset(s.width + 20, s.height * 0.48),
      road,
    );
    road.strokeWidth = 12;
    canvas.drawLine(
      Offset(-20, s.height * 0.82),
      Offset(s.width + 20, s.height * 0.78),
      road,
    );
    canvas.drawLine(
      Offset(s.width * 0.2, -20),
      Offset(s.width * 0.26, s.height + 20),
      road,
    );
    canvas.drawLine(
      Offset(s.width * 0.9, s.height * 0.3),
      Offset(s.width * 0.82, s.height + 20),
      road,
    );

    final r = route;
    if (r != null && r.length > 1) {
      final dot = Paint()..color = C.pink;
      final pts = r
          .map((o) => Offset(o.dx * s.width, o.dy * s.height))
          .toList();
      for (var i = 0; i < pts.length - 1; i++) {
        final a = pts[i];
        final b = pts[i + 1];
        final len = (b - a).distance;
        final n = (len / 14).floor();
        for (var k = 0; k <= n; k++) {
          canvas.drawCircle(Offset.lerp(a, b, k / math.max(n, 1))!, 3.2, dot);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant MapPainter oldDelegate) => false;
}

/// Point along a polyline (fractional coordinates), t in 0..1.
Offset alongPolyline(List<Offset> pts, double t) {
  var total = 0.0;
  for (var i = 0; i < pts.length - 1; i++) {
    total += (pts[i + 1] - pts[i]).distance;
  }
  var target = total * t.clamp(0.0, 1.0);
  for (var i = 0; i < pts.length - 1; i++) {
    final seg = (pts[i + 1] - pts[i]).distance;
    if (target <= seg) return Offset.lerp(pts[i], pts[i + 1], target / seg)!;
    target -= seg;
  }
  return pts.last;
}

class MapPin extends StatelessWidget {
  final Color color;
  final double size;
  const MapPin({super.key, this.color = C.pink, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: math.pi / 4,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.white, width: 3),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(size),
            topRight: Radius.circular(size),
            bottomLeft: Radius.circular(size),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
      ),
    );
  }
}
