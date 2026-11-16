import 'package:flutter/material.dart';

import '../data.dart';
import '../services/repo.dart';
import '../theme.dart';
import '../widgets.dart';

/// Allergen information, Privacy policy and Terms of service shown inside the app.
/// The text is the same one the website shows, edited in Admin > Settings > Website pages,
/// so a change there appears here the next time the page is opened.
class LegalPageScreen extends StatefulWidget {
  final String slug; // allergens | privacy | terms
  final String title;
  const LegalPageScreen({super.key, required this.slug, required this.title});

  @override
  State<LegalPageScreen> createState() => _LegalPageScreenState();
}

class _LegalPageScreenState extends State<LegalPageScreen> {
  List<({bool heading, String text})>? _blocks;
  String? _title;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final page = await Repo.legalPage(widget.slug);
      if (!mounted) return;
      setState(() {
        _title = page.title.isEmpty ? null : page.title;
        _blocks = page.blocks;
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final blocks = _blocks;
    // The page's own first heading repeats the title; skip it.
    final shown = blocks == null
        ? null
        : (blocks.isNotEmpty && blocks.first.heading && blocks.first.text.trim().toLowerCase() == (_title ?? widget.title).toLowerCase()
              ? blocks.sublist(1)
              : blocks);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(_title ?? widget.title, cart: false),
            Expanded(
              child: _failed
                  ? _error()
                  : shown == null
                  ? const Center(child: CircularProgressIndicator(color: C.deep))
                  : RefreshIndicator(
                      color: C.deep,
                      onRefresh: _load,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                        children: [
                          if (shown.isEmpty)
                            Text('Nothing here yet.', style: dm(15, color: C.grey))
                          else
                            for (final b in shown)
                              Padding(
                                padding: EdgeInsets.only(top: b.heading ? 18 : 0, bottom: b.heading ? 6 : 12),
                                child: Text(
                                  b.text,
                                  style: b.heading ? fred(19) : dm(15.5, color: C.ink, height: 1.5),
                                ),
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

  Widget _error() => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.wifi_off_rounded, size: 40, color: C.grey),
        const SizedBox(height: 12),
        Text("Couldn't load this page.", style: fred(18), textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text('Check your internet connection and try again.', style: dm(14, color: C.grey), textAlign: TextAlign.center),
        const SizedBox(height: 18),
        Btn('Try again', onTap: _load, expand: false, height: 48),
        if (Rules.siteUrl.isNotEmpty)
          TextButton(
            onPressed: () => openLink(context, Uri.parse('${Rules.siteUrl}${widget.slug}')),
            child: Text('Open on the website', style: dm(14, color: C.deep, weight: FontWeight.w700)),
          ),
      ],
    ),
  );
}
