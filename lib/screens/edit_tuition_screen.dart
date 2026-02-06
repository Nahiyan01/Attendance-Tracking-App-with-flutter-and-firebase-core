import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:attendence_app/models/tuition_model.dart';
import 'package:attendence_app/providers/tuition_provider.dart';

/// Screen for editing an existing tuition.
class EditTuitionScreen extends StatefulWidget {
  final TuitionModel tuition;
  const EditTuitionScreen({super.key, required this.tuition});

  @override
  State<EditTuitionScreen> createState() => _EditTuitionScreenState();
}

class _EditTuitionScreenState extends State<EditTuitionScreen> {
  late TextEditingController _nameController;
  late TextEditingController _studentCountController;
  late List<String> _selectedDays;
  bool _isSubmitting = false;

  static const List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tuition.name);
    _studentCountController = TextEditingController(
      text: widget.tuition.studentCount.toString(),
    );
    _selectedDays = List.from(widget.tuition.days);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _studentCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Tuition')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, 'Tuition Name'),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'e.g., Math Class',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.school),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle(context, 'Days of Week'),
            const SizedBox(height: 8),
            _buildDaySelector(context),
            const SizedBox(height: 24),
            _buildSectionTitle(context, 'Number of Students'),
            const SizedBox(height: 8),
            TextField(
              controller: _studentCountController,
              decoration: InputDecoration(
                hintText: 'e.g., 15',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.people),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () => _handleSave(context),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Update'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) => Text(
    title,
    style: Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
  );

  Widget _buildDaySelector(BuildContext context) {
    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _daysOfWeek.map((day) {
            final isSelected = _selectedDays.contains(day);
            return FilterChip(
              label: Text(day),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedDays.add(day);
                  } else {
                    _selectedDays.remove(day);
                  }
                });
              },
            );
          }).toList(),
        ),
        if (_selectedDays.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Select at least one day',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.red),
            ),
          ),
      ],
    );
  }

  String? _validateForm() {
    final name = _nameController.text.trim();
    final studentCountText = _studentCountController.text.trim();
    if (name.isEmpty) return 'Please enter a tuition name';
    if (_selectedDays.isEmpty) return 'Please select at least one day';
    if (studentCountText.isEmpty) return 'Please enter number of students';
    final studentCount = int.tryParse(studentCountText);
    if (studentCount == null || studentCount <= 0) {
      return 'Number of students must be a positive number';
    }
    return null;
  }

  void _handleSave(BuildContext context) async {
    final validationError = _validateForm();
    if (validationError != null) {
      _showErrorDialog(context, validationError);
      return;
    }
    setState(() => _isSubmitting = true);
    final provider = context.read<TuitionProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final success = await provider.updateTuition(
      tuitionId: widget.tuition.id,
      name: _nameController.text.trim(),
      days: _selectedDays,
      studentCount: int.parse(_studentCountController.text.trim()),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (success) {
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Tuition updated'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      _showErrorDialog(
        navigator.context,
        provider.errorMessage ?? 'An error occurred',
      );
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
