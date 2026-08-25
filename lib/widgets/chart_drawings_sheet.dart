import 'package:flutter/material.dart';

import '../service/chart_drawing_store.dart';

Future<DrawingTool?> showChartDrawingsSheet(BuildContext context) {
  return showModalBottomSheet<DrawingTool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF121722),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (_) => const _DrawingsSheet(),
  );
}

class _DrawingsSheet extends StatefulWidget {
  const _DrawingsSheet();

  @override
  State<_DrawingsSheet> createState() => _DrawingsSheetState();
}

class _DrawingsSheetState extends State<_DrawingsSheet> {
  String _category = ChartDrawingCatalog.categories.first;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final items = ChartDrawingCatalog.tools.where((t) {
      final inCat = t.category == _category;
      final inQ = q.isEmpty || t.label.toLowerCase().contains(q) || t.category.toLowerCase().contains(q);
      return q.isEmpty ? inCat : inQ;
    }).toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.94,
      builder: (context, controller) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Drawings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF1C2434),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: ChartDrawingCatalog.categories.map((c) {
                    final on = c == _category && _query.isEmpty;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(c),
                        selected: on,
                        onSelected: (_) => setState(() {
                          _category = c;
                          _query = '';
                        }),
                        labelStyle: TextStyle(
                          color: on ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        selectedColor: const Color(0xFF2A3348),
                        backgroundColor: const Color(0xFF1C2434),
                        side: BorderSide.none,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: GridView.builder(
                  controller: controller,
                  itemCount: items.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.95,
                  ),
                  itemBuilder: (context, i) {
                    final tool = items[i];
                    final fav = tool.id == 'fib' || tool.id == 'rect';
                    return InkWell(
                      onTap: () => Navigator.pop(context, tool),
                      borderRadius: BorderRadius.circular(12),
                      child: Ink(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C2434),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(tool.icon, color: Colors.white, size: 28),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    child: Text(
                                      tool.label,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        height: 1.15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (fav)
                              const Positioned(
                                top: 6,
                                right: 6,
                                child: Icon(Icons.star, size: 12, color: Color(0xFFF59E0B)),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
