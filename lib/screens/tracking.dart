import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data.dart';
import '../services/repo.dart';
import '../theme.dart';
import '../widgets.dart';
import 'photo_booth.dart';

void openTracking(BuildContext context, ActiveOrder order) =>
    push(context, TrackingScreen(order: order));

// ---------------------------------------------------------------------------
// A10 Pickup tracking / A10b Delivery tracking
// ---------------------------------------------------------------------------

class TrackingScreen extends StatefulWidget {
  final ActiveOrder order;
  const TrackingScreen({super.key, required this.order});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  late bool _delivery = widget.order.mode == Mode.delivery;
  Timer? _ticker;
  int _tick = 0;

  ActiveOrder get o => widget.order;

  @override
  void initState() {
    super.initState();
    Repo.refreshActive();
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _tick++;
      if (_tick % 10 == 0) Repo.refreshActive(); // ask the server every 5 s
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _done(String title, String body) async {
    int earned = o.earn;
    try {
      earned = await Repo.collectActive();
    } catch (e) {
      if (mounted) toast(context, e.toString());
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  color: C.blush,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.icecream_rounded,
                  color: C.deep,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(title, textAlign: TextAlign.center, style: fred(24)),
              const SizedBox(height: 6),
              Text(
                body,
                textAlign: TextAlign.center,
                style: dm(14.5, color: C.grey, height: 1.4),
              ),
              if (earned > 0) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: C.yellow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '+$earned pts added · ${app.points} total',
                    style: dm(14, weight: FontWeight.w700),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Btn(
                'Snap it for +25 pts',
                onTap: () {
                  Navigator.pop(ctx);
                  push(context, const PhotoBoothScreen());
                },
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Close', style: dm(15, color: C.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Row(
                children: [
                  const CircleBtn(icon: Icons.close_rounded),
                  Expanded(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: C.line, width: 1.2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _seg(
                              'Pickup',
                              !_delivery,
                              () => setState(() => _delivery = false),
                            ),
                            _seg(
                              'Delivery',
                              _delivery,
                              () => setState(() => _delivery = true),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 46),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _delivery ? _deliveryView() : _pickupView(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _seg(String t, bool sel, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: sel ? C.ink : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        t,
        style: dm(
          14,
          weight: FontWeight.w700,
          color: sel ? Colors.white : C.ink,
        ),
      ),
    ),
  );

  // ---------------- Pickup ----------------
  Widget _pickupView() {
    final e = o.elapsed;
    final stage = o.stage;
    final progress = stage == 2
        ? 1.0
        : 0.25 + 0.65 * (e / ActiveOrder.prepSeconds).clamp(0.0, 1.0);
    final minsLeft = math.max(
      1,
      (o.prepMinutes * (1 - e / ActiveOrder.prepSeconds)).ceil(),
    );
    final title = stage == 2
        ? 'Ready at the counter!'
        : (stage == 0
              ? 'Order received'
              : (o.waffle
                    ? 'Your waffle is on the iron'
                    : 'Scooping it up now'));
    final placed = o.placed;
    return ListView(
      key: const ValueKey('pickup'),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      children: [
        Center(
          child: SizedBox(
            width: 220,
            height: 220,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 600),
              builder: (_, v, __) => CustomPaint(
                painter: _RingPainter(v),
                child: Center(
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: const BoxDecoration(
                      color: C.blush,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      stage == 2
                          ? Icons.check_rounded
                          : (o.waffle
                                ? Icons.grid_on_rounded
                                : Icons.icecream_outlined),
                      size: 60,
                      color: C.deep.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: Text(
            'ORDER #${o.number}',
            style: dm(13.5, color: C.deep, weight: FontWeight.w700, spacing: 2),
          ),
        ),
        const SizedBox(height: 4),
        Text(title, textAlign: TextAlign.center, style: fred(28, height: 1.1)),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(
            style: dm(15.5, color: C.grey),
            children: stage == 2
                ? [
                    const TextSpan(
                      text: 'Show your order number at the counter',
                    ),
                  ]
                : [
                    const TextSpan(text: 'Ready for pickup in about '),
                    TextSpan(
                      text: '$minsLeft min',
                      style: dm(15.5, weight: FontWeight.w700),
                    ),
                  ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        CardBox(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            children: [
              _step(
                'Order received',
                null,
                fmtTime(placed),
                stage >= 0,
                stage == 0,
              ),
              _step(
                'Making it',
                'Scoops going on now',
                stage >= 1
                    ? fmtTime(placed.add(const Duration(minutes: 3)))
                    : '',
                stage >= 1,
                stage == 1,
              ),
              _step(
                'Ready at the counter',
                null,
                stage >= 2
                    ? fmtTime(placed.add(const Duration(minutes: 7)))
                    : '',
                stage >= 2,
                stage == 2,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 72,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: C.ink,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('+${o.earn} pts', style: fred(18, color: C.yellow)),
                    Text(
                      o.collected
                          ? 'added to your balance'
                          : 'added when you collect',
                      style: dm(12.5, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => push(context, const PhotoBoothScreen()),
                child: Container(
                  height: 72,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: C.pink,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Photo booth', style: fred(18, color: Colors.white)),
                      Text(
                        'Snap it for +25 pts',
                        style: dm(12.5, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Btn(
          o.collected ? 'Enjoy! Back to home' : "I'm here, bring it out",
          onTap: () {
            if (o.collected) {
              app.finishOrder();
              Navigator.of(context).popUntil((r) => r.isFirst);
              app.setTab(0);
              return;
            }
            if (stage < 2) {
              toast(
                context,
                "Got it! We'll bring it out the moment it's ready",
              );
            }
            _done(
              'Bringing it out!',
              'Look for the pink tray. Enjoy your treat.',
            );
          },
        ),
      ],
    );
  }

  Widget _step(
    String title,
    String? sub,
    String time,
    bool done,
    bool current,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: !done
                  ? Colors.white
                  : (current && title != 'Order received' ? C.deep : C.green),
              border: Border.all(
                color: done ? Colors.transparent : const Color(0xFFBDB2B6),
                width: 1.6,
              ),
              boxShadow: current && done
                  ? [
                      BoxShadow(
                        color: C.pink.withValues(alpha: 0.3),
                        blurRadius: 0,
                        spreadRadius: 5,
                      ),
                    ]
                  : null,
            ),
            child: done && !(current && title != 'Order received')
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: dm(
                    16,
                    weight: done ? FontWeight.w700 : FontWeight.w400,
                    color: done ? C.ink : C.grey,
                  ),
                ),
                if (sub != null && current)
                  Text(sub, style: dm(13, color: C.grey)),
              ],
            ),
          ),
          Text(time, style: dm(13.5, color: C.grey)),
        ],
      ),
    );
  }

  // ---------------- Delivery ----------------
  static const _route = [
    Offset(0.2, 0.25),
    Offset(0.52, 0.46),
    Offset(0.8, 0.82),
  ];

  Widget _deliveryView() {
    final e = o.elapsed;
    final t = (e / ActiveOrder.driveSeconds).clamp(0.0, 1.0);
    final arrived = t >= 1;
    final mins = math.max(0, (12 * (1 - t)).ceil());
    final eta = o.placed.add(const Duration(minutes: 35));
    return ListView(
      key: const ValueKey('delivery'),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: AspectRatio(
            aspectRatio: 1.2,
            child: LayoutBuilder(
              builder: (context, c) {
                Offset at(Offset f) =>
                    Offset(f.dx * c.maxWidth, f.dy * c.maxHeight);
                final driver = at(alongPolyline(_route, t));
                final store = at(_route.first);
                final home = at(_route.last);
                return Stack(
                  children: [
                    const Positioned.fill(
                      child: CustomPaint(painter: MapPainter(route: _route)),
                    ),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          arrived ? 'Arrived!' : 'Arriving ${fmtTime(eta)}',
                          style: dm(13.5, weight: FontWeight.w700),
                        ),
                      ),
                    ),
                    Positioned(
                      left: store.dx - 22,
                      top: store.dy - 22,
                      child: const _MarkerLogo(),
                    ),
                    Positioned(
                      left: home.dx - 20,
                      top: home.dy - 40,
                      child: const MapPin(color: C.blue, size: 34),
                    ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 500),
                      left: driver.dx - 22,
                      top: driver.dy - 22,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: C.ink,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(
                          Icons.pedal_bike_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'ORDER #${o.number} · ${arrived ? 'DELIVERED' : 'ON THE WAY'}',
          style: dm(13.5, color: C.deep, weight: FontWeight.w700, spacing: 1.5),
        ),
        const SizedBox(height: 4),
        Text(arrived ? 'At your door' : '$mins min away', style: fred(28)),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: 0.15 + 0.85 * t,
            minHeight: 8,
            color: C.deep,
            backgroundColor: C.blush,
          ),
        ),
        const SizedBox(height: 14),
        CardBox(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: C.yellow,
                child: Text(
                  'JD',
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700,
                    color: C.ink,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jas · your driver',
                      style: dm(16, weight: FontWeight.w700),
                    ),
                    Text(
                      'Insulated bag · scoops stay frozen',
                      style: dm(13, color: C.grey),
                    ),
                  ],
                ),
              ),
              CircleBtn(
                icon: Icons.chat_bubble_outline_rounded,
                color: C.blush,
                iconColor: C.deep,
                onTap: () => toast(context, 'Chat with Jas opens here'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        CardBox(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Delivering to Home',
                      style: dm(15, weight: FontWeight.w700),
                    ),
                  ),
                  Text('Leave at door', style: dm(14, color: C.grey)),
                ],
              ),
              const SizedBox(height: 4),
              Text(app.addressLine, style: dm(14, color: C.grey)),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: C.line),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      o.names.join(', '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: dm(14.5),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(money(o.total), style: dm(15, weight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 6),
              Row2(
                'Points on delivery',
                '+${o.earn} pts',
                style: dm(14.5, color: C.green, weight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (arrived && !o.collected)
          Btn(
            'I got it, thanks!',
            onTap: () =>
                _done('Delivered!', 'Hope it\'s still perfectly frozen.'),
          )
        else if (o.collected)
          Btn(
            'Back to home',
            onTap: () {
              app.finishOrder();
              Navigator.of(context).popUntil((r) => r.isFirst);
              app.setTab(0);
            },
          )
        else
          Row(
            children: [
              Expanded(
                child: Btn(
                  'Call driver',
                  style: BtnStyle.outline,
                  onTap: () => toast(context, 'Calling Jas…'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Btn(
                  'Get help',
                  style: BtnStyle.dark,
                  onTap: () => _help(context),
                ),
              ),
            ],
          ),
      ],
    );
  }

  void _help(BuildContext context) {
    showSheet(
      context,
      title: 'How can we help?',
      child: Column(
        children: [
          for (final t in [
            'My order is late',
            'Something is missing',
            'Change delivery instructions',
            'Cancel my order',
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CardBox(
                onTap: () {
                  Navigator.pop(context);
                  toast(
                    context,
                    'A Lick It team member will message you shortly',
                  );
                },
                child: Row(
                  children: [
                    Expanded(
                      child: Text(t, style: dm(15.5, weight: FontWeight.w500)),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: C.grey),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MarkerLogo extends StatelessWidget {
  const _MarkerLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: C.pink,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        child: Image(
          image: AssetImage('assets/images/logo.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  _RingPainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 10;
    final track = Paint()
      ..color = C.blush
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;
    canvas.drawCircle(c, r, track);
    final arc = Paint()
      ..color = C.pink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * value,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.value != value;
}
