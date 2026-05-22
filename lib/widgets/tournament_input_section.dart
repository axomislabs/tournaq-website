import 'package:flutter/material.dart';
import '../models/tournament_mode.dart';

class TournamentInputSection extends StatefulWidget {
  final Function(String name, TournamentMode mode) onTournamentCreated;

  const TournamentInputSection({super.key, required this.onTournamentCreated});

  @override
  State<TournamentInputSection> createState() => _TournamentInputSectionState();
}

class _TournamentInputSectionState extends State<TournamentInputSection> {
  final TextEditingController _controller = TextEditingController();
  TournamentModeType _selectedMode = TournamentModeType.league;

  void _createTournament() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    final mode = TournamentMode.fromType(_selectedMode);
    widget.onTournamentCreated(name, mode);
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
          'Create a New Tournament',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          decoration: const InputDecoration(
            labelText: 'Tournament name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        const Text('Mode'),
        const SizedBox(height: 8),
        DropdownButton<TournamentModeType>(
          value: _selectedMode,
          isExpanded: true,
          items: TournamentModeType.values.map((mode) {
            final displayName = TournamentMode.fromType(mode).displayName;
            return DropdownMenuItem(value: mode, child: Text(displayName));
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedMode = value;
              });
            }
          },
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _createTournament,
          child: const Text('Create Tournament'),
        ),
      ],
    );
  }
}
