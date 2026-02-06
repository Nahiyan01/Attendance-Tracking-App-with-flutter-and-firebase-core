import 'package:flutter/material.dart';
import 'package:attendence_app/models/tuition_model.dart';

/// Reusable widget that displays a tuition as a card.
/// Shows: name, days, student count, session count, and action buttons.
class TuitionCard extends StatelessWidget {
  final TuitionModel tuition;
  final VoidCallback onMarkSession;
  final VoidCallback onEdit;
  final VoidCallback onViewHistory;
  final VoidCallback onDelete;

  const TuitionCard({
    super.key,
    required this.tuition,
    required this.onMarkSession,
    required this.onEdit,
    required this.onViewHistory,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Tuition name and session count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    tuition.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${tuition.sessionCount} sessions',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Days of week
            Wrap(
              spacing: 8,
              children: tuition.days.map((day) {
                return Chip(
                  label: Text(day),
                  backgroundColor: Colors.grey.shade200,
                  labelStyle: const TextStyle(fontSize: 12),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Student count
            Text(
              'Students: ${tuition.studentCount}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            // Action buttons row
            Row(
              children: [
                // Mark Session button (primary)
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: onMarkSession,
                    icon: const Icon(Icons.add_circle),
                    label: const Text('Mark Session'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // More options menu
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                        break;
                      case 'history':
                        onViewHistory();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'history',
                      child: Row(
                        children: [
                          Icon(Icons.history, size: 18),
                          SizedBox(width: 8),
                          Text('History'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
