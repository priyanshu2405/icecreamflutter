import 'package:flutter/material.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'cart.dart';

/// Flavour chips grouped like the website ("The Classics", "Fruit Favourites"…),
/// every chip tappable. Used on the Menu picker and on an ice-cream product page.
class FlavourChooser extends StatelessWidget {
  final List<String> picked;
  final ValueChanged<String> onToggle;
  const FlavourChooser({super.key, required this.picked, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final groups = groupedFlavours();
    final flat = scoopFlavours.every((f) => Rules.scoopPriceOf(f.name) == Rules.scoop);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final g in groups.entries) ...[
          if (groups.length > 1) ...[
            const SizedBox(height: 10),
            Text(g.key.toUpperCase(), style: dm(12, color: C.deep, weight: FontWeight.w700, spacing: 1.2)),
            const SizedBox(height: 8),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: [
              for (final f in g.value)
                PillChip(
                  flat ? f.name : '${f.name} +${money(Rules.scoopPriceOf(f.name))}',
                  dot: f.dot,
                  selected: picked.contains(f.name),
                  onTap: () => onToggle(f.name),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Picking rules shared by the Menu picker and the product page (same as the website):
/// pick the flavours the product includes, then up to 4 extra scoops.
class IcePick {
  static const maxExtra = 4;

  static List<String> toggle(BuildContext context, List<String> picked, String f, int included) {
    final next = List<String>.of(picked);
    if (next.contains(f)) {
      next.remove(f);
    } else if (next.length < included + maxExtra) {
      next.add(f);
    } else {
      toast(context, 'Up to ${included + maxExtra} flavours');
    }
    return next;
  }

  static int need(List<String> picked, int included) => (included - picked.length).clamp(0, included);

  static List<String> extras(List<String> picked, int included) =>
      picked.length > included ? picked.sublist(included) : const [];

  static String hint(List<String> picked, int included) {
    final n = need(picked, included);
    if (n > 0) {
      return 'Tap $n more flavour${n > 1 ? 's' : ''}'
          '${picked.isEmpty ? '' : ' · picked: ${picked.join(', ')}'}'
          ' · want more? Extra scoops +${money(Rules.scoop)} each';
    }
    final ex = extras(picked, included);
    return 'Picked: ${picked.join(', ')}'
        '${ex.isEmpty ? ' · tap more to add extra scoops +${money(Rules.scoop)} each' : ' · ${ex.length} extra scoop${ex.length > 1 ? 's' : ''} +${money(ex.fold(0.0, (a, f) => a + Rules.scoopPriceOf(f)))}'}';
  }

  /// Cart line exactly like the website: extras as "Extra: X", included flavours in the note.
  static void addToCart(MenuItem item, List<String> picked, {int qty = 1}) {
    app.add(
      item,
      scoops: [for (final f in extras(picked, item.includedFlavours)) 'Extra: $f'],
      qty: qty,
      note: 'Flavours: ${picked.take(item.includedFlavours).join(', ')}',
    );
  }
}

/// The Menu's Ice Cream section, like the website: choose the size
/// (every ice-cream product from the admin), tap flavours, add.
class IceCreamPicker extends StatefulWidget {
  const IceCreamPicker({super.key});

  @override
  State<IceCreamPicker> createState() => _IceCreamPickerState();
}

class _IceCreamPickerState extends State<IceCreamPicker> {
  String? _slug;
  List<String> _picked = [];

  List<MenuItem> get _products => menu.where((m) => m.isIceCream).toList()..sort((a, b) => a.price.compareTo(b.price));

  @override
  Widget build(BuildContext context) {
    final products = _products;
    final cur = products.where((p) => p.id == _slug).firstOrNull ?? products.firstOrNull;
    final included = cur?.includedFlavours ?? 1;
    final picked = _picked.take(included + IcePick.maxExtra).toList();
    final need = cur == null ? 0 : IcePick.need(picked, included);
    final extrasCost = IcePick.extras(picked, included).fold(0.0, (a, f) => a + Rules.scoopPriceOf(f));

    return CardBox(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: C.blush, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.icecream_outlined, color: C.deep),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('In the case today', style: fred(18)),
                    Text('${scoopFlavours.length} flavours · selection rotates', style: dm(13, color: C.grey)),
                  ],
                ),
              ),
            ],
          ),
          if (products.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('1. Choose your size', style: fred(16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in products)
                  PillChip(
                    '${p.name} · ${money(p.price)}',
                    selected: p.id == cur!.id,
                    onTap: () => setState(() {
                      _slug = p.id;
                      _picked = _picked.take(p.includedFlavours + IcePick.maxExtra).toList();
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(included == 1 ? '2. Pick your flavour' : '2. Pick $included flavours', style: fred(16)),
          ],
          const SizedBox(height: 4),
          FlavourChooser(
            picked: picked,
            onToggle: (f) {
              if (cur == null) {
                toast(context, 'Ice cream sizes are not on the menu right now');
                return;
              }
              setState(() {
                _slug = cur.id;
                _picked = IcePick.toggle(context, picked, f, included);
              });
            },
          ),
          if (cur != null) ...[
            const SizedBox(height: 12),
            Text(IcePick.hint(picked, included), style: dm(13, color: need > 0 ? C.deep : C.grey, height: 1.35)),
            const SizedBox(height: 12),
            Opacity(
              opacity: need > 0 ? 0.65 : 1,
              child: Btn(
                need > 0 ? 'Pick $need more' : 'Add to order · ${money(cur.price + extrasCost)}',
                height: 50,
                fontSize: 16,
                onTap: () {
                  if (need > 0) {
                    toast(context, 'Pick $need more flavour${need > 1 ? 's' : ''}');
                    return;
                  }
                  IcePick.addToCart(cur, picked);
                  setState(() => _picked = []);
                  toast(context, 'Added ${cur.name}', action: 'View cart', onAction: () => push(context, const CartScreen()));
                },
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            'Please tell our team about allergies. Flavours and toppings are subject to availability.',
            style: dm(12, color: C.grey, height: 1.35),
          ),
        ],
      ),
    );
  }
}
