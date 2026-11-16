import 'package:flutter/material.dart';

import '../data.dart';
import '../services/api_client.dart';
import '../services/repo.dart';
import '../theme.dart';
import '../widgets.dart';

// ---------------------------------------------------------------------------
// A11 Rewards
// ---------------------------------------------------------------------------

class Reward {
  final String name;
  final int cost;
  final Color tile;
  final int? id;
  const Reward(this.name, this.cost, this.tile, [this.id]);
}

List<Reward> rewards = [
  Reward('Free topping', 100, Color(0xFFF1E6D6)),
  Reward('Free single scoop', 500, Color(0xFFFCE1EC)),
  Reward('Free signature shake', 750, Color(0xFFFFF0C2)),
  Reward('Free Lick It Signature waffle', 1500, Color(0xFFFCE1EC)),
];

class RewardsTab extends StatelessWidget {
  const RewardsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final nextGoal = 500;
        final toGo = (nextGoal - app.points).clamp(0, nextGoal);
        final progress = (app.points / nextGoal).clamp(0.0, 1.0);
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: top + 190,
                    child: Container(color: C.ink),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, top + 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Rewards',
                                style: fred(28, color: Colors.white),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => push(context, const WalletScreen()),
                              child: Text(
                                'Wallet ${money(app.wallet)}',
                                style: dm(
                                  15,
                                  color: const Color(0xFFFF7DB4),
                                  weight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: C.pink,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: C.pink.withValues(alpha: 0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                right: -40,
                                top: -40,
                                child: Blob(
                                  170,
                                  Colors.white.withValues(alpha: 0.18),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Lick it',
                                          style: script(
                                            24,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            app.points >= 1000
                                                ? 'WAFFLE TIER'
                                                : 'SCOOP TIER',
                                            style: dm(
                                              12,
                                              color: C.deep,
                                              weight: FontWeight.w700,
                                              spacing: 1.2,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${app.points}',
                                          style: fred(
                                            52,
                                            color: Colors.white,
                                            height: 1,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 6,
                                          ),
                                          child: Text(
                                            'pts',
                                            style: fred(
                                              20,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              toGo > 0
                                                  ? '$toGo pts to a'
                                                  : 'You\'ve unlocked a',
                                              style: dm(
                                                13,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              'free scoop',
                                              style: dm(
                                                13,
                                                color: Colors.white,
                                                weight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        minHeight: 9,
                                        color: C.yellow,
                                        backgroundColor: Colors.white
                                            .withValues(alpha: 0.35),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    const Barcode(),
                                  ],
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Ways to earn', style: fred(20)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _earn(
                          context,
                          '1/\$',
                          'Every order',
                          'Earn 1 point for every dollar you spend.',
                        ),
                        _earn(
                          context,
                          '+25',
                          'Photo booth',
                          'Snap your treat in the Photo Booth and share it.',
                        ),
                        _earn(
                          context,
                          '+15',
                          'Leave a review',
                          'Rate a past order from Your orders.',
                        ),
                        _earn(
                          context,
                          '+100',
                          'Invite a friend',
                          'They get a free scoop, you get 100 pts after their first order.',
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text('Redeem', style: fred(20)),
                    const SizedBox(height: 10),
                    for (final r in rewards) ...[
                      _rewardRow(context, r),
                      const SizedBox(height: 10),
                    ],
                    // Points history, same as the website's "Recent activity".
                    if (app.pointsHistory.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text('Recent activity', style: fred(20)),
                      const SizedBox(height: 10),
                      CardBox(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        child: Column(
                          children: [
                            for (final h in app.pointsHistory.take(8))
                              historyRow(h, (v) => '${v > 0 ? '+' : ''}${v.round()} pts'),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _earn(BuildContext context, String big, String label, String info) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: CardBox(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          onTap: () => showSheet(
            context,
            title: label,
            child: Text(info, style: dm(16, color: C.grey, height: 1.4)),
          ),
          child: Column(
            children: [
              Text(big, style: fred(20, color: C.deep)),
              const SizedBox(height: 2),
              SizedBox(
                height: 32,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: dm(11.5, height: 1.25),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rewardRow(BuildContext context, Reward r) {
    final can = app.points >= r.cost;
    return CardBox(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          FoodTile(color: r.tile, size: 58, radius: 14),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.name, style: dm(16, weight: FontWeight.w700)),
                Text('${r.cost} pts', style: dm(13, color: C.grey)),
              ],
            ),
          ),
          if (can)
            Btn(
              'Redeem',
              expand: false,
              height: 40,
              fontSize: 14,
              onTap: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: Colors.white,
                    title: Text('Redeem ${r.name}?', style: fred(20)),
                    content: Text(
                      'This uses ${r.cost} of your ${app.points} pts. You will get a code to show at the counter.',
                      style: dm(14.5, color: C.grey),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text('Cancel', style: dm(15, color: C.grey)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(
                          'Redeem',
                          style: dm(15, color: C.deep, weight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  try {
                    final code = await Repo.redeemReward(r);
                    if (context.mounted) {
                      toast(context, '${r.name} · show code $code at the counter 🎉');
                    }
                  } on ApiException catch (e) {
                    if (context.mounted) toast(context, e.message);
                  }
                }
              },
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1ECEE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${r.cost - app.points} to go',
                style: dm(13.5, color: C.grey, weight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// A12 Wallet
// ---------------------------------------------------------------------------

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  int _amount = 25;
  bool _auto = true;

  Map<int, int> get _bonus => app.packBonus;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const ScreenHeader('Wallet'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    Container(
                      height: 170,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: C.ink,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Stack(
                        children: [
                          const Positioned(
                            right: -30,
                            bottom: -50,
                            child: Blob(170, C.pink),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Lick It Wallet balance',
                                  style: dm(14, color: Colors.white70),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  money(app.wallet),
                                  style: fred(44, color: Colors.white),
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    Btn(
                                      'Pay in store',
                                      style: BtnStyle.blush,
                                      expand: false,
                                      height: 38,
                                      fontSize: 14,
                                      onTap: () => _payInStore(context),
                                    ),
                                    const SizedBox(width: 8),
                                    _outlineWhite(
                                      'History',
                                      () => _history(context),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text('Top up', style: fred(19)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        for (final a in app.packAmounts) ...[
                          if (a != 10) const SizedBox(width: 8),
                          Expanded(child: _amountTile(a)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    CardBox(
                      onTap: () => setState(() => _auto = !_auto),
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          PinkCheck(_auto),
                          const SizedBox(width: 12),
                          Text('Auto-reload \$25 below \$5', style: dm(15)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (!Rules.onlinePayments) ...[
                      Text(
                        'Online top-ups are paused right now. You can top up your wallet at the counter.',
                        style: dm(13, color: C.grey, height: 1.35),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Btn(
                      'Add \$$_amount',
                      onTap: !Rules.onlinePayments ? null : () async {
                        final b = _bonus[_amount] ?? 0;
                        try {
                          await Repo.topUp(_amount);
                          if (!context.mounted) return;
                          toast(
                            context,
                            b > 0
                                ? 'Added \$$_amount + $b bonus pts'
                                : 'Added \$$_amount to your wallet',
                          );
                        } on ApiException catch (e) {
                          if (context.mounted) toast(context, e.message);
                        }
                      },
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(child: Text('Gift cards', style: fred(19))),
                        GestureDetector(
                          onTap: () => _redeemCode(context),
                          child: Text(
                            'Redeem a code',
                            style: dm(
                              14,
                              color: C.deep,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 104,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _giftCard(
                            'Happy birthday!',
                            '\$25',
                            C.pink,
                            Colors.white,
                          ),
                          _giftCard(
                            'Treat yourself',
                            '\$10 – \$100',
                            C.yellow,
                            C.ink,
                          ),
                          _giftCard('Thank you!', '\$15', C.ink, Colors.white),
                          Dashed(
                            color: const Color(0xFFBDB2B6),
                            onTap: () => _sendGift(context),
                            child: const SizedBox(
                              width: 64,
                              height: 104,
                              child: Icon(Icons.add, color: C.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Btn(
                      'Send a gift card',
                      style: BtnStyle.outline,
                      onTap: () => _sendGift(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _outlineWhite(String t, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 1.6),
      ),
      child: Text(
        t,
        style: dm(14, color: Colors.white, weight: FontWeight.w700),
      ),
    ),
  );

  Widget _amountTile(int a) {
    final sel = _amount == a;
    final b = _bonus[a] ?? 0;
    return GestureDetector(
      onTap: () => setState(() => _amount = a),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 64,
        decoration: BoxDecoration(
          color: sel ? C.blush : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: sel ? C.deep : C.line,
            width: sel ? 2 : 1.4,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('\$$a', style: dm(17, weight: FontWeight.w700)),
            if (b > 0)
              Text(
                '+$b pts',
                style: dm(11, color: C.deep, weight: FontWeight.w700),
              ),
          ],
        ),
      ),
    );
  }

  Widget _giftCard(String title, String amount, Color bg, Color fg) => Padding(
    padding: const EdgeInsets.only(right: 10),
    child: GestureDetector(
      onTap: () => _sendGift(context, design: title),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: script(15, color: fg)),
            const Spacer(),
            Text(
              amount,
              style: dm(14, color: fg, weight: FontWeight.w700),
            ),
          ],
        ),
      ),
    ),
  );

  void _payInStore(BuildContext context) {
    showSheet(
      context,
      title: 'Scan to pay',
      child: Column(
        children: [
          Text(
            'Show this at the counter. Balance ${money(app.wallet)}.',
            style: dm(15, color: C.grey),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: C.pink,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Barcode(height: 90),
          ),
          const SizedBox(height: 12),
          Text(
            'Code refreshes every 60 seconds',
            style: dm(12.5, color: C.grey),
          ),
        ],
      ),
    );
  }

  void _history(BuildContext context) {
    final rows = app.walletHistory;
    showSheet(
      context,
      title: 'Wallet history',
      child: rows.isEmpty
          ? Text('No wallet activity yet.', style: dm(15, color: C.grey))
          : Column(
              children: [
                for (final h in rows.take(20))
                  historyRow(h, (v) => '${v >= 0 ? '+' : '−'}${money(v.abs())}'),
              ],
            ),
    );
  }

  void _redeemCode(BuildContext context) {
    final c = TextEditingController();
    showSheet(
      context,
      title: 'Redeem a code',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: c,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            style: dm(18, weight: FontWeight.w700, spacing: 2),
            decoration: InputDecoration(
              hintText: 'LICK-XXXX-XXXX',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: C.line),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Btn(
            'Redeem',
            onTap: () {
              Navigator.pop(context);
              toast(context, 'Gift cards are not available yet');
            },
          ),
        ],
      ),
    );
  }

  void _sendGift(BuildContext context, {String design = 'Happy birthday!'}) {
    showSheet(
      context,
      title: 'Send a gift card',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Design: $design', style: dm(15, color: C.grey)),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              labelText: "Friend's phone or email",
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final a in ['\$10', '\$25', '\$50'])
                PillChip(a, selected: a == '\$25'),
            ],
          ),
          const SizedBox(height: 16),
          Btn(
            'Send \$25 gift card',
            onTap: () {
              Navigator.pop(context);
              toast(context, 'Gift card sent! 🎁');
            },
          ),
        ],
      ),
    );
  }
}

/// One history line: date · what happened, and the amount (green when added).
Widget historyRow(HistoryLine h, String Function(double) fmt) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final d = h.date;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            d == null ? h.text : '${months[d.month - 1]} ${d.day} · ${h.text}',
            style: dm(14.5),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          fmt(h.amount),
          style: dm(14.5, weight: FontWeight.w700, color: h.amount > 0 ? C.green : C.ink),
        ),
      ],
    ),
  );
}
