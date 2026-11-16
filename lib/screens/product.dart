import 'package:flutter/material.dart';

import '../data.dart';
import '../plate_preview.dart';
import '../theme.dart';
import '../widgets.dart';
import 'cart.dart';

// ---------------------------------------------------------------------------
// A06 Product
// ---------------------------------------------------------------------------

class ProductScreen extends StatefulWidget {
  final MenuItem item;
  const ProductScreen({super.key, required this.item});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final List<String> _scoops = [];
  final List<String> _toppings = [];
  int _qty = 1;

  MenuItem get item => widget.item;

  double get _unit => app.unitFor(item, _scoops.length, _toppings.length);
  double get _total => round2(_unit * _qty);

  void _toggleScoop(String s) {
    setState(() {
      if (_scoops.contains(s)) {
        _scoops.remove(s);
      } else if (_scoops.length < 2) {
        _scoops.add(s);
      } else {
        toast(context, 'Up to 2 extra scoops');
      }
    });
  }

  void _add() {
    app.add(item, scoops: _scoops, toppings: _toppings, qty: _qty);
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    nav.pop();
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Added $_qty × ${item.name}'),
        action: SnackBarAction(
          label: 'View cart',
          textColor: C.yellow,
          onPressed: () =>
              nav.push(MaterialPageRoute(builder: (_) => const CartScreen())),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: top + 280,
                    color: C.pink,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: top + 20,
                          child: Hero(
                            tag: 'tile-${item.id}',
                            child: Container(
                              width: width * 0.66,
                              height: width * 0.66,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: PlatePreview(
                                item: item,
                                scoops: List.of(_scoops),
                                toppings: List.of(_toppings),
                                size: width * 0.62,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          top: top + 10,
                          child: const CircleBtn(size: 46),
                        ),
                        Positioned(
                          right: 16,
                          top: top + 10,
                          child: ListenableBuilder(
                            listenable: app,
                            builder: (context, _) {
                              final fav = app.favourites.contains(item.id);
                              return CircleBtn(
                                icon: fav
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                iconColor: C.deep,
                                onTap: () {
                                  app.toggleFav(item.id);
                                  toast(
                                    context,
                                    fav
                                        ? 'Removed from favourites'
                                        : 'Saved to favourites',
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -28),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: C.cream,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(30),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (item.tag != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: C.ink,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    item.tag!,
                                    style: dm(
                                      12,
                                      color: Colors.white,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              const Spacer(),
                              Text(
                                money(app.unitFor(item, 0, 0)),
                                style: fred(24),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(item.name, style: fred(28, height: 1.1)),
                          const SizedBox(height: 4),
                          Text(item.desc, style: dm(15.5, color: C.grey)),
                          if (item.takesScoops) ...[
                            const SizedBox(height: 22),
                            _SectionTitle('Add a scoop', '+\$2.50 · up to 2'),
                            const SizedBox(height: 10),
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
                          ],
                          const SizedBox(height: 22),
                          _SectionTitle('Extra toppings', '+\$1.25 each'),
                          const SizedBox(height: 10),
                          CardBox(
                            padding: EdgeInsets.zero,
                            child: Column(
                              children: [
                                for (
                                  var i = 0;
                                  i < toppingOptions.length;
                                  i++
                                ) ...[
                                  if (i > 0)
                                    const Divider(
                                      height: 1,
                                      color: C.line,
                                      indent: 14,
                                    ),
                                  InkWell(
                                    onTap: () => setState(() {
                                      final t = toppingOptions[i];
                                      _toppings.contains(t)
                                          ? _toppings.remove(t)
                                          : _toppings.add(t);
                                    }),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 14,
                                      ),
                                      child: Row(
                                        children: [
                                          PinkCheck(
                                            _toppings.contains(
                                              toppingOptions[i],
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Text(
                                              toppingOptions[i],
                                              style: dm(16),
                                            ),
                                          ),
                                          Text(
                                            '+\$1.25',
                                            style: dm(14, color: C.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 16,
                                color: C.grey,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Contains milk, wheat & soy. May contain nuts.',
                                  style: dm(12.5, color: C.grey),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              12 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: C.line)),
            ),
            child: Row(
              children: [
                QtyStepper(
                  qty: _qty,
                  large: true,
                  onMinus: () => setState(() => _qty = _qty > 1 ? _qty - 1 : 1),
                  onPlus: () => setState(() => _qty++),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Btn(
                    'Add · +${_total.floor()} pts',
                    trailing: money(_total),
                    fontSize: 16,
                    onTap: _add,
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

class _SectionTitle extends StatelessWidget {
  final String title;
  final String note;
  const _SectionTitle(this.title, this.note);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: fred(19))),
        Text(note, style: dm(13, color: C.grey)),
      ],
    );
  }
}
