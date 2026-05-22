import 'package:flutter/material.dart';

class TeamInputSection extends StatefulWidget {
  final Function(String) onTeamCreated;

  const TeamInputSection({
    super.key,
    required this.onTeamCreated,
  });

  @override
  State<TeamInputSection> createState() => _TeamInputSectionState();
}

class _TeamInputSectionState extends State<TeamInputSection> {
  final TextEditingController _controller = TextEditingController();

  void _addTeam() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    widget.onTeamCreated(name);
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
          'Create a New Team',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _addTeam(),
          decoration: const InputDecoration(
            labelText: 'Team name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _addTeam,
          child: const Text('Add Team'),
        ),
      ],
    );
  }
}
