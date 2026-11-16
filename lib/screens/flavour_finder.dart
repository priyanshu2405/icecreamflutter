import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data.dart';
import '../services/api_client.dart';
import '../services/repo.dart';
import '../theme.dart';
import '../widgets.dart';
import 'cart.dart';

// ---------------------------------------------------------------------------
// A17 Flavour Finder (scripted AI demo)
// ---------------------------------------------------------------------------

class _Pick {
  final String itemId;
  final int match;
  final String reason;
  const _Pick(this.itemId, this.match, this.reason);
}

const _picks = <String, List<_Pick>>{
  'Chocolatey': [
    _Pick(
      'signature',
      96,
      "Three chocolates & brownie crunch: you've ordered chocolate 6 of your last 8 visits.",
    ),
    _Pick(
      'rockyroad',
      91,
      'Oreo crunch, chocolate & almonds. Big texture, big cocoa.',
    ),
    _Pick(
      'oreo',
      88,
      'Cookies & cream shake with an Oreo crumb rim. Drinkable dessert.',
    ),
  ],
  'Fruity': [
    _Pick(
      'mango',
      94,
      'Alphonso mango piled on snow. You loved this on Nov 2.',
    ),
    _Pick(
      'cheesecake',
      90,
      'Berries, cheesecake bites & condensed milk. Bright and creamy.',
    ),
    _Pick(
      'strawberry',
      86,
      'Fresh strawberries & cotton candy, blended thick.',
    ),
  ],
  'Something new': [
    _Pick(
      'pista',
      89,
      'New this month: pistachio cream & kunafa crunch.',
    ),
    _Pick(
      'redvelvet',
      84,
      "Red velvet & white chocolate. You haven't tried it yet.",
    ),
    _Pick(
      'matchabingsu',
      82,
      'Ceremonial matcha, red bean & mochi. Earthy and not too sweet.',
    ),
  ],
  'Caffeine': [
    _Pick(
      'matcha',
      92,
      'Iced Matcha with oat milk: a gentle lift, light on sugar.',
    ),
    _Pick(
      'goldenhour',
      87,
      'Biscoff & caramel with a shot of espresso on request. 10% off nearby.',
    ),
  ],
  'Sharing': [
    _Pick(
      'cheesecake',
      93,
      'Bingsu is made to share: two spoons, one mountain of snow.',
    ),
    _Pick(
      'signature',
      90,
      'Our biggest waffle. Add two scoops and grab extra forks.',
    ),
  ],
};

class _Msg {
  final bool user;
  final String? text;
  final _Pick? pick;
  final bool typing;
  final bool chips;
  const _Msg({
    this.user = false,
    this.text,
    this.pick,
    this.typing = false,
    this.chips = false,
  });
}

class FlavourFinderScreen extends StatefulWidget {
  const FlavourFinderScreen({super.key});

  @override
  State<FlavourFinderScreen> createState() => _FlavourFinderScreenState();
}

class _FlavourFinderScreenState extends State<FlavourFinderScreen> {
  final _scroll = ScrollController();
  final _input = TextEditingController();
  late final List<_Msg> _msgs = [
    _Msg(text: 'Hi ${app.firstName}! What are you in the mood for tonight?'),
    const _Msg(chips: true),
  ];
  String _mood = '';
  int _idx = 0;
  bool _busy = false;
  List<_Pick> _list = const []; // picks for the current question

