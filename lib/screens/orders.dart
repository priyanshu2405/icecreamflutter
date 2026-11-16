import 'package:flutter/material.dart';

import '../data.dart';
import '../services/repo.dart';
import '../theme.dart';
import '../widgets.dart';
import 'cart.dart';
import 'home.dart' show ActiveOrderStrip;

// ---------------------------------------------------------------------------
// A18 Your orders
// ---------------------------------------------------------------------------

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const ScreenHeader('Your orders'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    if (app.active != null) ...[
                      ActiveOrderStrip(order: app.active!),
                      const SizedBox(height: 18),
                    ],
                    Text('Past orders', style: fred(20)),
                    const SizedBox(height: 10),
                    if (app.past.isEmpty)
                      Text('No orders yet.', style: dm(15, color: C.grey)),
                    for (final o in app.past) ...[
                      _PastOrderCard(order: o),
                      const SizedBox(height: 12),
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

class _PastOrderCard extends StatelessWidget {
  final PastOrder order;
  const _PastOrderCard({required this.order});

  Future<void> _rate(BuildContext context) async {
    var stars = 5;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text('How was it?', style: fred(22)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                order.title,
                textAlign: TextAlign.center,
                style: dm(14.5, color: C.grey),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (i) => GestureDetector(
                    onTap: () => setS(() => stars = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(
                        i < stars
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: C.yellow,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Later', style: dm(15, color: C.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                'Submit · +${Rules.ratingPoints} pts',
                style: dm(15, color: C.deep, weight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
    if (ok == true && !order.rated) {
      order.rated = true;
      Repo.rateOrder(order, stars);
      if (context.mounted) toast(context, 'Thanks! +${Rules.ratingPoints} pts added');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CardBox(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${order.date} · ${order.mode}',
                  style: dm(13.5, color: C.grey),
                ),
              ),
              Text(
                '+${order.pts} pts',
                style: dm(13.5, color: C.green, weight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              FoodTile(color: order.tile, size: 46, radius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  order.title,
                  style: dm(15, weight: FontWeight.w700, height: 1.3),
                ),
              ),
              const SizedBox(width: 8),
              Text(money(order.total), style: dm(16, weight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Btn(
                  'Order again',
                  style: BtnStyle.dark,
                  height: 44,
                  fontSize: 14.5,
                  onTap: () {
                    if (order.itemIds.isEmpty) {
                      toast(context, 'Reordering is available from the menu');
                      return;
                    }
                    for (final id in order.itemIds) {
                      app.add(itemById(id));
                    }
                    toast(
                      context,
                      'Added to your cart',
                      action: 'View cart',
                      onAction: () => push(context, const CartScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Btn(
                  order.rated ? 'Rated ★' : 'Rate · +${Rules.ratingPoints} pts',
                  style: BtnStyle.outline,
                  height: 44,
                  fontSize: 14.5,
                  onTap: order.rated ? null : () => _rate(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
