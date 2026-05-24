import 'package:flutter/material.dart';

import '../models/tournament_mode.dart';

class HybridModeSetupPage extends StatefulWidget {
  final List<TournamentModeType> modeTypes;
  final List<List<TournamentModeType>> initialGroups;

  const HybridModeSetupPage({
    super.key,
    required this.modeTypes,
    this.initialGroups = const [],
  });

  @override
  State<HybridModeSetupPage> createState() => _HybridModeSetupPageState();
}

class _HybridModeSetupPageState extends State<HybridModeSetupPage> {
  late List<TournamentModeType> _available;
  late List<List<TournamentModeType>> _groups;

  @override
  void initState() {
    super.initState();
    final used = widget.initialGroups.expand((g) => g).toSet();
    _available = widget.modeTypes.where((m) => !used.contains(m)).toList();
    _groups = widget.initialGroups.map((g) => [...g]).toList();
  }

  String _label(TournamentModeType t) => TournamentMode.fromType(t).displayName;

  void _addGroup() => setState(() => _groups.add([]));

  void _removeGroup(int i) => setState(() {
    _available.addAll(_groups.removeAt(i));
  });

  void _removeFromGroup(int gi, int mi) => setState(() {
    _available.add(_groups[gi].removeAt(mi));
  });

  void _addToGroup(TournamentModeType mode, int gi) {
    if (_available.remove(mode)) {
      setState(() => _groups[gi].add(mode));
    }
  }

  void _confirm() => Navigator.of(context).pop(_groups);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hybrid Mode Setup'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TextButton(
            onPressed: _confirm,
            child: const Text(
              'Done',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Available Modes ──────────────────────────────────────────────
          Row(children: [
            const Text('Available Modes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('${_available.length} remaining', style: const TextStyle(fontSize: 12, color: Colors.black45)),
          ]),
          const SizedBox(height: 4),
          const Text(
            'Long-press to drag into a group, or tap to add to the first group.',
            style: TextStyle(fontSize: 12, color: Colors.black45),
          ),
          const SizedBox(height: 12),
          _available.isEmpty
              ? _emptyBox('All modes assigned to groups.')
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _available.map((mode) => LongPressDraggable<TournamentModeType>(
                    data: mode,
                    delay: const Duration(milliseconds: 200),
                    feedback: Material(
                      color: Colors.transparent,
                      child: Chip(
                        label: Text(_label(mode)),
                        backgroundColor: const Color(0xFFD9A520),
                        labelStyle: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.3,
                      child: Chip(label: Text(_label(mode))),
                    ),
                    child: ActionChip(
                      label: Text(_label(mode)),
                      avatar: const Icon(Icons.add_rounded, size: 14),
                      onPressed: _groups.isEmpty
                          ? null
                          : () => _addToGroup(mode, 0),
                    ),
                  )).toList(),
                ),

          const SizedBox(height: 24),

          // ── Groups ──────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mode Groups', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _addGroup,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Group'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD9A520),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_groups.isEmpty)
            _emptyBox('Add a group above, then drag or tap modes into it.')
          else
            ...List.generate(_groups.length, _buildGroupCard),

          const SizedBox(height: 24),
          const Text(
            'Tip: Each group defines a round of play. Teams cycle through all mode groups.',
            style: TextStyle(fontSize: 12, color: Colors.black45),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(int gi) {
    final group = _groups[gi];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Container(
                width: 26, height: 26,
                decoration: const BoxDecoration(color: Color(0xFFFFF3CC), shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    '${gi + 1}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFD9A520)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('Group ${gi + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.black38),
                onPressed: () => _removeGroup(gi),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ]),
            const SizedBox(height: 8),
            DragTarget<TournamentModeType>(
              onWillAcceptWithDetails: (d) => !group.contains(d.data),
              onAcceptWithDetails: (d) => _addToGroup(d.data, gi),
              builder: (context, candidateData, _) {
                final isHovering = candidateData.isNotEmpty;
                final showEmpty = group.isEmpty && !isHovering;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(12),
                  constraints: const BoxConstraints(minHeight: 60),
                  decoration: BoxDecoration(
                    color: isHovering ? const Color(0xFFFFF3CC) : Colors.grey[50],
                    border: Border.all(
                      color: isHovering ? const Color(0xFFD9A520) : Colors.grey[300]!,
                      width: isHovering ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: showEmpty
                      ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.drag_indicator_rounded, size: 16, color: Colors.grey[400]),
                          const SizedBox(width: 6),
                          Text(
                            'Drag modes here',
                            style: TextStyle(color: Colors.grey[400], fontSize: 13),
                          ),
                        ])
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ...group.asMap().entries.map((e) => Chip(
                              label: Text(_label(e.value)),
                              backgroundColor: const Color(0xFFFFF3CC),
                              deleteIconColor: const Color(0xFFD9A520),
                              labelStyle: const TextStyle(fontSize: 13),
                              onDeleted: () => _removeFromGroup(gi, e.key),
                            )),
                            if (isHovering)
                              Opacity(
                                opacity: 0.5,
                                child: Chip(
                                  label: Text(_label(candidateData.first!)),
                                  backgroundColor: const Color(0xFFFFF3CC),
                                  labelStyle: const TextStyle(fontSize: 13),
                                ),
                              ),
                          ],
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyBox(String text) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.grey[200]!),
    ),
    child: Center(
      child: Text(text, style: const TextStyle(color: Colors.black45, fontSize: 13)),
    ),
  );
}
