import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'data.dart';

// ---------------------------------------------------------------------------
// Plate preview: draws the customer's treat from what they've picked so far
// (scoops in their flavour colours, every topping, the waffle base colour).
// The website draws the same picture in public/site/js/plate.js; keep the two
// in step. Newly added items pop / drop in; the rest stays still.
// ---------------------------------------------------------------------------

enum PlateVessel { waffle, cup, cone, bingsu, shake, pancakes }

PlateVessel vesselFor(MenuItem item) {
  final c = item.category.toLowerCase();
  final n = item.name.toLowerCase();
  if (item.isShake || c.contains('shake') || c.contains('coffee') || c.contains('matcha')) {
    return PlateVessel.shake;
  }
  if (c.contains('bingsu')) return PlateVessel.bingsu;
  if (c.contains('pancake')) return PlateVessel.pancakes;
  if (c.contains('waffle') || c.contains('build')) return PlateVessel.waffle;
  if (n.contains('cone')) return PlateVessel.cone;
  return PlateVessel.cup;
}

class PlatePreview extends StatefulWidget {
  final MenuItem item;
  final List<String> scoops;
  final List<String> toppings;
  final double size;

  /// Build-your-own only: waffle base ('Classic Belgian', 'Red Velvet',
  /// 'Chocolate') and drizzle (name + colour). Null = work it out from [item].
  final String? base;
  final Flavour? drizzle;

  /// Draw the item's own scoop(s) for cups / cones (off once flavours are picked).
  final bool houseScoops;

  const PlatePreview({
    super.key,
    required this.item,
    required this.scoops,
    required this.toppings,
    required this.size,
    this.base,
    this.drizzle,
    this.houseScoops = true,
  });

  @override
  State<PlatePreview> createState() => _PlatePreviewState();
}

class _PlatePreviewState extends State<PlatePreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
    value: 1,
  );
  Set<String> _keys = {};
  Set<String> _fresh = {};

  Set<String> _keysFor(PlatePreview w) => {
    if (w.base != null) 'base:${w.base}',
    if (w.drizzle != null) 'drizzle:${w.drizzle!.name}',
    for (final s in w.scoops) 'scoop:$s',
    for (final t in w.toppings) 'top:$t',
  };

  @override
  void initState() {
    super.initState();
    _keys = _keysFor(widget);
  }

  @override
  void didUpdateWidget(covariant PlatePreview old) {
    super.didUpdateWidget(old);
    final now = _keysFor(widget);
    final added = now.difference(_keys);
    _keys = now;
    if (added.isNotEmpty) {
      _fresh = added;
      if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
        _anim.value = 1;
      } else {
        _anim.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colours = {for (final f in scoopFlavours) f.name: f.dot};
    final label = [
      widget.item.name,
      if (widget.base != null) '${widget.base} base',
      if (widget.scoops.isNotEmpty) 'with ${widget.scoops.join(', ')}',
      if (widget.drizzle != null) '${widget.drizzle!.name} drizzle',
      if (widget.toppings.isNotEmpty) 'topped with ${widget.toppings.join(', ')}',
    ].join(', ');
    return Semantics(
      label: 'Preview: $label',
      image: true,
      child: SizedBox.square(
        dimension: widget.size,
        child: CustomPaint(
          painter: _PlatePainter(
            item: widget.item,
            scoops: [
              for (final s in widget.scoops)
                _Scoop(s, colours[s] ?? const Color(0xFFF25C9A)),
            ],
            toppings: List.of(widget.toppings),
            base: widget.base,
            drizzle: widget.drizzle,
            houseScoops: widget.houseScoops,
            fresh: _fresh,
            anim: _anim,
          ),
        ),
      ),
    );
  }
}

class _Scoop {
  final String name;
  final Color color;
  final bool house;
  const _Scoop(this.name, this.color, {this.house = false});
}

// --------------------------------------------------------------------------- painter

class _PlatePainter extends CustomPainter {
  final MenuItem item;
  final List<_Scoop> scoops;
  final List<String> toppings;
  final String? base;
  final Flavour? drizzle;
  final bool houseScoops;
  final Set<String> fresh;
  final Animation<double> anim;

  _PlatePainter({
    required this.item,
    required this.scoops,
    required this.toppings,
    this.base,
    this.drizzle,
    this.houseScoops = true,
    required this.fresh,
    required this.anim,
  }) : super(repaint: anim);

