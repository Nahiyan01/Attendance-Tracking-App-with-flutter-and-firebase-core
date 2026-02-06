import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:attendence_app/providers/tuition_provider.dart';
import 'package:attendence_app/widgets/tuition_card.dart';
import 'add_tuition_screen.dart';
import 'edit_tuition_screen.dart';
import 'session_history_screen.dart';

/// Home screen: Displays list of all tuitions and allows adding new ones.
/// This is the main entry point of the app.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize tuitions stream on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TuitionProvider>().initializeTuitions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Tracker'), elevation: 2),
      body: Consumer<TuitionProvider>(
        builder: (context, provider, child) {
          // Show error message if any
          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      provider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: provider.clearErrorMessage,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Show loading indicator
          if (provider.isLoading && provider.tuitions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Show empty state
          if (provider.tuitions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.school_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No tuitions yet',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add a tuition to get started',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToAddTuition(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Tuition'),
                  ),
                ],
              ),
            );
          }

          // Show list of tuitions
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: provider.tuitions.length,
            itemBuilder: (context, index) {
              final tuition = provider.tuitions[index];
              return TuitionCard(
                tuition: tuition,
                onMarkSession: () => _markSession(context, tuition.id),
                onEdit: () => _navigateToEditTuition(context, tuition),
                onViewHistory: () =>
                    _navigateToSessionHistory(context, tuition),
                onDelete: () => _showDeleteConfirmation(context, tuition.id),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddTuition(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Tuition'),
      ),
    );
  }

  // ============================================================================
  // NAVIGATION & DIALOG METHODS
  // ============================================================================

  /// Navigate to Add Tuition screen
  void _navigateToAddTuition(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddTuitionScreen()),
    );
  }

  /// Navigate to Edit Tuition screen with existing tuition data
  void _navigateToEditTuition(BuildContext context, dynamic tuition) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTuitionScreen(tuition: tuition),
      ),
    );
  }

  /// Navigate to Session History screen
  void _navigateToSessionHistory(BuildContext context, dynamic tuition) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionHistoryScreen(tuition: tuition),
      ),
    );
  }

  /// Mark a session with loading feedback
  void _markSession(BuildContext context, String tuitionId) async {
    final provider = context.read<TuitionProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final success = await provider.markSession(tuitionId);

    if (!mounted) return;

    if (success) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Session marked successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to mark session'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Show confirmation dialog before deleting a tuition
  void _showDeleteConfirmation(BuildContext context, String tuitionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tuition?'),
        content: const Text(
          'This will permanently delete the tuition and all its session history. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTuition(context, tuitionId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Delete tuition with feedback
  void _deleteTuition(BuildContext context, String tuitionId) async {
    final provider = context.read<TuitionProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final success = await provider.deleteTuition(tuitionId);

    if (!mounted) return;

    if (success) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Tuition deleted'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to delete tuition'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
