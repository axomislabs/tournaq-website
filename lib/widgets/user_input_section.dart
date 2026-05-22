import 'package:flutter/material.dart';

import '../models/team.dart';

class UserInputSection extends StatefulWidget {
  final List<Team> teams;
  final void Function(String name, String? teamId) onUserCreated;

  const UserInputSection({
    super.key,
    required this.teams,
    required this.onUserCreated,
  });

  @override
  State<UserInputSection> createState() => _UserInputSectionState();
}

class _UserInputSectionState extends State<UserInputSection> {
  final TextEditingController _controller = TextEditingController();
  String? _selectedTeamId;

  void _createUser() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    widget.onUserCreated(name, _selectedTeamId);
    _controller.clear();
    setState(() {
      _selectedTeamId = null;
    });
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
          'Create a New User',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _createUser(),
          decoration: const InputDecoration(
            labelText: 'User name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String?>(
          initialValue: _selectedTeamId,
          decoration: const InputDecoration(
            labelText: 'Assign to team (optional)',
            border: OutlineInputBorder(),
          ),
          items: <DropdownMenuItem<String?>>[
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('No team'),
            ),
            ...widget.teams.map(
              (team) => DropdownMenuItem<String?>(
                value: team.id,
                child: Text(team.name),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedTeamId = value;
            });
          },
        ),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: _createUser, child: const Text('Add User')),
      ],
    );
  }
}