  double get _t => anim.value;

  @override
  bool shouldRepaint(covariant _PlatePainter o) =>
      o.item.id != item.id ||
      o.scoops.map((s) => s.name).join('|') != scoops.map((s) => s.name).join('|') ||
      o.toppings.join('|') != toppings.join('|') ||
      o.base != base ||
      o.houseScoops != houseScoops ||
      o.drizzle?.name != drizzle?.name ||
      o.fresh != fresh;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 200, size.height / 200); // work in a 200×200 box
    final v = vesselFor(item);
    switch (v) {
      case PlateVessel.waffle:
        _animated(canvas, 'base:$base', const Offset(100, 112), pop: true, squish: true, () => _waffle(canvas));
        if (drizzle != null) {
          _animated(canvas, 'drizzle:${drizzle!.name}', const Offset(100, 112), pop: false, fade: true, () => _drizzle(canvas, drizzle!.dot));
        }
      case PlateVessel.cup:
        _cupBack(canvas);
      case PlateVessel.cone:
        _cone(canvas);
      case PlateVessel.bingsu:
        _bingsu(canvas);
      case PlateVessel.shake:
        _shake(canvas);
      case PlateVessel.pancakes:
        _pancakes(canvas);
    }

    // Scoops: the item's own scoop(s) for cups / cones, then the extras picked.
    final all = <_Scoop>[if (houseScoops) ..._houseScoops(v), ...scoops];
    final shown = all.length > 3 ? all.sublist(all.length - 3) : all;
    final slots = _slots(v, shown.length);
    final order = List<int>.generate(shown.length, (i) => i);
    if (v != PlateVessel.cone) order.sort((a, b) => slots[a].dy.compareTo(slots[b].dy));
    for (final i in order) {
      final s = shown[i];
      final p = slots[i];
      _animated(canvas, 'scoop:${s.name}', Offset(p.dx, p.dy), pop: true, () {
        _scoop(canvas, p.dx, p.dy, p.r, s);
      });
    }
    if (v == PlateVessel.cup) _cupFront(canvas);

    // Toppings sit on top of everything.
    for (final t in toppings) {
      final r = _region(v);
      _animated(canvas, 'top:$t', r.center, pop: false, () => _topping(canvas, t, v));
    }

    if (v == PlateVessel.waffle && shown.isNotEmpty) {
      final top = slots[order.first];
      canvas.save();
      canvas.translate(top.dx, top.dy - top.r - 6);
      canvas.scale(0.9);
      canvas.drawPath(_svg(_heart), _fill(const Color(0xFFC2185B)));
      canvas.restore();
    }
    canvas.restore();
  }

  /// Runs [draw]; if [key] was just added, scales it up (pop) or drops it in.
  void _animated(
    Canvas canvas,
    String key,
    Offset c,
    VoidCallback draw, {
    required bool pop,
    bool squish = false,
    bool fade = false,
  }) {
    if (!fresh.contains(key) || _t >= 1) {
      draw();
      return;
    }
    final t = _t.clamp(0.0, 1.0);
    if (squish) {
      // base swap: a small bounce instead of fading the whole waffle out
      final s = 0.92 + 0.08 * Curves.easeOutBack.transform(t);
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.scale(s);
      canvas.translate(-c.dx, -c.dy);
      draw();
      canvas.restore();
      return;
    }
    canvas.saveLayer(null, Paint()..color = Colors.black.withValues(alpha: math.min(1.0, t * 1.6)));
    if (fade) {
      // opacity only
    } else if (pop) {
      final s = Curves.easeOutBack.transform(t);
      canvas.translate(c.dx, c.dy);
      canvas.scale(s);
      canvas.translate(-c.dx, -c.dy);
    } else {
      canvas.translate(0, -18 * (1 - Curves.easeOutCubic.transform(t)));
    }
    draw();
    canvas.restore();
  }

  // ----------------------------------------------------------------- vessels

  void _shadow(Canvas canvas, double cx, double cy, double rx, double ry, double o) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2),
      _fill(Colors.black.withValues(alpha: o)),
    );
  }

  void _waffle(Canvas canvas) {
    final id = '${item.id} ${item.name}'.toLowerCase();
    var body = const Color(0xFFC9852F), edge = const Color(0xFF9A5F1C);
    final admin = byoBaseNamed(base);
    final b = base?.toLowerCase();
    if (admin != null && b != 'classic belgian') {
      // a base from Admin > Build your own: its own colour, a darker edge
      body = admin.color;
      edge = Color.lerp(admin.color, Colors.black, .3)!;
    } else if (b == 'red velvet' || (b == null && (id.contains('red velvet') || id.contains('red-velvet') || id.contains('redvelvet')))) {
      body = const Color(0xFFB3263E);
      edge = const Color(0xFF7A1426);
    } else if (b == 'chocolate' || (b == null && (id.contains('chocolate base') || id.contains('build-your-own-chocolate')))) {
      body = const Color(0xFF6B3B26);
      edge = const Color(0xFF3E2117);
    }
    _shadow(canvas, 100, 176, 74, 9, .08);
    canvas.drawCircle(const Offset(100, 112), 70, _fill(body));
    canvas.drawCircle(const Offset(100, 112), 70, _stroke(edge, 5));
    final sq = _fill(edge.withValues(alpha: .55));
    for (final x in [59.0, 80.0, 101.0, 122.0, 143.0]) {
      for (final y in [70.0, 91.0, 112.0, 133.0, 154.0]) {
        final d = Offset(x + 6.5 - 100, y + 6.5 - 112).distance;
        if (d < 58) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTWH(x, y, 13, 13), const Radius.circular(3)),
            sq,
          );
        }
      }
    }
  }

  void _drizzle(Canvas canvas, Color c) {
    canvas.drawPath(_svg('M44 92c14-10 22 8 36-2s20 10 34 0 22 8 40-4'), _stroke(c, 7));
    canvas.drawPath(_svg('M50 130c16-8 22 6 38-2s22 8 38-2 18 4 26 0'), _stroke(c, 5));
    canvas.drawPath(_svg('M60 152c12-6 18 4 30-1s18 5 30-1 12 3 18 0'), _stroke(c.withValues(alpha: .9), 4));
  }

  void _cupBack(Canvas canvas) {
    _shadow(canvas, 100, 182, 60, 7, .08);
  }

  void _cupFront(Canvas canvas) {
    final body = _svg('M42 112L158 112 146 174Q145 180 139 180L61 180Q55 180 54 174Z');
    canvas.drawPath(body, _fill(Colors.white));
    canvas.save();
    canvas.clipPath(body);
    final stripe = _fill(const Color(0xFFFDE6EF));
    for (var x = 30.0; x < 180; x += 22) {
      canvas.drawPath(_svg('M$x 112l10 0-8 70-10 0z'), stripe);
    }
    canvas.restore();
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(36, 104, 128, 13), const Radius.circular(6.5)),
      _fill(const Color(0xFFC2185B)),
    );
  }

  void _cone(Canvas canvas) {
    _shadow(canvas, 100, 188, 26, 4, .1);
    final cone = _svg('M66 104L134 104 103 186Q100 191 97 186Z');
    canvas.drawPath(cone, _fill(const Color(0xFFD9A05B)));
    canvas.save();
    canvas.clipPath(cone);
    final line = _stroke(const Color(0xFFB57A35), 2);
    for (var k = -40.0; k < 120; k += 13) {
      canvas.drawLine(Offset(60 + k, 104), Offset(100 + k, 190), line);
      canvas.drawLine(Offset(140 - k, 104), Offset(100 - k, 190), line);
    }
    canvas.restore();
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(62, 100, 76, 10), const Radius.circular(5)),
      _fill(const Color(0xFFC98C45)),
    );
  }

  void _bingsu(Canvas canvas) {
    _shadow(canvas, 100, 182, 66, 7, .08);
    final snow = Color.lerp(item.tile, Colors.white, .45)!;
    canvas.drawPath(_svg('M40 128Q44 54 100 50 156 54 160 128Z'), _fill(snow));
    final speck = _fill(Color.lerp(item.tile, Colors.black, .12)!.withValues(alpha: .5));
    final r = math.Random(item.id.hashCode);
    for (var i = 0; i < 18; i++) {
      canvas.drawCircle(Offset(56 + r.nextDouble() * 88, 70 + r.nextDouble() * 54), 1.2, speck);
    }
    canvas.drawPath(_svg('M26 124L174 124Q170 178 100 182 30 178 26 124Z'), _fill(Colors.white));
    canvas.drawPath(_svg('M26 124L174 124Q170 178 100 182 30 178 26 124Z'), _stroke(const Color(0xFFF1D3DF), 3));
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(30, 132, 140, 6), const Radius.circular(3)),
      _fill(const Color(0xFFFDE6EF)),
    );
  }

  void _shake(Canvas canvas) {
    _shadow(canvas, 100, 190, 34, 5, .1);
    final drink = Color.lerp(item.tile, Colors.black, .1)!;
    final glass = _svg('M56 74L144 74 133 182Q132 188 126 188L74 188Q68 188 67 182Z');
    canvas.drawPath(glass, _fill(drink));
    canvas.drawPath(_svg('M66 84L74 84 80 178 74 178Z'), _fill(Colors.white.withValues(alpha: .35)));
    // straw
    canvas.save();
    canvas.translate(118, 50);
    canvas.rotate(.32);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-4, -34, 8, 60), const Radius.circular(4)),
      _fill(const Color(0xFFFFD54A)),
    );
    canvas.restore();
    // whipped cream
    final cream = _fill(const Color(0xFFFFFBF5));
    for (final c in const [Offset(70, 72), Offset(88, 64), Offset(108, 62), Offset(128, 70), Offset(98, 50)]) {
      canvas.drawCircle(c, 17, cream);
    }
    canvas.drawCircle(const Offset(98, 34), 5, _fill(const Color(0xFFB0164F)));
  }

  void _pancakes(Canvas canvas) {
    _shadow(canvas, 100, 160, 80, 12, .08);
    canvas.drawOval(Rect.fromCenter(center: const Offset(100, 132), width: 176, height: 70), _fill(Colors.white));
    canvas.drawOval(Rect.fromCenter(center: const Offset(100, 132), width: 150, height: 54), _stroke(const Color(0xFFF1D3DF), 2));
    final r = math.Random(7);
    for (var i = 0; i < 9; i++) {
      final c = Offset(52 + (i % 5) * 24 + r.nextDouble() * 6, 118 + (i ~/ 5) * 20 + r.nextDouble() * 6);
      canvas.drawOval(Rect.fromCenter(center: c, width: 26, height: 18), _fill(const Color(0xFFC9852F)));
      canvas.drawOval(Rect.fromCenter(center: c.translate(0, -2), width: 20, height: 12), _fill(const Color(0xFFE2A85A)));
    }
  }

  // ----------------------------------------------------------------- scoops

  List<_Scoop> _houseScoops(PlateVessel v) {
    if (v != PlateVessel.cup && v != PlateVessel.cone) return const [];
    final n = item.name.toLowerCase();
    Color c = Color.lerp(item.tile, Colors.black, .04)!;
    for (final e in const {
      'vanilla': Color(0xFFF3E3C3),
      'strawberr': Color(0xFFF7B3CC),
      'mango': Color(0xFFFFB300),
      'matcha': Color(0xFF8DB860),
      'pista': Color(0xFF9CCC65),
      'dubai': Color(0xFF6B3B26),
      'chocolate': Color(0xFF6B3B26),
    }.entries) {
      if (n.contains(e.key)) {
        c = e.value;
        break;
      }
    }
    final count = n.contains('double') ? 2 : 1;
    return [for (var i = 0; i < count; i++) _Scoop('house$i', c, house: true)];
  }

  List<_Slot> _slots(PlateVessel v, int n) {
    if (n == 0) return const [];
    switch (v) {
      case PlateVessel.waffle:
        return const [
          [_Slot(100, 76, 30)],
          [_Slot(79, 80, 26), _Slot(123, 76, 26)],
          [_Slot(100, 58, 24), _Slot(74, 88, 25), _Slot(126, 88, 25)],
        ][n - 1];
      case PlateVessel.cone:
        return const [
          [_Slot(100, 82, 30)],
          [_Slot(100, 88, 29), _Slot(100, 56, 27)],
          [_Slot(100, 90, 28), _Slot(100, 62, 26), _Slot(100, 36, 23)],
        ][n - 1];
      case PlateVessel.bingsu:
        return const [
          [_Slot(100, 64, 24)],
          [_Slot(82, 70, 22), _Slot(120, 66, 22)],
          [_Slot(100, 52, 21), _Slot(78, 76, 22), _Slot(124, 76, 22)],
        ][n - 1];
      case PlateVessel.cup:
      case PlateVessel.shake:
      case PlateVessel.pancakes:
        final dy = v == PlateVessel.shake ? -20.0 : (v == PlateVessel.pancakes ? 28.0 : 0.0);
        return [
          [_Slot(100, 78 + dy, 32)],
          [_Slot(80, 80 + dy, 28), _Slot(122, 76 + dy, 28)],
          [_Slot(100, 56 + dy, 26), _Slot(76, 84 + dy, 27), _Slot(124, 84 + dy, 27)],
        ][n - 1];
    }
  }

  void _scoop(Canvas canvas, double cx, double cy, double r, _Scoop s) {
    final k = r / 30;
    final drip = Color.lerp(s.color, Colors.black, .16)!;
    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(k);
    _shadow(canvas, 0, 27, 27, 6, .14);
    canvas.drawCircle(Offset.zero, 30, _fill(s.color));
    final d = _svg('M-28 4c6 10 14 2 18 12s14-6 18 4 12-2 18-8');
    canvas.drawPath(d, _fill(drip));
    canvas.drawPath(d, _stroke(drip, 6)..strokeJoin = StrokeJoin.round);
    if (!s.house) _scoopDetails(canvas, s);
    canvas.drawCircle(const Offset(-10, -12), 7, _fill(Colors.white.withValues(alpha: .45)));
    canvas.restore();
  }

  void _rotRect(Canvas canvas, double x, double y, double w, double h, double rx, double deg, Paint p) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(deg * math.pi / 180);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), Radius.circular(rx)), p);
    canvas.restore();
  }

  void _scoopDetails(Canvas canvas, _Scoop s) {
    final n = s.name.toLowerCase();
    final dark = s.color.computeLuminance() < 0.12;
    bool has(String re) => RegExp(re).hasMatch(n);

    if (has(r'chip|cookie dough|moose|brownie')) {
      final p = _fill(dark ? const Color(0xFFF3E9DC) : const Color(0xFF3E2117));
      const pts = [[-15, -10], [5, -18], [13, 0], [-5, 4], [-19, 6], [18, -12], [0, -6]];
      for (var i = 0; i < pts.length; i++) {
        _rotRect(canvas, pts[i][0].toDouble(), pts[i][1].toDouble(), i.isOdd ? 5.0 : 6.0, 4.5, 1.4, (i * 37 % 60 - 30).toDouble(), p);
      }
    }
    if (has(r'cookies|oreo|cookie crunch')) {
      final p = _fill(const Color(0xFF2B1D1A));
      const pts = [[-14, -12], [8, -16], [14, 2], [-6, 2], [-18, 4], [2, -4], [18, -8], [-8, -20]];
      for (var i = 0; i < pts.length; i++) {
        canvas.drawCircle(Offset(pts[i][0].toDouble(), pts[i][1].toDouble()), i % 3 == 0 ? 2.8 : 2, p);
      }
    }
    if (has(r'ripple|swirl|fudge|tiger|moose|raspberry|cheesecake')) {
      final Color rc;
      if (has(r'raspberry|cherry')) {
        rc = const Color(0xFFB0164F);
      } else if (has(r'butterscotch|caramel')) {
        rc = const Color(0xFFA0621F);
      } else if (has(r'fudge|moose')) {
        rc = const Color(0xFF3E2117);
      } else if (has(r'tiger')) {
        rc = const Color(0xFF1E1418);
      } else if (has(r'blueberry')) {
        rc = const Color(0xFF4B3A9C);
      } else if (has(r'strawberry')) {
        rc = const Color(0xFFD81B60);
      } else {
        rc = Color.lerp(s.color, Colors.black, .35)!;
      }
      canvas.drawPath(_svg('M-22 -4c8-9 14 5 22-3s12-9 21 -1'), _stroke(rc, 3.6));
      canvas.drawPath(_svg('M-16 8c6-5 10 3 16-1s9-5 15 0'), _stroke(rc.withValues(alpha: .85), 3));
    }
    if (has(r'walnut|pecan|praline|hazelnut|rocky|almond|toffee|peanut')) {
      const pts = [[-13, -14], [10, -10], [-4, 6], [16, 4], [-20, -2]];
      for (var i = 0; i < pts.length; i++) {
        canvas.save();
        canvas.translate(pts[i][0].toDouble(), pts[i][1].toDouble());
        canvas.rotate(i * 50 * math.pi / 180);
        final o = Rect.fromCenter(center: Offset.zero, width: 7.2, height: 4.8);
        canvas.drawOval(o, _fill(const Color(0xFFD9A066)));
        canvas.drawOval(o, _stroke(const Color(0xFFA86F3A), 1));
        canvas.restore();
      }
    }
    if (has(r'rocky')) {
      for (final p in const [[-8, -18], [12, -2], [-16, 8]]) {
        _rotRect(canvas, p[0].toDouble(), p[1].toDouble(), 6, 6, 2, 0, _fill(Colors.white.withValues(alpha: .95)));
      }
    }
    if (has(r'birthday|confetti|funfetti')) {
      const cs = [Color(0xFFE8287A), Color(0xFF6EC6F2), Color(0xFF9CCC65), Color(0xFFB388FF), Color(0xFFFF8A3D)];
      const pts = [[-15, -12], [6, -18], [14, 0], [-4, 2], [-19, 6], [18, -12], [0, -8], [-10, -22]];
      for (var i = 0; i < pts.length; i++) {
        _rotRect(canvas, pts[i][0].toDouble(), pts[i][1].toDouble(), 6, 2.4, 1.2, (i * 47).toDouble(), _fill(cs[i % cs.length]));
      }
    }
  }

  // ----------------------------------------------------------------- toppings

  ({Offset center, double rMin, double rMax, double squash}) _region(PlateVessel v) {
    switch (v) {
      case PlateVessel.waffle:
        return (center: const Offset(100, 114), rMin: 16.0, rMax: 62.0, squash: .9);
      case PlateVessel.cup:
        return (center: const Offset(100, 74), rMin: 0.0, rMax: 38.0, squash: .7);
      case PlateVessel.cone:
        return (center: const Offset(100, 72), rMin: 0.0, rMax: 28.0, squash: .8);
      case PlateVessel.bingsu:
        return (center: const Offset(100, 92), rMin: 6.0, rMax: 50.0, squash: .55);
      case PlateVessel.shake:
        return (center: const Offset(98, 60), rMin: 0.0, rMax: 34.0, squash: .5);
      case PlateVessel.pancakes:
        return (center: const Offset(100, 128), rMin: 6.0, rMax: 62.0, squash: .4);
    }
  }

  static String _kind(String t) {
    final n = t.toLowerCase();
    bool has(String re) => RegExp(re).hasMatch(n);
    if (has(r'drizzle|sauce|syrup')) return 'drizzle';
    if (has(r'oreo')) return 'oreo';
    if (has(r'brownie')) return 'brownie';
    if (has(r'strawberr')) return 'strawberry';
    if (has(r'kit ?kat|wafer')) return 'kitkat';
    if (has(r'sprinkle')) return 'sprinkles';
    if (has(r'banana')) return 'banana';
    if (has(r'almond|nut|pistachio|pecan')) return 'almond';
    if (has(r'kunafa|kataifi')) return 'kunafa';
    if (has(r'biscoff|lotus|crumble|graham')) return 'crumble';
    if (has(r'marshmallow')) return 'marshmallow';
    if (has(r'blueberr|berry')) return 'berry';
    return 'dots';
  }

  static Color _drizzleColour(String t) {
    final n = t.toLowerCase();
    if (n.contains('white')) return const Color(0xFFF3E9DC);
    if (RegExp(r'caramel|biscoff|lotus').hasMatch(n)) return const Color(0xFFD8902F);
    if (RegExp(r'strawberr|raspberr').hasMatch(n)) return const Color(0xFFE53950);
    if (n.contains('pistachio')) return const Color(0xFF9CCC65);
    return const Color(0xFF5A2E1E);
  }

  static const _counts = {
    'oreo': 9, 'brownie': 5, 'strawberry': 4, 'kitkat': 3, 'sprinkles': 18, 'banana': 4,
    'almond': 6, 'kunafa': 10, 'crumble': 9, 'marshmallow': 6, 'berry': 6, 'dots': 7,
  };
  static const _sprinkles = [
    Color(0xFFFFD54A), Color(0xFF6EC6F2), Color(0xFFFFFFFF), Color(0xFFE8287A), Color(0xFF9CCC65), Color(0xFFB388FF),
  ];
  static const _dots = [
    Color(0xFFE8287A), Color(0xFFFFB300), Color(0xFF6EC6F2), Color(0xFF9CCC65), Color(0xFFB388FF), Color(0xFFFF8A3D),
  ];

  /// Stable per-name seed so a topping lands in the same spots every time.
  static int _seed(String s) {
    var h = 0x811c9dc5;
    for (final c in s.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
    return h;
  }

  void _topping(Canvas canvas, String t, PlateVessel v) {
    final kind = _kind(t);
    if (kind == 'drizzle') {
      final p = _stroke(_drizzleColour(t), 4.5);
      if (v == PlateVessel.waffle) {
        canvas.drawPath(_svg('M58 66c12 9 20-6 32 2s18-7 30 2 14-5 24 1'), p);
        canvas.drawPath(_svg('M64 100c10 6 16-4 26 1s14-5 26 1'), p..strokeWidth = 3.5);
      } else {
        final c = _region(v).center;
        canvas.save();
        canvas.translate(c.dx - 100, c.dy - 70);
        canvas.drawPath(_svg('M64 66c10 8 18-6 28 2s16-7 26 2 10-4 18 0'), p);
        canvas.restore();
      }
      return;
    }
    final r = _region(v);
    final rnd = math.Random(_seed(t));
    final dot = _dots[_seed(t) % _dots.length];
    for (var i = 0; i < (_counts[kind] ?? 7); i++) {
      final a = rnd.nextDouble() * math.pi * 2;
      final rad = r.rMin + rnd.nextDouble() * (r.rMax - r.rMin);
      final x = r.center.dx + math.cos(a) * rad;
      final y = r.center.dy + math.sin(a) * rad * r.squash;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rnd.nextDouble() * math.pi * 2);
      _piece(canvas, kind, rnd, dot);
      canvas.restore();
    }
  }

  void _piece(Canvas canvas, String kind, math.Random rnd, Color dot) {
    switch (kind) {
      case 'oreo':
        canvas.drawCircle(Offset.zero, 3.8, _fill(const Color(0xFF2B1D1A)));
        canvas.drawCircle(const Offset(1.1, -1), 1, _fill(const Color(0xFFEDE6DA)));
      case 'brownie':
        _rotRect(canvas, -5, -4.5, 10, 9, 2, 0, _fill(const Color(0xFF4A2618)));
        _rotRect(canvas, -3, -3, 4, 2, 1, 0, _fill(const Color(0xFF6B3B26)));
      case 'strawberry':
        canvas.drawPath(_svg('M0 7C-7 3-8-4-4-6-2-7 0-6 0-5 0-6 2-7 4-6 8-4 7 3 0 7z'), _fill(const Color(0xFFE53950)));
        canvas.drawPath(_svg('M0 5C-4 2-5-3-2-4 0-4.5 0-3 0-3 0-3 0-4.5 2-4 5-3 4 2 0 5z'), _fill(const Color(0x99FF8A9A)));
        for (final s in const [Offset(-2, -1), Offset(2, 0), Offset(0, 2.5)]) {
          canvas.drawCircle(s, .7, _fill(const Color(0xFFFFE0A3)));
        }
      case 'kitkat':
        _rotRect(canvas, -3.6, -9, 7.2, 18, 1.6, 0, _fill(const Color(0xFF8B4A2B)));
        canvas.drawLine(const Offset(-3.6, 0), const Offset(3.6, 0), _stroke(const Color(0xFF5E2E19), 1.2));
        _rotRect(canvas, -2.4, -7.6, 1.6, 6, .8, 0, _fill(const Color(0xFFA8613D)));
      case 'sprinkles':
        _rotRect(canvas, -4.5, -1.6, 9, 3.2, 1.6, 0, _fill(_sprinkles[rnd.nextInt(_sprinkles.length)]));
      case 'banana':
        canvas.drawCircle(Offset.zero, 5.6, _fill(const Color(0xFFFFF1B8)));
        canvas.drawCircle(Offset.zero, 5.6, _stroke(const Color(0xFFE9C85A), 1.4));
        canvas.drawCircle(Offset.zero, 1.7, _fill(const Color(0xB3E9C85A)));
      case 'almond':
        final o = Rect.fromCenter(center: Offset.zero, width: 5.8, height: 10);
        canvas.drawOval(o, _fill(const Color(0xFFD9A066)));
        canvas.drawOval(o, _stroke(const Color(0xFFA86F3A), 1));
      case 'kunafa':
        canvas.drawPath(_svg('M-7 0c2-3 4 3 7 0s4 3 7 0'), _stroke(const Color(0xFFE8A33D), 1.9));
      case 'crumble':
        final p = _svg('M-3-3 3-4 4.2 2-1 4.2-4.2 1z');
        canvas.drawPath(p, _fill(const Color(0xFFB5732F)));
        canvas.drawPath(p, _stroke(const Color(0xFF8E5520), .8));
      case 'marshmallow':
        _rotRect(canvas, -3.5, -3.5, 7, 7, 2.2, 0, _fill(Colors.white));
      case 'berry':
        canvas.drawCircle(Offset.zero, 3.6, _fill(const Color(0xFF4B3A9C)));
        canvas.drawCircle(const Offset(-1, -1), 1, _fill(const Color(0xFF8C7DE0)));
      default:
        canvas.drawCircle(Offset.zero, 3.2, _fill(dot));
    }
  }

  // ----------------------------------------------------------------- helpers

  static const _heart = 'M0-6c0-8 10-8 10 0 0 6-10 12-10 12s-10-6-10-12c0-8 10-8 10 0z';

  static Paint _fill(Color c) => Paint()..color = c;
  static Paint _stroke(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round;

  static final Map<String, Path> _pathCache = {};
  static Path _svg(String d) => _pathCache.putIfAbsent(d, () => parseSvgPath(d));
}

