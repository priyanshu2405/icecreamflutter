import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data.dart';
import '../services/repo.dart';
import '../theme.dart';
import '../widgets.dart';

// ---------------------------------------------------------------------------
// Frames
// ---------------------------------------------------------------------------

class FrameStyle {
  final String name;
  final Color color;
  final Color pill;
  final Color? tint;
  final bool sprinkles;
  const FrameStyle(
    this.name,
    this.color,
    this.pill, {
    this.tint,
    this.sprinkles = false,
  });
}

const frames = [
  FrameStyle('Drip', C.pink, C.pink),
  FrameStyle('Classic', C.cream, C.pink),
  FrameStyle('Sprinkles', C.yellow, C.pink, sprinkles: true),
  FrameStyle('Midnight', C.ink, C.pink, tint: Color(0x33000000)),
  FrameStyle('Birthday', Color(0xFF9AD8FF), C.pink, sprinkles: true),
];

/// The framed photo. The prototype uses a sample photo of the store sign in
/// place of the live camera feed.
class BoothFrame extends StatelessWidget {
  final FrameStyle style;
  final double scale;
  final double radius;
  const BoothFrame({
    super.key,
    required this.style,
    this.scale = 1,
    this.radius = 26,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius * scale),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/booth.jpg', fit: BoxFit.cover),
          if (style.tint != null) Container(color: style.tint),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: style.color, width: 12 * scale),
              borderRadius: BorderRadius.circular(radius * scale),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 70 * scale,
            child: CustomPaint(painter: _DripPainter(style.color)),
          ),
          if (style.sprinkles)
            Positioned.fill(
              child: CustomPaint(painter: _SprinklePainter(scale)),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 26 * scale,
            child: Column(
              children: [
                Text(
                  'Love at First Lick.',
                  style: script(
                    30 * scale,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: C.deep,
                        offset: Offset(0, 2 * scale),
                        blurRadius: 0,
                      ),
                      Shadow(
                        color: Colors.black38,
                        offset: Offset(0, 3 * scale),
                        blurRadius: 8 * scale,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 6 * scale),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16 * scale,
                    vertical: 6 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: style.pill,
                    borderRadius: BorderRadius.circular(20 * scale),
                  ),
                  child: Text(
                    'LICK IT · CITY PKWY · SURREY',
                    style: fred(
                      12 * scale,
                      color: Colors.white,
                      spacing: 1.5 * scale,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DripPainter extends CustomPainter {
  final Color color;
  _DripPainter(this.color);

  @override
  void paint(Canvas canvas, Size s) {
    final p = Path()..moveTo(0, 0);
    p.lineTo(0, s.height * 0.45);
    const drips = [0.55, 0.3, 0.8, 0.4, 0.95, 0.35, 0.6, 0.3];
    final step = s.width / drips.length;
    for (var i = 0; i < drips.length; i++) {
      final x0 = i * step;
      final depth = s.height * drips[i];
      p.quadraticBezierTo(
        x0 + step * 0.1,
        s.height * 0.3,
        x0 + step * 0.3,
        s.height * 0.35,
      );
      p.lineTo(x0 + step * 0.3, depth - step * 0.2);
      p.arcToPoint(
        Offset(x0 + step * 0.7, depth - step * 0.2),
        radius: Radius.circular(step * 0.2),
        clockwise: false,
      );
      p.lineTo(x0 + step * 0.7, s.height * 0.35);
      p.quadraticBezierTo(
        x0 + step * 0.9,
        s.height * 0.3,
        x0 + step,
        s.height * 0.4,
      );
    }
    p.lineTo(s.width, 0);
    p.close();
    canvas.drawPath(p, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _DripPainter old) => old.color != color;
}

class _SprinklePainter extends CustomPainter {
  final double scale;
  _SprinklePainter(this.scale);

  @override
  void paint(Canvas canvas, Size s) {
    final rnd = math.Random(7);
    const colors = [C.pink, Colors.white, Color(0xFF8FD3FF), C.yellow, C.deep];
    for (var i = 0; i < 46; i++) {
      final edge = rnd.nextInt(4);
      final along = rnd.nextDouble();
      final inset = rnd.nextDouble() * 34 * scale;
      final o = switch (edge) {
        0 => Offset(along * s.width, 70 * scale + inset),
        1 => Offset(s.width - inset, along * s.height),
        2 => Offset(along * s.width, s.height - inset),
        _ => Offset(inset, along * s.height),
      };
      canvas.save();
      canvas.translate(o.dx, o.dy);
      canvas.rotate(rnd.nextDouble() * math.pi);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: 12 * scale,
            height: 4 * scale,
          ),
          Radius.circular(2 * scale),
        ),
        Paint()..color = colors[i % colors.length],
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// A15 Photo booth
// ---------------------------------------------------------------------------

class PhotoBoothScreen extends StatefulWidget {
  const PhotoBoothScreen({super.key});

  @override
  State<PhotoBoothScreen> createState() => _PhotoBoothScreenState();
}

class _PhotoBoothScreenState extends State<PhotoBoothScreen> {
  int _frame = 0;
  int _mode = 1; // 0 boomerang, 1 photo, 2 strip
  bool _timer = false;
  bool _flash = false;
  int? _count;
  bool _flashOverlay = false;
  bool _front = false;

  Future<void> _shoot() async {
    if (_count != null) return;
    if (_timer) {
      for (var i = 3; i > 0; i--) {
        setState(() => _count = i);
        await Future<void>.delayed(const Duration(seconds: 1));
        if (!mounted) return;
      }
      setState(() => _count = null);
    }
    setState(() => _flashOverlay = true);
    await Future<void>.delayed(const Duration(milliseconds: 160));
    if (!mounted) return;
    setState(() => _flashOverlay = false);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    push(context, PhotoShareScreen(style: frames[_frame], strip: _mode == 2));
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: const Color(0xFF15100F),
      body: Column(
        children: [
          Container(height: top, color: frames[_frame].color),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Transform.flip(
                        key: ValueKey('$_frame-$_front'),
                        flipX: _front,
                        child: BoothFrame(style: frames[_frame]),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 22,
                  top: 12,
                  child: _roundIcon(
                    Icons.close_rounded,
                    () => Navigator.of(context).maybePop(),
                  ),
                ),
                Positioned(
                  right: 22,
                  top: 12,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _timer = !_timer),
                        child: Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _timer
                                ? C.yellow
                                : Colors.black.withValues(alpha: 0.45),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '3s',
                            style: dm(
                              14,
                              color: _timer ? C.ink : Colors.white,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _roundIcon(
                        _flash
                            ? Icons.flash_on_rounded
                            : Icons.flash_off_rounded,
                        () => setState(() => _flash = !_flash),
                        active: _flash,
                      ),
                    ],
                  ),
                ),
                if (_count != null)
                  Center(
                    child: Text(
                      '$_count',
                      style: fred(120, color: Colors.white, height: 1),
                    ),
                  ),
                IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _flashOverlay ? 1 : 0,
                    duration: const Duration(milliseconds: 120),
                    child: Container(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: frames.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final sel = i == _frame;
                return GestureDetector(
                  onTap: () => setState(() => _frame = i),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: frames[i].color,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: sel ? Colors.white : Colors.white24,
                            width: sel ? 3 : 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        frames[i].name,
                        style: dm(
                          12,
                          color: sel ? Colors.white : Colors.white60,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 34),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => toast(context, 'Your Lick It photos live here'),
                  child: Container(
                    width: 52,
                    height: 52,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Image.asset(
                      'assets/images/booth.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _shoot,
                  child: Container(
                    width: 84,
                    height: 84,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: C.pink,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                _roundIcon(
                  Icons.flip_camera_ios_outlined,
                  () => setState(() => _front = !_front),
                  size: 52,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 3; i++)
                GestureDetector(
                  onTap: () => setState(() => _mode = i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      ['BOOMERANG', 'PHOTO', 'STRIP ×4'][i],
                      style: dm(
                        13.5,
                        color: _mode == i ? C.pink : Colors.white54,
                        weight: FontWeight.w700,
                        spacing: 0.8,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 10 + bottom),
        ],
      ),
    );
  }

  Widget _roundIcon(
    IconData i,
    VoidCallback onTap, {
    bool active = false,
    double size = 44,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: active ? C.yellow : Colors.black.withValues(alpha: 0.45),
        shape: BoxShape.circle,
      ),
      child: Icon(i, color: active ? C.ink : Colors.white, size: size * 0.5),
    ),
  );
}

// ---------------------------------------------------------------------------
// A16 Photo share
// ---------------------------------------------------------------------------

class PhotoShareScreen extends StatefulWidget {
  final FrameStyle style;
  final bool strip;
  const PhotoShareScreen({super.key, required this.style, this.strip = false});

  @override
  State<PhotoShareScreen> createState() => _PhotoShareScreenState();
}

class _PhotoShareScreenState extends State<PhotoShareScreen> {
  bool _feature = true;

  void _share(String where) {
    if (!app.sharedPhoto) {
      app.sharedPhoto = true;
      Repo.sharePhoto();
      toast(context, 'Shared to $where · +${Rules.photoPoints} pts earned!');
    } else {
      toast(
        context,
        where == 'Save' ? 'Saved to your photos' : 'Shared to $where',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cardW = math.min(w * 0.76, 320.0);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Retake',
                      style: dm(16, weight: FontWeight.w500),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Looking sweet!',
                      textAlign: TextAlign.center,
                      style: fred(20),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).popUntil((r) => r.isFirst),
                    child: Text(
                      'Done',
                      style: dm(16, color: C.deep, weight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                children: [
                  Center(
                    child: Transform.rotate(
                      angle: 0.03,
                      child: Container(
                        width: cardW,
                        padding: EdgeInsets.fromLTRB(
                          cardW * 0.05,
                          cardW * 0.05,
                          cardW * 0.05,
                          8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.14),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            if (widget.strip)
                              SizedBox(
                                height: cardW * 1.08,
                                child: GridView.count(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 6,
                                  crossAxisSpacing: 6,
                                  childAspectRatio: 0.82,
                                  physics: const NeverScrollableScrollPhysics(),
                                  children: [
                                    for (var i = 0; i < 4; i++)
                                      BoothFrame(
                                        style: widget.style,
                                        scale: 0.32,
                                        radius: 10,
                                      ),
                                  ],
                                ),
                              )
                            else
                              AspectRatio(
                                aspectRatio: 0.82,
                                child: BoothFrame(
                                  style: widget.style,
                                  scale: cardW / 400,
                                  radius: 4,
                                ),
                              ),
                            const SizedBox(height: 8),
                            Text(
                              'Love at First Lick.',
                              style: script(20, color: C.deep),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: C.ink,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: C.yellow,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            app.sharedPhoto ? '✓' : '+25',
                            style: fred(17),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              style: dm(14, color: Colors.white, height: 1.35),
                              children: [
                                const TextSpan(text: 'Share with '),
                                TextSpan(
                                  text: '#LickItLove',
                                  style: dm(
                                    14,
                                    color: Colors.white,
                                    weight: FontWeight.w700,
                                    height: 1.35,
                                  ),
                                ),
                                const TextSpan(
                                  text: ' to earn 25 points. Best photo each month wins a free waffle cake.',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('Share to', style: fred(18)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _shareTile(
                        'Instagram',
                        Icons.camera_alt_outlined,
                        const Color(0xFFC13584),
                      ),
                      _shareTile('TikTok', Icons.music_note_rounded, C.ink),
                      _shareTile(
                        'Facebook',
                        Icons.facebook_rounded,
                        const Color(0xFF1877F2),
                      ),
                      _shareTile(
                        'Save',
                        Icons.download_rounded,
                        C.blush,
                        iconColor: C.deep,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () => setState(() => _feature = !_feature),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PinkCheck(_feature),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Allow Lick It to feature my photo on the website wall',
                            style: dm(14.5, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shareTile(
    String label,
    IconData icon,
    Color bg, {
    Color iconColor = Colors.white,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: CardBox(
          padding: const EdgeInsets.symmetric(vertical: 12),
          onTap: () => _share(label),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(height: 6),
              Text(label, style: dm(12.5, weight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
