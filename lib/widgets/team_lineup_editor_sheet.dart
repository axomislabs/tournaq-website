import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import 'sheet_helpers.dart';

const _kGold     = AppColors.gold;
const _kGoldCream = AppColors.goldCream;
const _kOlive    = AppColors.olive;
const _kOliveLight = AppColors.oliveLight;

class TeamLineupEditorSheet extends StatefulWidget {
  final String teamName;
  final List<String> activeNames;
  final List<String> benchNames;
  final void Function(List<String> active, List<String> bench) onSave;

  const TeamLineupEditorSheet({
    super.key,
    required this.teamName,
    required this.activeNames,
    required this.benchNames,
    required this.onSave,
  });

  @override
  State<TeamLineupEditorSheet> createState() => _TeamLineupEditorSheetState();
}

class _TeamLineupEditorSheetState extends State<TeamLineupEditorSheet> {
  late List<String> _active;
  late List<String> _bench;
  late List<TextEditingController> _activeCtrs;
  late List<TextEditingController> _benchCtrs;
  int? _draggingBenchIndex;

  @override
  void initState() {
    super.initState();
    _active = List.from(widget.activeNames);
    _bench  = List.from(widget.benchNames);
    _activeCtrs = _active.map((n) => TextEditingController(text: n)).toList();
    _benchCtrs  = _bench.map((n) => TextEditingController(text: n)).toList();
  }

  @override
  void dispose() {
    for (final c in _activeCtrs) { c.dispose(); }
    for (final c in _benchCtrs)  { c.dispose(); }
    super.dispose();
  }

  void _save() {
    final active = List.generate(_activeCtrs.length, (i) {
      final t = _activeCtrs[i].text.trim();
      return t.isEmpty ? 'Player ${i + 1}' : t;
    });
    final bench = _benchCtrs.map((c) => c.text.trim()).toList();
    widget.onSave(active, bench);
    Navigator.of(context).pop();
  }

  void _reorderActive(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    setState(() {
      final name = _active.removeAt(oldIndex);
      _active.insert(newIndex, name);
      final ctr = _activeCtrs.removeAt(oldIndex);
      _activeCtrs.insert(newIndex, ctr);
    });
  }

  void _subBenchIntoActive(int benchIndex, int activeIndex) {
    setState(() {
      final benchName  = _benchCtrs[benchIndex].text.trim().isNotEmpty
          ? _benchCtrs[benchIndex].text.trim()
          : _bench[benchIndex];
      final activeName = _activeCtrs[activeIndex].text.trim().isNotEmpty
          ? _activeCtrs[activeIndex].text.trim()
          : _active[activeIndex];

      _active[activeIndex] = benchName;
      _activeCtrs[activeIndex].text = benchName;
      _bench[benchIndex]  = activeName;
      _benchCtrs[benchIndex].text = activeName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TournaQSheet(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const Divider(height: 1),
            _buildSectionLabel(
              label: 'IN',
              hint: 'Drag ≡ to set serve order',
              color: _kOlive,
              bg: _kOliveLight,
            ),
            _buildActiveList(),
            if (_bench.isNotEmpty) ...[
              _buildSectionLabel(
                label: 'OUT',
                hint: 'Long-press to drag into lineup',
                color: Colors.black45,
                bg: Colors.grey.shade100,
              ),
              _buildBenchList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(children: [
        Expanded(
          child: Text(
            widget.teamName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: _kGold,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  Widget _buildSectionLabel({
    required String label,
    required String hint,
    required Color color,
    required Color bg,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
          child: Text(
            label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ),
        const SizedBox(width: 8),
        Text(hint,
            style: const TextStyle(fontSize: 12, color: Colors.black38)),
      ]),
    );
  }

  Widget _buildActiveList() {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _active.length,
      proxyDecorator: (child, index, animation) => Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
        child: child,
      ),
      onReorder: _reorderActive,
      itemBuilder: (ctx, i) {
        final isFirst = i == 0;
        return DragTarget<int>(
          key: ValueKey('active_$i'),
          onAcceptWithDetails: (details) => _subBenchIntoActive(details.data, i),
          builder: (ctx, candidates, _) {
            final highlighted = candidates.isNotEmpty;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
              decoration: BoxDecoration(
                color: highlighted ? _kGoldCream : Colors.grey.shade50,
                border: Border.all(
                  color: highlighted ? _kGold : Colors.grey.shade200,
                  width: highlighted ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                // Position badge
                SizedBox(
                  width: 38,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isFirst ? _kGold : Colors.black38,
                        ),
                      ),
                      if (isFirst)
                        Icon(Icons.sports_volleyball_rounded,
                            size: 10, color: _kGold),
                    ],
                  ),
                ),
                // Editable name
                Expanded(
                  child: TextField(
                    controller: _activeCtrs[i],
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 13, horizontal: 4),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                // Drag handle (only this triggers reorder)
                ReorderableDragStartListener(
                  index: i,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Icon(Icons.drag_handle_rounded,
                        color: Colors.black26, size: 20),
                  ),
                ),
              ]),
            );
          },
        );
      },
    );
  }

  Widget _buildBenchList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _bench.length,
      itemBuilder: (ctx, i) {
        final isDragging = _draggingBenchIndex == i;
        return LongPressDraggable<int>(
          data: i,
          delay: const Duration(milliseconds: 300),
          onDragStarted: () => setState(() => _draggingBenchIndex = i),
          onDragEnd: (_)    => setState(() => _draggingBenchIndex = null),
          onDraggableCanceled: (_, _) => setState(() => _draggingBenchIndex = null),
          feedback: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: const BoxConstraints(minWidth: 200),
              decoration: BoxDecoration(
                border: Border.all(color: _kGold, width: 1.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.swap_vert_rounded,
                    size: 16, color: Colors.black38),
                const SizedBox(width: 8),
                Text(
                  _bench[i].isEmpty ? 'Player' : _bench[i],
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ]),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: _buildBenchRow(i, editable: false),
          ),
          child: isDragging
              ? _buildBenchRow(i, editable: false)
              : _buildBenchRow(i, editable: true),
        );
      },
    );
  }

  Widget _buildBenchRow(int i, {required bool editable}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        const SizedBox(width: 12),
        const Icon(Icons.swap_vert_rounded, size: 16, color: Colors.black26),
        const SizedBox(width: 8),
        Expanded(
          child: editable
              ? TextField(
                  controller: _benchCtrs[i],
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 13, horizontal: 4),
                  ),
                  style: const TextStyle(
                      fontSize: 14, color: Colors.black54),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 13, horizontal: 4),
                  child: Text(
                    _bench[i].isEmpty ? 'Player' : _bench[i],
                    style: const TextStyle(
                        fontSize: 14, color: Colors.black54),
                  ),
                ),
        ),
      ]),
    );
  }
}
