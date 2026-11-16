import 'package:flutter/material.dart';

import '../data.dart';
import '../services/api_client.dart';
import '../services/repo.dart';
import '../theme.dart';
import '../widgets.dart';

// ---------------------------------------------------------------------------
// Catering, cakes & parties: the website's "Request a quote" form.
// Requests land in the website admin under Catering enquiries.
// ---------------------------------------------------------------------------

class CateringScreen extends StatefulWidget {
  const CateringScreen({super.key});

  @override
  State<CateringScreen> createState() => _CateringScreenState();
}

class _CateringScreenState extends State<CateringScreen> {
  static const _events = ['Birthday', 'Corporate', 'Wedding', 'School / community'];
  static const _interests = ['Waffle cake', 'Scoop station', 'Party trays'];

  final _name = TextEditingController(text: app.fullName == 'Friend' ? '' : app.fullName);
  final _phone = TextEditingController(text: app.phone);
  final _guests = TextEditingController();
  final _message = TextEditingController();
  String? _event;
  String? _interest;
  DateTime? _date;
  bool _sending = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _guests.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date ?? now.add(const Duration(days: 3)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty) {
      toast(context, 'Please add your name and phone number.');
      return;
    }
    setState(() => _sending = true);
    try {
      final msg = await Repo.sendCatering(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        eventType: _event,
        date: _date,
        guests: int.tryParse(_guests.text.trim()),
        interestedIn: _interest,
        message: _message.text,
      );
      if (!mounted) return;
      Navigator.pop(context);
      toast(context, msg);
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  InputDecoration _box(String? hint) => InputDecoration(
    hintText: hint,
    hintStyle: dm(15, color: C.grey),
    counterText: '',
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: C.line, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: C.deep, width: 2),
    ),
  );

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(t, style: dm(14.5, weight: FontWeight.w700)),
  );

  @override
  Widget build(BuildContext context) {
    final d = _date;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ScreenHeader('Catering & parties'),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 24 + MediaQuery.of(context).padding.bottom),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: C.pink,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bring the waffle bar to your party.', style: fred(22, color: Colors.white, height: 1.15)),
                        const SizedBox(height: 6),
                        Text(
                          'Birthdays, office treats, baby showers and weddings. Pre-order a waffle cake, or book a live waffle and scoop station.',
                          style: dm(14, color: Colors.white, height: 1.4),
                        ),
                        const SizedBox(height: 14),
                        for (final o in const [
                          ('Waffle cakes', 'Layered for sharing'),
                          ('Scoop station', 'Staffed, on-site'),
                          ('Party trays', 'Mini pancakes & hugs'),
                        ])
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(o.$1, style: dm(14, color: Colors.white, weight: FontWeight.w700)),
                                Text(' · ${o.$2}', style: dm(14, color: Colors.white)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text('Request a quote', style: fred(22)),
                  ),
                  _label('Name'),
                  TextField(controller: _name, textCapitalization: TextCapitalization.words, style: dm(15.5), decoration: _box(null)),
                  _label('Phone'),
                  TextField(controller: _phone, keyboardType: TextInputType.phone, style: dm(15.5), decoration: _box(null)),
                  _label('Event type'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final e in _events)
                        PillChip(e, selected: _event == e, onTap: () => setState(() => _event = _event == e ? null : e)),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Date'),
                            InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: _pickDate,
                              child: InputDecorator(
                                decoration: _box(null),
                                child: Row(
                                  children: [
                                    const Icon(Icons.event_outlined, size: 18, color: C.grey),
                                    const SizedBox(width: 8),
                                    Text(
                                      d == null ? 'Pick a date' : '${d.day}/${d.month}/${d.year}',
                                      style: dm(15.5, color: d == null ? C.grey : C.ink),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 110,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Guests'),
                            TextField(
                              controller: _guests,
                              keyboardType: TextInputType.number,
                              maxLength: 4,
                              style: dm(15.5),
                              decoration: _box('e.g. 30'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  _label('Interested in'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final o in _interests)
                        PillChip(o, selected: _interest == o, onTap: () => setState(() => _interest = _interest == o ? null : o)),
                    ],
                  ),
                  _label('Anything else?'),
                  TextField(
                    controller: _message,
                    minLines: 3,
                    maxLines: 6,
                    maxLength: 1500,
                    textCapitalization: TextCapitalization.sentences,
                    style: dm(15.5),
                    decoration: _box('Theme, flavours, timing…'),
                  ),
                  const SizedBox(height: 18),
                  Btn(_sending ? 'Sending…' : 'Send request', onTap: _sending ? null : _send),
                  const SizedBox(height: 10),
                  Text(
                    "Waffle cakes need 48 hours' notice.",
                    textAlign: TextAlign.center,
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

/// Entry card for the catering form (Home and Stores).
class CateringCard extends StatelessWidget {
  const CateringCard({super.key});

  @override
  Widget build(BuildContext context) {
    return CardBox(
      onTap: () => push(context, const CateringScreen()),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(color: C.yellow, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.cake_outlined, color: C.ink),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Catering, cakes & parties', style: fred(17)),
                const SizedBox(height: 2),
                Text('Waffle cakes, scoop stations and party trays. Request a quote.', style: dm(13.5, color: C.grey, height: 1.3)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: C.grey),
        ],
      ),
    );
  }
}
