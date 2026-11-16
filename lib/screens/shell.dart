import 'package:flutter/material.dart';

import '../data.dart';
import '../services/repo.dart';
import '../theme.dart';
import '../widgets.dart';
import 'home.dart';
import 'menu.dart';
import 'photo_booth.dart';
import 'profile.dart';
import 'rewards.dart';

/// Main tabbed app: Home, Menu, (camera), Rewards, Profile.
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Back from the background: pick up anything changed in the website admin.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) Repo.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => Scaffold(
        body: IndexedStack(
          index: app.tab,
          children: const [HomeTab(), MenuTab(), RewardsTab(), ProfileTab()],
        ),
        bottomNavigationBar: const BottomNav(),
      ),
    );
  }
}

class BottomNav extends StatelessWidget {
  const BottomNav({super.key});

  // Listens to the app state itself: as a const child of the Shell's builder it
  // would otherwise never rebuild, and the selected tab would never change.
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: app, builder: (context, _) => _bar(context));
  }

  Widget _bar(BuildContext context) {
    final inset = MediaQuery.of(context).padding.bottom;
    Widget item(int i, IconData icon, IconData active, String label) {
      final sel = app.tab == i;
      return Expanded(
        child: Semantics(
          button: true,
          selected: sel,
          label: '$label tab',
          excludeSemantics: true,
          child: Center(
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  app.setTab(i);
                  Repo.refresh();
                },
                splashColor: C.blush,
                highlightColor: C.blush.withValues(alpha: 0.5),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? C.blush : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(sel ? active : icon, color: sel ? C.deep : C.grey, size: 25),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          maxLines: 1,
                          style: dm(
                            11.5,
                            color: sel ? C.deep : C.grey,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 24 + 66 + inset,
      child: Stack(
        children: [
          Positioned(
            top: 24,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.only(bottom: inset),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: C.line, width: 1.2)),
              ),
              child: Row(
                children: [
                  item(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
                  item(1, Icons.menu_rounded, Icons.menu_rounded, 'Menu'),
                  const Expanded(child: SizedBox()),
                  item(
                    2,
                    Icons.star_border_rounded,
                    Icons.star_rounded,
                    'Rewards',
                  ),
                  item(
                    3,
                    Icons.person_outline_rounded,
                    Icons.person_rounded,
                    'Profile',
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => push(context, const PhotoBoothScreen()),
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: C.deep,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 5),
                    boxShadow: [
                      BoxShadow(
                        color: C.deep.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