  @override
  void dispose() {
    _scroll.dispose();
    _input.dispose();
    super.dispose();
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _moodFromText(String t) {
    final s = t.toLowerCase();
    if (s.contains('choc') || s.contains('brownie') || s.contains('oreo')) {
      return 'Chocolatey';
    }
    if (s.contains('fruit') ||
        s.contains('mango') ||
        s.contains('berry') ||
        s.contains('fresh')) {
      return 'Fruity';
    }
    if (s.contains('coffee') ||
        s.contains('caffeine') ||
        s.contains('matcha') ||
        s.contains('awake')) {
      return 'Caffeine';
    }
    if (s.contains('share') || s.contains('friends') || s.contains('group')) {
      return 'Sharing';
    }
    return 'Something new';
  }

  /// Real picks from the live menu: the website's AI assistant when it's on,
  /// otherwise the server's keyword picks, otherwise the built-in ones.
  Future<(String, List<_Pick>)> _findPicks(String mood, String userText, bool noNuts) async {
    List<_Pick> fromServer(List<AiPick> ps) => [
      for (var i = 0; i < ps.length; i++)
        _Pick(ps[i].slug, math.max(70, 96 - i * 5), ps[i].reason.isNotEmpty ? ps[i].reason : itemById(ps[i].slug).desc),
    ];
    if (Rules.aiEnabled) {
      final r = await Repo.aiMenu(userText);
      if (r != null) return (r.message.isNotEmpty ? r.message : "Here's what I'd pick:", fromServer(r.picks));
    }
    if (Api.hasToken) {
      final ps = await Repo.flavourFinder(userText);
      if (ps.isNotEmpty) {
        return (noNuts ? "Got it, nut-free. Here's my top pick:" : "Here's my top pick from today's menu:", fromServer(ps));
      }
    }
    var list = _picks[mood]!;
    if (noNuts) {
      list = list.where((p) => p.itemId != 'pista' && p.itemId != 'rockyroad').toList();
      if (list.isEmpty) list = _picks['Fruity']!;
    }
    return (noNuts ? "Got it, nut-free. Here's my top pick:" : "Here's my top pick:", list);
  }

  Future<void> _ask(String mood, String userText) async {
    if (_busy) return;
    _busy = true;
    final noNuts = userText.toLowerCase().contains('nut');
    setState(() {
      _mood = mood;
      _idx = 0;
      _msgs.add(_Msg(user: true, text: userText));
      _msgs.add(const _Msg(typing: true));
    });
    _toBottom();
    final (intro, list) = await _findPicks(mood, userText, noNuts);
    if (!mounted) return;
    _list = list;
    setState(() {
      _msgs.removeLast();
      _msgs.add(_Msg(text: intro));
      _msgs.add(_Msg(pick: list.first));
    });
    _busy = false;
    _toBottom();
  }

  Future<void> _another() async {
    if (_busy || _mood.isEmpty) return;
    _busy = true;
    final list = _list.isNotEmpty ? _list : _picks[_mood]!;
    _idx = (_idx + 1) % list.length;
    setState(() {
      _msgs.add(const _Msg(user: true, text: 'Show me another'));
      _msgs.add(const _Msg(typing: true));
    });
    _toBottom();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _msgs.removeLast();
      _msgs.add(const _Msg(text: 'How about this one?'));
      _msgs.add(_Msg(pick: list[_idx]));
    });
    _busy = false;
    _toBottom();
  }

  void _send() {
    final t = _input.text.trim();
    if (t.isEmpty) return;
    _input.clear();
    FocusScope.of(context).unfocus();
    _ask(_moodFromText(t), t);
  }

  @override
  Widget build(BuildContext context) {
    final lastPickIndex = _msgs.lastIndexWhere((m) => m.pick != null);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(
              'Flavour Finder',
              subtitle: 'AI · LEARNS YOUR TASTE',
            ),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                itemCount: _msgs.length,
                itemBuilder: (context, i) {
                  final m = _msgs[i];
                  if (m.chips) return _chips();
                  if (m.typing) return _bubble(null, typing: true);
                  if (m.pick != null) {
                    return _pickCard(m.pick!, showActions: i == lastPickIndex);
                  }
                  return _bubble(m.text, user: m.user);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Container(
                padding: const EdgeInsets.only(left: 18, right: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: C.line, width: 1.5),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        onSubmitted: (_) => _send(),
                        textInputAction: TextInputAction.send,
                        style: dm(16),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Try: something fruity, no nuts',
                          hintStyle: dm(16, color: C.grey),
                        ),
                      ),
                    ),
                    CircleBtn(
                      icon: Icons.arrow_forward_rounded,
                      color: C.deep,
                      iconColor: Colors.white,
                      size: 44,
                      onTap: _send,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chips() {
    const moods = [
      'Chocolatey',
      'Fruity',
      'Something new',
      'Caffeine',
      'Sharing',
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final m in moods)
            PillChip(
              m,
              selected: _mood == m,
              fontSize: 14.5,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              onTap: () => _ask(m, '$m, please!'),
            ),
        ],
      ),
    );
  }

  Widget _bubble(String? text, {bool user = false, bool typing = false}) {
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: user ? C.ink : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: user ? null : Border.all(color: C.line, width: 1.3),
        ),
        child: typing
            ? const _TypingDots()
            : Text(
                text ?? '',
                style: dm(
                  15.5,
                  color: user ? Colors.white : C.ink,
                  height: 1.4,
                ),
              ),
      ),
    );
  }

  Widget _pickCard(_Pick p, {required bool showActions}) {
    final item = itemById(p.itemId);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: C.pink,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -30,
                  top: -30,
                  child: Blob(130, Colors.white.withValues(alpha: 0.15)),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      FoodTile(
                        color: Colors.white,
                        size: 92,
                        radius: 18,
                        icon: item.icon,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${p.match}% MATCH',
                              style: dm(
                                12,
                                color: Colors.white,
                                weight: FontWeight.w700,
                                spacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.name,
                              style: fred(21, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              p.reason,
                              style: dm(13, color: Colors.white, height: 1.35),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              money(item.price),
                              style: dm(
                                14,
                                color: Colors.white,
                                weight: FontWeight.w700,
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
          if (showActions) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Btn(
                    'Add to order',
                    style: BtnStyle.dark,
                    height: 50,
                    fontSize: 16,
                    onTap: () {
                      app.add(item);
                      toast(
                        context,
                        'Added ${item.name}',
                        action: 'View cart',
                        onAction: () => push(context, const CartScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Btn(
                    'Show another',
                    style: BtnStyle.outline,
                    height: 50,
                    fontSize: 16,
                    onTap: _another,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final v = ((_c.value * 3 - i) % 3);
          final up = v < 1 ? v : 0.0;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 8,
            height: 8,
            transform: Matrix4.translationValues(0, -4 * up, 0),
            decoration: BoxDecoration(
              color: C.grey.withValues(alpha: 0.4 + 0.6 * up),
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }
}
