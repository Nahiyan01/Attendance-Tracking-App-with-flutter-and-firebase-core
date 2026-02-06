import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:attendence_app/models/tuition_model.dart';
import 'package:attendence_app/providers/tuition_provider.dart';
import 'package:intl/intl.dart';

/// Screen showing the complete session history for a tuition.
/// Displays all marked sessions with their dates (newest first).
/// Also provides reset functionality to clear all history.
class SessionHistoryScreen extends StatefulWidget {
  final TuitionModel tuition;

  const SessionHistoryScreen({super.key, required this.tuition});

  @override
  State<SessionHistoryScreen> createState() => _SessionHistoryScreenState();
}

class _SessionHistoryScreenState extends State<SessionHistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Load session history when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TuitionProvider>().loadSessionHistory(widget.tuition.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.tuition.name} - Session History'),
        elevation: 2,
        actions: [
          // Reset button in app bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () => _showResetConfirmation(context),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reset'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<TuitionProvider>(
        builder: (context, provider, child) {
          final sessions = provider.sessionHistory;

          // Show error if any
          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading history',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      provider.errorMessage!,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }

          // Show empty state
          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history, size: 80, color: Colors.grey),
                  const SizedBox(height: 24),
                  Text(
                    'No sessions yet',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mark a session to start tracking',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Show session history (newest first)
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              return _buildSessionItem(context, index + 1, session.date);
            },
          );
        },
      ),
    );
  }

  // ============================================================================
  // UI BUILDER METHODS
  // ============================================================================

  /// Build a session history item
  Widget _buildSessionItem(
    BuildContext context,
    int sessionNumber,
    DateTime date,
  ) {
    final formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(date);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Session number badge
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '#$sessionNumber',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Date information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Session $sessionNumber',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),

            // Check icon
            const Icon(Icons.check_circle, color: Colors.green, size: 28),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // DIALOG METHODS
  // ============================================================================

  /// Show confirmation dialog before resetting
  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Sessions?'),
        content: const Text(
          'This will set the session count to 0 and delete all session history. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleReset(context);
            },
            child: const Text('Reset', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  /// Handle reset action
  void _handleReset(BuildContext context) async {
    final provider = context.read<TuitionProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final success = await provider.resetTuition(widget.tuition.id);

    if (!mounted) return;

    if (success) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Sessions reset successfully'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to reset sessions'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
