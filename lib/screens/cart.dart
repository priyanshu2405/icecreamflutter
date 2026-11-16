import 'package:flutter/material.dart';

import '../data.dart';
import '../services/api_client.dart';
import '../services/repo.dart';
import '../theme.dart';
import '../widgets.dart';
import 'home.dart' show showAddressSheet;
import 'stores.dart';
import 'tracking.dart';

// ---------------------------------------------------------------------------
// A07 Cart (pickup) / A07b Cart (delivery)
// ---------------------------------------------------------------------------

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  TimeOfDay? _scheduled;

  Future<void> _schedule() async {
    final now = TimeOfDay.now();
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: (now.hour + 1) % 24, minute: 0),
      helpText: 'Schedule for later',
    );
    if (t != null) setState(() => _scheduled = t);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final mode = app.mode;
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                const ScreenHeader('Your cart'),
                Expanded(
                  child: app.cart.isEmpty
                      ? _empty(context)
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                          children: [
                            _ModeSegment(mode: mode),
                            const SizedBox(height: 12),
                            _whereCard(context, mode),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                PillChip(
                                  switch (mode) {
                                    Mode.pickup => 'ASAP · ready ~15 min',
                                    Mode.delivery => 'ASAP · 30–40 min',
                                    Mode.dineIn => 'ASAP · to your table',
                                  },
                                  selected: _scheduled == null,
                                  fontSize: 13.5,
                                  onTap: () =>
                                      setState(() => _scheduled = null),
                                ),
                                PillChip(
                                  _scheduled == null
                                      ? 'Schedule for later'
                                      : 'Scheduled · ${_scheduled!.format(context)}',
                                  selected: _scheduled != null,
                                  fontSize: 13.5,
                                  onTap: _schedule,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            for (final l in app.cart) ...[
                              _CartLineCard(line: l),
                              const SizedBox(height: 12),
                            ],
                            if (!app.inCart('velvet'))
                              Material(
                                color: C.blush,
                                borderRadius: BorderRadius.circular(18),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () {
                                    app.add(itemById('velvet'));
                                    toast(
                                      context,
                                      'Added Vanilla Velvet Cloud',
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      children: [
                                        FoodTile(
                                          color: const Color(0xFFFFF4DA),
                                          size: 44,
                                          radius: 12,
                                          icon: Icons.icecream_outlined,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text.rich(
                                            TextSpan(
                                              style: dm(14.5),
                                              children: [
                                                const TextSpan(text: 'Add a '),
                                                TextSpan(
                                                  text: 'Vanilla Velvet Cloud',
                                                  style: dm(
                                                    14.5,
                                                    weight: FontWeight.w700,
                                                  ),
                                                ),
                                                const TextSpan(
                                                  text:
                                                      '? Pairs with chocolate.',
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '+ \$6.75',
                                          style: dm(
                                            15,
                                            color: C.deep,
                                            weight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),
                            Row2('Subtotal', money(app.subtotal)),
                            if (mode == Mode.delivery)
                              Row2('Delivery fee', money(app.deliveryFee)),
                            Row2(
                              "Points you'll earn",
                              '+${app.earnBeforePoints} pts',
                              style: dm(
                                15,
                                color: C.green,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
                if (app.cart.isNotEmpty)
                  _BottomBar(
                    child: Btn(
                      'Go to checkout',
                      trailing: money(app.subtotal + app.deliveryFee),
                      onTap: () =>
                          push(context, CheckoutScreen(scheduled: _scheduled)),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _empty(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: const BoxDecoration(
              color: C.blush,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.icecream_outlined, size: 52, color: C.deep),
          ),
          const SizedBox(height: 18),
          Text('Your cart is empty', style: fred(24)),
          const SizedBox(height: 6),
          Text(
            'Every great day starts with a scoop.',
            style: dm(15, color: C.grey),
          ),
          const SizedBox(height: 22),
          Btn(
            'Browse the menu',
            expand: false,
            onTap: () {
              app.setTab(1);
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
          ),
        ],
      ),
    ),
  );

  Widget _whereCard(BuildContext context, Mode mode) {
    final (title, sub) = switch (mode) {
      Mode.pickup => (
        'Pickup at ${app.storeShort}',
        app.store.address,
      ),
      Mode.delivery => (
        'Deliver to Home',
        app.addressLine,
      ),
      Mode.dineIn => ('Dine-in at ${app.storeShort}', 'Table 7 · we\'ll bring it over'),
    };
    return CardBox(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: C.blush,
              shape: BoxShape.circle,
            ),
            child: Icon(
              mode == Mode.dineIn
                  ? Icons.table_restaurant_outlined
                  : Icons.location_on_outlined,
              color: C.deep,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: dm(16, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(sub, style: dm(13, color: C.grey)),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              if (mode == Mode.delivery) {
                showAddressSheet(context);
              } else if (mode == Mode.pickup) {
                push(context, const StoresScreen());
              } else {
                toast(context, 'Scan the QR on your table to change it');
              }
            },
            child: Text(
              'Change',
              style: dm(15, color: C.deep, weight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeSegment extends StatelessWidget {
  final Mode mode;
  const _ModeSegment({required this.mode});

  @override
  Widget build(BuildContext context) {
    Widget seg(Mode m, String t, String s) {
      final sel = m == mode;
      return Expanded(
        child: GestureDetector(
          onTap: () => app.setMode(m),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: sel ? C.ink : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text(
                  t,
                  style: dm(
                    15,
                    weight: FontWeight.w700,
                    color: sel ? Colors.white : C.ink,
                  ),
                ),
                Text(s, style: dm(11.5, color: sel ? Colors.white70 : C.grey)),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: C.line, width: 1.2),
      ),
      child: Row(
        children: [
          seg(Mode.pickup, 'Pickup', '~15 min'),
          seg(Mode.delivery, 'Delivery', '30–40 min'),
          seg(Mode.dineIn, 'Dine-in', 'Order to table'),
        ],
      ),
    );
  }
}

class _CartLineCard extends StatelessWidget {
  final CartLine line;
  const _CartLineCard({required this.line});

  @override
  Widget build(BuildContext context) {
    return CardBox(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          FoodTile(color: line.item.tile, size: 70, icon: line.item.icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.item.name, style: dm(16, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  app.lineSubtitle(line),
                  maxLines: line.note == null ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: dm(12.5, color: C.grey, height: 1.3),
                ),
                const SizedBox(height: 4),
                Text(
                  money(app.lineTotal(line)),
                  style: dm(15, weight: FontWeight.w700),
                ),
              ],
            ),
          ),
          QtyStepper(
            qty: line.qty,
            onMinus: () => app.changeQty(line, -1),
            onPlus: () => app.changeQty(line, 1),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final Widget child;
  const _BottomBar({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// A08 Checkout
// ---------------------------------------------------------------------------

enum PayMethod { card, wallet, tap, gift }

class CheckoutScreen extends StatefulWidget {
  final TimeOfDay? scheduled;
  const CheckoutScreen({super.key, this.scheduled});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late int _pts = app.points >= 200 ? 200 : 0;
  PayMethod _pay = PayMethod.card;

  String _summary(BuildContext context) {
    final when = widget.scheduled == null
        ? switch (app.mode) {
            Mode.pickup => 'ASAP (~15 min)',
            Mode.delivery => 'ASAP (30–40 min)',
            Mode.dineIn => 'ASAP',
          }
        : widget.scheduled!.format(context);
    return switch (app.mode) {
      Mode.pickup => 'Pickup · ${app.storeShort} · $when',
      Mode.delivery => 'Delivery · Home · $when',
      Mode.dineIn => 'Dine-in · Table 7 · $when',
    };
  }

  Future<void> _place() async {
    final total = app.total(_pts);
    if (_pay == PayMethod.wallet && app.wallet < total) {
      toast(
        context,
        'Wallet has ${money(app.wallet)}. Try Split payment to cover the rest.',
      );
      return;
    }
    if (_pay == PayMethod.gift) {
      toast(context, 'Enter a gift card code first, or choose another method');
      return;
    }
    DateTime? when;
    final t = widget.scheduled;
    if (t != null) {
      final n = DateTime.now();
      when = DateTime(n.year, n.month, n.day, t.hour, t.minute);
      if (when.isBefore(n)) when = when.add(const Duration(days: 1));
    }
    await runPayment(
      context,
      ptsUsed: _pts,
      walletUsed: _pay == PayMethod.wallet ? total : 0,
      scheduledFor: when,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final total = app.total(_pts);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ScreenHeader('Checkout'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                children: [
                  CardBox(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _summary(context),
                            style: dm(14.5, weight: FontWeight.w500),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            'Edit',
                            style: dm(
                              15,
                              color: C.blue,
                              weight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: C.ink,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Use your points',
                                style: fred(19, color: Colors.white),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: C.yellow,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${app.points} pts',
                                style: dm(13.5, weight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            for (final p in [0, 100, 200, 400]) ...[
                              if (p != 0) const SizedBox(width: 8),
                              Expanded(child: _ptsTile(p)),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "100 pts = \$1.00 (proposed rate) · you'll still earn ${total.floor()} pts",
                          style: dm(12.5, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('Notes for the kitchen', style: fred(19)),
                  const SizedBox(height: 10),
                  TextFormField(
                    initialValue: app.orderNotes,
                    onChanged: (v) => app.orderNotes = v,
                    minLines: 1,
                    maxLines: 3,
                    maxLength: 500,
                    textCapitalization: TextCapitalization.sentences,
                    style: dm(15.5),
                    decoration: InputDecoration(
                      hintText: 'Optional, e.g. extra napkins please',
                      hintStyle: dm(15, color: C.grey),
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: C.line, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: C.deep, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('Pay with', style: fred(19)),
                  const SizedBox(height: 10),
                  CardBox(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _payRow(
                          PayMethod.card,
                          const MiniBadge('VISA', Color(0xFF1A1F71)),
                          'Visa •• 4821',
                          'Expires 08/29',
                        ),
                        const Divider(height: 1, color: C.line),
                        _payRow(
                          PayMethod.wallet,
                          const MiniBadge('LICK', C.pink),
                          'Lick It Wallet',
                          '${money(app.wallet)} balance',
                        ),
                        const Divider(height: 1, color: C.line),
                        _payRow(
                          PayMethod.tap,
                          const MiniBadge('PAY', C.ink),
                          isIOS ? 'Apple Pay' : 'Google Pay',
                          'Pay with one tap',
                        ),
                        const Divider(height: 1, color: C.line),
                        _payRow(
                          PayMethod.gift,
                          const MiniBadge('GIFT', C.waffle),
                          'Gift card',
                          'Add a code',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Dashed(
                    fill: C.blush,
                    onTap: () => push(context, SplitPayScreen(ptsUsed: _pts)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: C.deep,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.call_split_rounded,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Split payment',
                                  style: dm(15.5, weight: FontWeight.w700),
                                ),
                                Text(
                                  'Split across cards, wallet & points, or with friends',
                                  style: dm(13, color: C.grey),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row2('Subtotal', money(app.subtotal)),
                  if (app.mode == Mode.delivery)
                    Row2('Delivery fee', money(app.deliveryFee)),
                  if (_pts > 0)
                    Row2(
                      'Points ($_pts)',
                      '−${money(_pts / 100)}',
                      rightStyle: dm(
                        15,
                        color: C.green,
                        weight: FontWeight.w700,
                      ),
                    ),
                  Row2('GST (5%)', money(app.gst(_pts))),
                ],
              ),
            ),
            _BottomBar(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Total', style: fred(20))),
                      Text(money(total), style: fred(26)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Btn('Place order', onTap: _place),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ptsTile(int p) {
    final sel = _pts == p;
    final enabled = p <= app.points;
    return GestureDetector(
      onTap: enabled
          ? () => setState(() => _pts = p)
          : () => toast(context, 'You need $p pts for this'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFFF7DB4) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: sel ? const Color(0xFFFF7DB4) : Colors.white24,
            width: 1.5,
          ),
        ),
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: Column(
            children: [
              Text(
                p == 0 ? 'None' : '$p',
                style: dm(
                  15,
                  color: sel ? C.ink : Colors.white,
                  weight: FontWeight.w700,
                ),
              ),
              Text(
                p == 0 ? '\$0' : '−${money(p / 100)}',
                style: dm(11.5, color: sel ? C.ink : Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _payRow(PayMethod m, Widget badge, String title, String sub) {
    return InkWell(
      onTap: () => setState(() => _pay = m),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            badge,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: dm(15.5, weight: FontWeight.w700)),
                  Text(sub, style: dm(12.5, color: C.grey)),
                ],
              ),
            ),
            RadioDot(_pay == m),
          ],
        ),
      ),
    );
  }
}

/// Shows a short "processing" dialog, places the order and opens tracking.
Future<void> runPayment(
  BuildContext context, {
  required int ptsUsed,
  double walletUsed = 0,
  DateTime? scheduledFor,
}) async {
  final nav = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(color: C.deep, strokeWidth: 4),
            ),
            const SizedBox(height: 18),
            Text('Placing your order…', style: fred(19)),
            const SizedBox(height: 4),
            Text(
              'Sending it to the kitchen',
              style: dm(13.5, color: C.grey),
            ),
          ],
        ),
      ),
    ),
  );
  final ActiveOrder order;
  try {
    order = await Repo.placeOrder(
      ptsUsed: ptsUsed,
      walletUsed: walletUsed,
      scheduledFor: scheduledFor,
    );
  } on ApiException catch (e) {
    nav.pop(); // close dialog
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
    return;
  }
  nav.pop(); // close dialog
  nav.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => TrackingScreen(order: order)),
    (r) => r.isFirst,
  );
}

// ---------------------------------------------------------------------------
// A09 Split payment
// ---------------------------------------------------------------------------

class SplitPayScreen extends StatefulWidget {
  final int ptsUsed;
  const SplitPayScreen({super.key, required this.ptsUsed});

  @override
  State<SplitPayScreen> createState() => _SplitPayScreenState();
}

class _SplitPayScreenState extends State<SplitPayScreen> {
  bool _friends = false;
  final Set<String> _requested = {};

  @override
  Widget build(BuildContext context) {
    final total = app.total(widget.ptsUsed);
    final walletPart = round2(app.wallet.clamp(0.0, total));
    final cardPart = round2(total - walletPart);
    final share = round2(total / 3);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ScreenHeader('Split payment'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: C.pink,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order total',
                                style: dm(15, color: Colors.white),
                              ),
                              Text(
                                widget.ptsUsed > 0
                                    ? 'after ${widget.ptsUsed} pts · incl. GST'
                                    : 'incl. GST',
                                style: dm(12.5, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          money(total),
                          style: fred(32, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: C.line, width: 1.2),
                    ),
                    child: Row(
                      children: [
                        _seg(
                          'Cards, wallet & points',
                          !_friends,
                          () => setState(() => _friends = false),
                        ),
                        _seg(
                          'With friends',
                          _friends,
                          () => setState(() => _friends = true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (!_friends) ...[
                    Text(
                      'Use more than one way to pay. We charge the last method for whatever is left.',
                      style: dm(14, color: C.grey, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    _methodCard(
                      const MiniBadge('LICK', C.pink),
                      'Lick It Wallet',
                      'Balance ${money(app.wallet)} · use all',
                      walletPart,
                    ),
                    const SizedBox(height: 10),
                    _methodCard(
                      const MiniBadge('VISA', Color(0xFF1A1F71)),
                      'Visa •• 4821',
                      'Pays the remainder',
                      cardPart,
                    ),
                    const SizedBox(height: 10),
                    Dashed(
                      color: const Color(0xFFBDB2B6),
                      onTap: () =>
                          toast(context, 'Gift card / card entry opens here'),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 30,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFFBDB2B6),
                                ),
                              ),
                              child: const Icon(Icons.add, size: 18),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              'Add gift card or another card',
                              style: dm(15, weight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F4E8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '✓ Fully covered: ${money(walletPart)} + ${money(cardPart)} = ${money(total)}',
                        style: dm(
                          13.5,
                          color: C.green,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Send a request and everyone pays their share from their own Lick It app.',
                      style: dm(14, color: C.grey, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    _friendRow('You', 'PS', C.pink, share, me: true),
                    const SizedBox(height: 10),
                    _friendRow('Aman K.', 'AK', C.waffle, share),
                    const SizedBox(height: 10),
                    _friendRow(
                      'Neha R.',
                      'NR',
                      const Color(0xFF8FD3FF),
                      round2(total - share * 2),
                    ),
                    const SizedBox(height: 12),
                    Btn(
                      'Invite with a link',
                      style: BtnStyle.outline,
                      icon: Icons.link_rounded,
                      onTap: () =>
                          toast(context, 'Payment link copied to clipboard'),
                    ),
                  ],
                ],
              ),
            ),
            _BottomBar(
              child: Btn(
                _friends
                    ? 'Pay my share · ${money(share)}'
                    : 'Pay ${money(total)} · 2 methods',
                onTap: () {
                  if (_friends && _requested.length < 2) {
                    toast(context, 'Send requests to your friends first');
                    return;
                  }
                  runPayment(
                    context,
                    ptsUsed: widget.ptsUsed,
                    walletUsed: _friends ? 0 : walletPart,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _seg(String label, bool sel, VoidCallback onTap) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: sel ? C.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Text(
          label,
          style: dm(
            14,
            weight: FontWeight.w700,
            color: sel ? Colors.white : C.ink,
          ),
        ),
      ),
    ),
  );

  Widget _methodCard(Widget badge, String title, String sub, double amount) {
    return CardBox(
      border: C.deep,
      borderWidth: 2,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          badge,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: dm(15.5, weight: FontWeight.w700)),
                Text(sub, style: dm(12.5, color: C.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: C.line, width: 1.5),
            ),
            child: Text(money(amount), style: dm(16, weight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _friendRow(
    String name,
    String initials,
    Color color,
    double amount, {
    bool me = false,
  }) {
    final sent = _requested.contains(name);
    return CardBox(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color,
            child: Text(
              initials,
              style: dm(13, color: Colors.white, weight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: dm(15.5, weight: FontWeight.w700)),
                Text(money(amount), style: dm(13, color: C.grey)),
              ],
            ),
          ),
          if (!me)
            PillChip(
              sent ? 'Requested ✓' : 'Request',
              selected: sent,
              fontSize: 13,
              onTap: () => setState(() => _requested.add(name)),
            ),
        ],
      ),
    );
  }
}
