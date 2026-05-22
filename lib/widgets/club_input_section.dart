import 'package:flutter/material.dart';

class ClubInputSection extends StatefulWidget {
  final void Function(String name) onClubCreated;

  const ClubInputSection({super.key, required this.onClubCreated});

  @override
  State<ClubInputSection> createState() => _ClubInputSectionState();
}

class _ClubInputSectionState extends State<ClubInputSection> {
  final TextEditingController _controller = TextEditingController();

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    widget.onClubCreated(name);
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Create a New Club',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: const InputDecoration(
            labelText: 'Club name',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _controller.text.trim().isNotEmpty ? _submit : null,
          child: const Text('Create Club'),
        ),
      ],
    );
  }
}
