import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data.dart';
import '../plate_preview.dart';
import '../theme.dart';
import '../widgets.dart';
import 'cart.dart';
import 'product.dart';

// ---------------------------------------------------------------------------
// Build your own waffle: the app version of luckit.vads.ca/build-your-own.
// Base → up to 3 scoops → drizzle → toppings, with the live plate preview.
// Orders go to the same three server products the website uses
// (build-your-own / -red-velvet / -chocolate) with base + drizzle in the note.
// ---------------------------------------------------------------------------

class BuildYourOwnScreen extends StatefulWidget {
  const BuildYourOwnScreen({super.key});

  @override
  State<BuildYourOwnScreen> createState() => _BuildYourOwnScreenState();
}

class _BuildYourOwnScreenState extends State<BuildYourOwnScreen> {
  String _base = byoBases.first;
  final List<String> _scoops = [];
  String _drizzle = byoDrizzles.first.name;
  final List<String> _tops = [];
  int _qty = 1;
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Same starting waffle as the website, using whatever is on today's list.
    final names = scoopFlavours.map((f) => f.name).toSet();
    _scoops.addAll(['Strawberry', 'Cookies & Cream'].where(names.contains));
    if (toppingOptions.contains('Oreo crumble')) _tops.add('Oreo crumble');
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  MenuItem get _item => byoItemFor(_base);
  Flavour get _drizzleF => byoDrizzles.firstWhere((d) => d.name == _drizzle);
  double get _unit => app.unitFor(_item, _scoops.length, _tops.length);
  double get _total => round2(_unit * _qty);

  String _basePrice(String b) {
    final diff = round2(byoItemFor(b).price - byoItemFor(byoBases.first).price);
    return diff <= 0 ? 'Included' : '+${money(diff)}';
  }

  /// Sent to the kitchen with the line, like the website ("Base: … · Drizzle: …").
  String get _kitchenNote {
    final extra = _note.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    final n = 'Base: $_base · Drizzle: $_drizzle${extra.isEmpty ? '' : ' · $extra'}';
    return n.length > 255 ? n.substring(0, 255) : n;
  }

  void _toggleScoop(String s) {
    setState(() {
      if (_scoops.contains(s)) {
        _scoops.remove(s);
      } else if (_scoops.length < byoMaxScoops) {
        _scoops.add(s);
      } else {
        toast(context, 'Up to $byoMaxScoops scoops');
      }
    });
  }

  void _toggleTop(String t) =>
      setState(() => _tops.contains(t) ? _tops.remove(t) : _tops.add(t));

