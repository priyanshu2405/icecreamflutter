import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data.dart';
import '../services/api_client.dart';
import '../services/repo.dart';
import '../theme.dart';
import '../widgets.dart';
import 'shell.dart';

// ---------------------------------------------------------------------------
// A01 Splash
// ---------------------------------------------------------------------------

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _intro.dispose();
    _float.dispose();
    super.dispose();
  }

  Widget _sprinkle(double l, double t, Color c, double angle) => Positioned(
    left: l,
    top: t,
    child: AnimatedBuilder(
      animation: _float,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, math.sin(_float.value * math.pi) * 6),
        child: child,
      ),
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: 14,
          height: 4,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final logo = CurvedAnimation(parent: _intro, curve: Curves.elasticOut);
    final fade = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.35, 1, curve: Curves.easeOut),
    );
    return Scaffold(
      backgroundColor: C.pink,
      body: Stack(
        children: [
          Positioned(
            top: -size.width * 0.25,
            left: -size.width * 0.2,
            child: Blob(
              size.width * 0.75,
              Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            top: size.height * 0.27,
            right: -size.width * 0.3,
            child: Blob(size.width * 0.7, C.deep.withValues(alpha: 0.55)),
          ),
          _sprinkle(size.width * 0.15, size.height * 0.17, C.yellow, -0.5),
          _sprinkle(
            size.width * 0.78,
            size.height * 0.14,
            const Color(0xFF8FD3FF),
            -0.3,
          ),
          _sprinkle(size.width * 0.2, size.height * 0.6, Colors.white, 1.1),
          _sprinkle(size.width * 0.82, size.height * 0.66, C.yellow, 0.2),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipPath(
              clipper: const WaveTopClipper(amp: 46),
              child: Container(height: size.height * 0.25, color: C.cream),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),
                ScaleTransition(
                  scale: logo,
                  child: LogoStacked(width: math.min(size.width * 0.5, 220)),
                ),
                const SizedBox(height: 28),
                FadeTransition(
                  opacity: fade,
                  child: Column(
                    children: [
                      Text(
                        'Love at First Lick.',
                        style: script(32, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ice cream · Waffles · Bingsu · Shakes',
                        style: dm(15, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 4),
                FadeTransition(
                  opacity: fade,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                    child: Column(
                      children: [
                        Btn(
                          'Get started',
                          style: BtnStyle.dark,
                          onTap: () => push(context, const WelcomeScreen()),
                        ),
                        TextButton(
                          onPressed: () => push(context, const SignInScreen()),
                          child: Text(
                            'I already have an account',
                            style: dm(
                              15,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
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

// ---------------------------------------------------------------------------
// A02 Welcome / onboarding
// ---------------------------------------------------------------------------

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  final _pager = PageController();
  int _page = 0;
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    _pager.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < 2) {
      _pager.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOut,
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SignInScreen()),
      );
    }
  }

  Future<void> _allow() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Allow "Lick It" to use your location?',
          style: dm(17, weight: FontWeight.w700),
        ),
        content: Text(
          'We use your location to show your nearest store and send a deal when you\'re close by.',
          style: dm(14, color: C.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Don't allow", style: dm(15, color: C.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Allow',
              style: dm(15, color: C.deep, weight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (ok == true) toast(context, 'Location & alerts on. Sweet!');
    _next();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  const Logo(size: 52, shadow: false),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const SignInScreen()),
                    ),
                    child: Text(
                      'Skip',
                      style: dm(16, weight: FontWeight.w700, color: C.grey),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pager,
                onPageChanged: (p) => setState(() => _page = p),
                children: [
                  _OnboardPage(
                    art: _OrderArt(pulse: _pulse),
                    title: 'Skip the line, not the toppings',
                    body: 'Order ahead for pickup or delivery. Build it exactly how you like it and we\'ll have it ready.',
                  ),
                  _OnboardPage(
                    art: _RadarArt(pulse: _pulse),
                    title: 'Your nearest Lick It',
                    body: 'Turn on location to find your nearest store and fill in your delivery address. Turn on notifications to know when your order is ready.',
                  ),
                  _OnboardPage(
                    art: _BoothArt(pulse: _pulse),
                    title: 'Snap it. Share it. Earn it.',
                    body: 'Use our Photo Booth frames, share your treat and collect points towards free scoops.',
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _page ? 26 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _page ? C.deep : C.line,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: _page == 1
                  ? Column(
                      children: [
                        Btn('Allow location & alerts', onTap: _allow),
                        const SizedBox(height: 12),
                        Btn('Not now', style: BtnStyle.outline, onTap: _next),
                        const SizedBox(height: 10),
                        Text(
                          'You can change this any time in Profile › Notifications.',
                          style: dm(12, color: C.grey),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Btn(_page == 2 ? 'Let\'s go' : 'Next', onTap: _next),
                        const SizedBox(height: 12),
                        const SizedBox(height: 56 + 10 + 16),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  final Widget art;
  final String title;
  final String body;
  const _OnboardPage({
    required this.art,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: FittedBox(fit: BoxFit.scaleDown, child: art),
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: fred(32, height: 1.1),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            textAlign: TextAlign.center,
            style: dm(15.5, color: C.grey, height: 1.45),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

class _Callout extends StatelessWidget {
  final String title;
  final String sub;
  final bool dark;
  const _Callout(this.title, this.sub, {this.dark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: dark ? C.ink : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            title,
            style: dm(
              13.5,
              weight: FontWeight.w700,
              color: dark ? Colors.white : C.ink,
            ),
          ),
          Text(sub, style: dm(12.5, color: dark ? Colors.white70 : C.grey)),
        ],
      ),
    );
  }
}

class _RadarArt extends StatelessWidget {
  final Animation<double> pulse;
  const _RadarArt({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Blob(290, C.pink.withValues(alpha: 0.10)),
          AnimatedBuilder(
            animation: pulse,
            builder: (_, __) => Container(
              width: 120 + pulse.value * 170,
              height: 120 + pulse.value * 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: C.pink.withValues(alpha: 1 - pulse.value),
                  width: 2.5,
                ),
              ),
            ),
          ),
          Blob(130, C.pink.withValues(alpha: 0.2)),
          const Padding(
            padding: EdgeInsets.only(bottom: 18),
            child: MapPin(size: 64),
          ),
          const Positioned(
            left: 0,
            top: 36,
            child: _Callout('Nearest store', 'on the map'),
          ),
          const Positioned(
            right: 0,
            bottom: 66,
            child: _Callout('Order ready', "we'll let you know", dark: true),
          ),
        ],
      ),
    );
  }
}

class _OrderArt extends StatelessWidget {
  final Animation<double> pulse;
  const _OrderArt({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Blob(290, C.pink.withValues(alpha: 0.10)),
          AnimatedBuilder(
            animation: pulse,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, math.sin(pulse.value * 2 * math.pi) * 6),
              child: child,
            ),
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: C.pink,
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.icecream_rounded,
                color: Colors.white,
                size: 80,
              ),
            ),
          ),
          const Positioned(
            left: 0,
            top: 40,
            child: _Callout('Ready in 15 min', 'Pickup · City Pkwy'),
          ),
          const Positioned(
            right: 0,
            bottom: 50,
            child: _Callout('+20 pts', 'every order', dark: true),
          ),
        ],
      ),
    );
  }
}

class _BoothArt extends StatelessWidget {
  final Animation<double> pulse;
  const _BoothArt({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Blob(290, C.pink.withValues(alpha: 0.10)),
          Transform.rotate(
            angle: -0.08,
            child: Container(
              width: 160,
              height: 200,
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 34),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Image.asset(
                  'assets/images/booth.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            top: 40,
            child: _Callout('#LickItLove', 'share to earn'),
          ),
          Positioned(
            right: 0,
            bottom: 50,
            child: _Callout('+${Rules.photoPoints} pts', 'first share', dark: true),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// A03 Sign in
// ---------------------------------------------------------------------------

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _phone = TextEditingController();
  bool _email = false; // sign in with email instead of mobile (same as the website)

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  void _enterApp() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const Shell()),
      (_) => false,
    );
  }

  void _notYet() => toast(
    context,
    'Please sign in with your mobile number or email for now.',
  );

  Future<void> _sendCode() async {
    FocusScope.of(context).unfocus();
    final String identifier;
    final String shownTo;
    if (_email) {
      identifier = _phone.text.trim().toLowerCase();
      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(identifier)) {
        toast(context, 'Enter your email address first');
        return;
      }
      shownTo = identifier;
    } else {
      final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
      if (digits.length < 7) {
        toast(context, 'Enter your mobile number first');
        return;
      }
      identifier = '+1$digits';
      shownTo = '+1 ${_phone.text}';
    }
    try {
      await Repo.requestCode(identifier);
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message);
      return;
    }
    if (!mounted) return;
    final code = TextEditingController();
    final name = TextEditingController();
    showSheet(
      context,
      title: 'Enter your code',
      child: StatefulBuilder(
        builder: (ctx, setS) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'We sent a 4-digit code to $shownTo.',
              style: dm(15, color: C.grey),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: code,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              onChanged: (_) => setS(() {}),
              style: fred(34, spacing: 18),
              decoration: InputDecoration(
                counterText: '',
                hintText: '••••',
                hintStyle: fred(34, color: C.line, spacing: 18),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: C.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: C.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: C.deep, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const SizedBox(height: 10),
            TextField(
              controller: name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Your name (new customers)',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: C.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: C.line),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The code expires in 10 minutes.',
              textAlign: TextAlign.center,
              style: dm(12, color: C.grey),
            ),
            const SizedBox(height: 16),
            Btn(
              'Verify & continue',
              onTap: code.text.length == 4
                  ? () async {
                      try {
                        await Repo.verifyCode(
                          identifier,
                          code.text,
                          name: name.text,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        _enterApp();
                      } on ApiException catch (e) {
                        if (ctx.mounted) toast(ctx, e.message);
                      }
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipPath(
              clipper: const WaveBottomClipper(amp: 40),
              child: Container(
                height: top + 250,
                color: C.pink,
                child: Stack(
                  children: [
                    Positioned(
                      right: -60,
                      top: -40,
                      child: Blob(220, Colors.white.withValues(alpha: 0.12)),
                    ),
                    Positioned(
                      left: 8,
                      top: top + 4,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(
                          Icons.chevron_left_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                    Align(
                      alignment: const Alignment(0, 0.15),
                      child: Padding(
                        padding: EdgeInsets.only(top: top),
                        child: const LogoStacked(width: 112),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Welcome back', style: fred(32)),
                  const SizedBox(height: 6),
                  Text(
                    'Sign in to collect points and reorder your favourites.',
                    style: dm(15.5, color: C.grey, height: 1.4),
                  ),
                  const SizedBox(height: 22),
                  Text(_email ? 'Email' : 'Mobile number', style: dm(15, weight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (!_email) Container(
                        width: 52,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: C.line, width: 1.5),
                        ),
                        child: Text(
                          '+1',
                          style: dm(17, weight: FontWeight.w500),
                        ),
                      ),
                      if (!_email) const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _phone,
                          keyboardType: _email ? TextInputType.emailAddress : TextInputType.phone,
                          autocorrect: false,
                          style: dm(18),
                          decoration: InputDecoration(
                            hintText: _email ? 'you@example.com' : null,
                            hintStyle: dm(17, color: C.grey),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: C.deep,
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: C.deep,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Btn('Send me a code', onTap: _sendCode),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Expanded(child: Divider(color: C.line)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'or continue with',
                          style: dm(13, color: C.grey),
                        ),
                      ),
                      const Expanded(child: Divider(color: C.line)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Btn(
                          'Apple',
                          style: BtnStyle.outline,
                          height: 50,
                          fontSize: 15,
                          icon: Icons.apple,
                          onTap: _notYet,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Btn(
                          'Google',
                          style: BtnStyle.outline,
                          height: 50,
                          fontSize: 15,
                          onTap: _notYet,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Btn(
                          _email ? 'Phone' : 'Email',
                          style: BtnStyle.outline,
                          height: 50,
                          fontSize: 15,
                          onTap: () => setState(() {
                            _email = !_email;
                            _phone.clear();
                          }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: C.ink,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: C.yellow,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.star_rounded, color: C.ink),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'New here? ',
                                  style: dm(
                                    14.5,
                                    color: Colors.white,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Sign up and get a free scoop plus double points on your first app order.',
                                  style: dm(14.5, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: _enterApp,
                      child: Text(
                        'Browse as guest',
                        style: dm(
                          15,
                          color: C.grey,
                          weight: FontWeight.w700,
                        ),
                      ),
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
}