class _Slot {
  final double dx, dy, r;
  const _Slot(this.dx, this.dy, this.r);
}

/// Minimal SVG path-data parser (M L H V C S Q Z, absolute and relative) so the
/// app can share the exact shapes used by the website preview.
Path parseSvgPath(String d) {
  final path = Path();
  final toks = RegExp(r'[MmLlHhVvCcSsQqZz]|-?\d*\.?\d+(?:[eE][-+]?\d+)?')
      .allMatches(d)
      .map((m) => m.group(0)!)
      .toList();
  bool isCmd(String t) => RegExp(r'^[A-Za-z]$').hasMatch(t);
  var i = 0;
  var cmd = 'M';
  double cx = 0, cy = 0, sx = 0, sy = 0;
  double? lx, ly; // last cubic control point, for S
  double n() => double.parse(toks[i++]);

  while (i < toks.length) {
    if (isCmd(toks[i])) {
      cmd = toks[i++];
    } else if (cmd == 'M') {
      cmd = 'L';
    } else if (cmd == 'm') {
      cmd = 'l';
    } else if (cmd == 'Z' || cmd == 'z') {
      i++; // stray number after Z: skip it
      continue;
    }
    final rel = cmd == cmd.toLowerCase();
    final ox = rel ? cx : 0.0, oy = rel ? cy : 0.0;
    switch (cmd.toUpperCase()) {
      case 'M':
        cx = n() + ox;
        cy = n() + oy;
        path.moveTo(cx, cy);
        sx = cx;
        sy = cy;
        lx = null;
      case 'L':
        cx = n() + ox;
        cy = n() + oy;
        path.lineTo(cx, cy);
        lx = null;
      case 'H':
        cx = n() + ox;
        path.lineTo(cx, cy);
        lx = null;
      case 'V':
        cy = n() + oy;
        path.lineTo(cx, cy);
        lx = null;
      case 'C':
        {
          final x1 = n() + ox, y1 = n() + oy, x2 = n() + ox, y2 = n() + oy;
          cx = n() + ox;
          cy = n() + oy;
          path.cubicTo(x1, y1, x2, y2, cx, cy);
          lx = x2;
          ly = y2;
        }
      case 'S':
        {
          final x1 = lx == null ? cx : 2 * cx - lx;
          final y1 = ly == null || lx == null ? cy : 2 * cy - ly;
          final x2 = n() + ox, y2 = n() + oy;
          cx = n() + ox;
          cy = n() + oy;
          path.cubicTo(x1, y1, x2, y2, cx, cy);
          lx = x2;
          ly = y2;
        }
      case 'Q':
        {
          final x1 = n() + ox, y1 = n() + oy;
          cx = n() + ox;
          cy = n() + oy;
          path.quadraticBezierTo(x1, y1, cx, cy);
          lx = null;
        }
      case 'Z':
        path.close();
        cx = sx;
        cy = sy;
        lx = null;
      default:
        return path; // unsupported command
    }
  }
  return path;
}