  void _add() {
    final qty = _qty;
    app.add(_item, scoops: _scoops, toppings: _tops, qty: qty, note: _kitchenNote);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const CartScreen()),
    );
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text('Added $qty × your $_base waffle')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final width = MediaQuery.of(context).size.width;
    final plate = math.min(width * 0.74, 360.0);
    final chips = [
      '$_base waffle',
      ..._scoops.map((s) => '$s scoop'),
      '$_drizzle drizzle',
      ..._tops,
    ];
    final pairings = [
      for (final n in byoPairings)
        ...menu.where((m) => m.name.toLowerCase() == n.toLowerCase()).take(1),
    ];

    return Scaffold(
      backgroundColor: C.cream,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ------------------------------------------------ preview
                  Container(
                    color: C.pink,
                    padding: EdgeInsets.fromLTRB(16, top + 10, 16, 46),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const CircleBtn(size: 46),
                            Expanded(
                              child: Text(
                                'Made just for you',
                                textAlign: TextAlign.center,
                                style: script(22, color: Colors.white),
                              ),
                            ),
                            const _CartButton(),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: plate * 1.12,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: plate * 1.12,
                                height: plate * 1.12,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF25C9A),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox.square(
                                dimension: plate * 0.98,
                                child: CustomPaint(painter: _DashedCircle()),
                              ),
                              PlatePreview(
                                item: _item,
                                scoops: List.of(_scoops),
                                toppings: List.of(_tops),
                                base: _base,
                                drizzle: _drizzleF,
                                size: plate,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final c in chips)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Text(c, style: dm(13, weight: FontWeight.w700)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ------------------------------------------------ options
                  Transform.translate(
                    offset: const Offset(0, -28),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: C.cream,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Build your waffle', style: fred(30, height: 1.05)),
                          const SizedBox(height: 6),
                          Text.rich(
                            TextSpan(
                              style: dm(15.5, color: C.grey),
                              children: [
                                const TextSpan(text: 'Fresh off the iron, finished your way. Starts at '),
                                TextSpan(
                                  text: money(byoItemFor(byoBases.first).price),
                                  style: dm(15.5, weight: FontWeight.w700),
                                ),
                                const TextSpan(text: '.'),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),
                          const _Step(1, 'Choose your base'),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              for (var i = 0; i < byoBases.length; i++) ...[
                                if (i > 0) const SizedBox(width: 10),
                                Expanded(
                                  child: _OptionCard(
                                    title: byoBases[i],
                                    subtitle: _basePrice(byoBases[i]),
                                    selected: _base == byoBases[i],
                                    onTap: () => setState(() => _base = byoBases[i]),
                                  ),
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 26),
                          _Step(2, 'Add scoops', note: 'up to $byoMaxScoops · ${_scoops.length} chosen'),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 10,
                            children: [
                              for (final f in scoopFlavours)
                                PillChip(
                                  f.name,
                                  dot: f.dot,
                                  selected: _scoops.contains(f.name),
                                  onTap: () => _toggleScoop(f.name),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '+${money(Rules.scoop)} per scoop · ${scoopFlavours.length} flavours rotate in store',
                            style: dm(13, color: C.grey),
                          ),

                          const SizedBox(height: 26),
                          const _Step(3, 'Pick a drizzle'),
                          const SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (context, c) {
                              final w = (c.maxWidth - 10) / 2;
                              return Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  for (final d in byoDrizzles)
                                    SizedBox(
                                      width: w,
                                      child: _OptionCard(
                                        title: d.name,
                                        dot: d.dot,
                                        selected: _drizzle == d.name,
                                        onTap: () => setState(() => _drizzle = d.name),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 26),
                          _Step(4, 'Top it off', note: '+${money(Rules.topping)} each'),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 10,
                            children: [
                              for (final t in toppingOptions)
                                PillChip(t, selected: _tops.contains(t), onTap: () => _toggleTop(t)),
                            ],
                          ),

                          const SizedBox(height: 26),
                          Text('Note for the kitchen', style: dm(15, weight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _note,
                            minLines: 2,
                            maxLines: 4,
                            maxLength: 180,
                            textCapitalization: TextCapitalization.sentences,
                            style: dm(15.5),
                            decoration: InputDecoration(
                              hintText: 'e.g. Drizzle on the side, please',
                              hintStyle: dm(15.5, color: C.grey),
                              counterText: '',
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: C.line, width: 2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: C.deep, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final a in const ['Contains: milk, wheat, soy', 'May contain: nuts'])
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(color: C.line),
                                  ),
                                  child: Text(a, style: dm(12.5)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                  // ------------------------------------------------ pairings
                  if (pairings.isNotEmpty)
                    Container(
                      color: C.blush,
                      padding: const EdgeInsets.fromLTRB(0, 22, 0, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: C.ink,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'AI PICKS',
                                    style: dm(10.5, color: Colors.white, weight: FontWeight.w700, spacing: 1),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Text('Goes great with your waffle', style: fred(19))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 92,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: pairings.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemBuilder: (_, i) => _PairingCard(item: pairings[i]),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          // ------------------------------------------------ total bar
          Container(
            padding: EdgeInsets.fromLTRB(14, 14, 14, 14 + MediaQuery.of(context).padding.bottom),
            decoration: const BoxDecoration(
              color: C.ink,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Row(
              children: [
                _DarkStepper(
                  qty: _qty,
                  onMinus: () => setState(() => _qty = _qty > 1 ? _qty - 1 : 1),
                  onPlus: () => setState(() => _qty++),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total · earns ${_total.floor()} pts',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: dm(12, color: const Color(0xFFE9D9E0)),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(money(_total), style: fred(24, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: const Color(0xFFFF8DBB),
                  shape: const StadiumBorder(),
                  child: InkWell(
                    customBorder: const StadiumBorder(),
                    onTap: _add,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                      child: Text('Add to order', style: dm(15.5, weight: FontWeight.w700)),
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

/// Entry card for the builder (top of the Waffles list and on Home).
class ByoBanner extends StatelessWidget {
  const ByoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final names = scoopFlavours.map((f) => f.name).toSet();
    return Material(
      color: C.pink,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => push(context, const BuildYourOwnScreen()),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
          child: Row(
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: const BoxDecoration(color: Color(0xFFF25C9A), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: PlatePreview(
                  item: byoItems.first,
                  scoops: ['Strawberry', 'Cookies & Cream'].where(names.contains).toList(),
                  toppings: const ['Rainbow sprinkles'],
                  base: byoBases.first,
                  drizzle: byoDrizzles.first,
                  size: 88,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Build your own waffle', style: fred(18, color: Colors.white)),
                    const SizedBox(height: 3),
                    Text(
                      'Pick a base, up to $byoMaxScoops scoops, a drizzle & toppings',
                      style: dm(13, color: Colors.white.withValues(alpha: 0.9), height: 1.3),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'From ${money(byoItemFor(byoBases.first).price)}',
                        style: dm(12.5, color: C.deep, weight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------- parts

class _Step extends StatelessWidget {
  final int n;
  final String title;
  final String? note;
  const _Step(this.n, this.title, {this.note});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: C.ink, shape: BoxShape.circle),
          child: Text('$n', style: dm(15, color: Colors.white, weight: FontWeight.w700)),
        ),
        const SizedBox(width: 10),
        Flexible(child: Text(title, style: fred(20))),
        if (note != null) ...[
          const SizedBox(width: 8),
          Text(note!, style: dm(13, color: C.grey, weight: FontWeight.w500)),
        ],
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color? dot;
  final bool selected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.title,
    this.subtitle,
    this.dot,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? C.blush : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? C.deep : C.line, width: 2),
          ),
          child: Row(
            children: [
              if (dot != null) ...[
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: dot,
                    shape: BoxShape.circle,
                    border: Border.all(color: C.line),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: dm(14.5, weight: FontWeight.w700, height: 1.15)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(subtitle!, style: dm(12.5, color: C.grey)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PairingCard extends StatelessWidget {
  final MenuItem item;
  const _PairingCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return CardBox(
      padding: const EdgeInsets.all(12),
      radius: 22,
      border: Colors.white,
      onTap: () => push(context, ProductScreen(item: item)),
      child: SizedBox(
        width: 200,
        child: Row(
          children: [
            FoodTile(color: item.tile, size: 64, icon: item.icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: dm(14.5, weight: FontWeight.w700, height: 1.2),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${item.category} · ${money(app.unitFor(item, 0, 0))}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: dm(12.5, color: C.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartButton extends StatelessWidget {
  const _CartButton();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => Stack(
        clipBehavior: Clip.none,
        children: [
          CircleBtn(
            icon: Icons.shopping_bag_outlined,
            onTap: () => push(context, const CartScreen()),
          ),
          if (app.cartCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                constraints: const BoxConstraints(minWidth: 20),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: C.ink,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${app.cartCount}',
                  textAlign: TextAlign.center,
                  style: dm(11.5, color: Colors.white, weight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DarkStepper extends StatelessWidget {
  final int qty;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  const _DarkStepper({required this.qty, required this.onMinus, required this.onPlus});

  @override
  Widget build(BuildContext context) {
    Widget b(IconData i, String label, VoidCallback f) => Semantics(
      button: true,
      label: label,
      child: Material(
        color: const Color(0xFF3A2C33),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: f,
          child: SizedBox(width: 40, height: 40, child: Icon(i, color: Colors.white, size: 20)),
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2026),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          b(Icons.remove_rounded, 'Decrease quantity', onMinus),
          SizedBox(
            width: 30,
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: dm(17, color: Colors.white, weight: FontWeight.w700),
            ),
          ),
          b(Icons.add_rounded, 'Increase quantity', onPlus),
        ],
      ),
    );
  }
}

class _DashedCircle extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, r);
    final p = Paint()
      ..color = const Color(0xFFFFB7D3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    const dashes = 64;
    for (var i = 0; i < dashes; i++) {
      final a = i * 2 * math.pi / dashes;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r - 1.5), a, math.pi / dashes, false, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
