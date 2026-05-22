import 'package:flutter/material.dart';

import '../models/tournament_mode.dart';

class HybridModeGroupDialog extends StatefulWidget {
  final List<TournamentModeType> modeTypes;
  final Function(List<List<TournamentModeType>>) onConfirm;

  const HybridModeGroupDialog({
    super.key,
    required this.modeTypes,
    required this.onConfirm,
  });

  @override
  State<HybridModeGroupDialog> createState() => _HybridModeGroupDialogState();
}

class _HybridModeGroupDialogState extends State<HybridModeGroupDialog> {
  late List<TournamentModeType> _availableModes;
  late List<List<TournamentModeType>> _groupedModes;

  @override
  void initState() {
    super.initState();
    _availableModes = [...widget.modeTypes];
    _groupedModes = [];
  }

  void _createNewGroup() {
    setState(() {
      _groupedModes.add([]);
    });
  }

  void _removeGroup(int groupIndex) {
    setState(() {
      final modesInGroup = _groupedModes[groupIndex];
      _availableModes.addAll(modesInGroup);
      _groupedModes.removeAt(groupIndex);
    });
  }

  void _removeModeFromGroup(int groupIndex, int modeIndex) {
    setState(() {
      final mode = _groupedModes[groupIndex].removeAt(modeIndex);
      _availableModes.add(mode);
    });
  }

  void _confirm() {
    widget.onConfirm(_groupedModes);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configure Hybrid Mode'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Available Modes',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            if (_availableModes.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'All modes grouped',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Wrap(
                spacing: 8,
                children: _availableModes
                    .map(
                      (mode) => Draggable<TournamentModeType>(
                        data: mode,
                        feedback: Material(
                          color: Colors.transparent,
                          child: Chip(
                            label: Text(mode.name),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.4,
                          child: Chip(label: Text(mode.name)),
                        ),
                        child: Chip(label: Text(mode.name)),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mode Groups',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                ElevatedButton(
                  onPressed: _createNewGroup,
                  child: const Text('+ Add Group'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_groupedModes.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'No groups created yet. Create a group and drag modes into it.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              )
            else
              Column(
                children: List.generate(
                  _groupedModes.length,
                  (groupIndex) => Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Group ${groupIndex + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18),
                                onPressed: () => _removeGroup(groupIndex),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          DragTarget<TournamentModeType>(
                            onWillAcceptWithDetails: (_) => true,
                            onAcceptWithDetails: (details) {
                              final mode = details.data;
                              setState(() {
                                if (_availableModes.remove(mode)) {
                                  _groupedModes[groupIndex].add(mode);
                                }
                              });
                            },
                            builder: (context, candidateData, rejectedData) {
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: candidateData.isNotEmpty
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey[300]!,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: _groupedModes[groupIndex].isEmpty
                                    ? const Text(
                                        'Drag modes here',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      )
                                    : Wrap(
                                        spacing: 8,
                                        children: List.generate(
                                          _groupedModes[groupIndex].length,
                                          (modeIndex) {
                                            final mode =
                                                _groupedModes[groupIndex][modeIndex];
                                            return Chip(
                                              label: Text(mode.name),
                                              onDeleted: () =>
                                                  _removeModeFromGroup(
                                                    groupIndex,
                                                    modeIndex,
                                                  ),
                                            );
                                          },
                                        ),
                                      ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              'Tip: Drag modes from "Available Modes" into a group.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _confirm, child: const Text('Confirm')),
      ],
    );
  }
}
