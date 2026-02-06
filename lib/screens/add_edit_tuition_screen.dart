import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:attendence_app/models/tuition_model.dart';
import 'package:attendence_app/providers/tuition_provider.dart';

/// Screen for adding a new tuition or editing an existing one.
/// In add mode: all fields are empty
/// In edit mode: pre-populated with existing tuition data
class AddEditTuitionScreen extends StatefulWidget {
  final TuitionModel? tuition; // null = add mode, non-null = edit mode

  const AddEditTuitionScreen({super.key, this.tuition});

  @override
  State<AddEditTuitionScreen> createState() => _AddEditTuitionScreenState();
}

class _AddEditTuitionScreenState extends State<AddEditTuitionScreen> {
  late TextEditingController _nameController;
  late TextEditingController _studentCountController;
  late List<String> _selectedDays;
  bool _isSubmitting = false;

  // Days of the week available for selection
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
    _initializeForm();
  }

  /// Initialize form fields based on add/edit mode
  void _initializeForm() {
    if (widget.tuition != null) {
      // Edit mode: pre-populate with existing data
      _nameController = TextEditingController(text: widget.tuition!.name);
      _studentCountController = TextEditingController(
        text: widget.tuition!.studentCount.toString(),
      );
      _selectedDays = List.from(widget.tuition!.days);
    } else {
      // Add mode: empty fields
      _nameController = TextEditingController();
      _studentCountController = TextEditingController();
      _selectedDays = [];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _studentCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.tuition != null;
    final screenTitle = isEditMode ? 'Edit Tuition' : 'Add Tuition';

    return Scaffold(
      appBar: AppBar(title: Text(screenTitle), elevation: 2),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tuition Name field
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
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 24),

            // Days of week selector
            _buildSectionTitle(context, 'Days of Week'),
            const SizedBox(height: 8),
            _buildDaySelector(context),
            const SizedBox(height: 24),

            // Student count field
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
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 32),

            // Action buttons
            _buildActionButtons(context, isEditMode),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // UI BUILDER METHODS
  // ============================================================================

  /// Build section title with consistent styling
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  /// Build day of week multi-select picker
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
              backgroundColor: Colors.grey.shade200,
              selectedColor: Colors.blue.shade300,
              labelStyle: TextStyle(
                color: isSelected ? Colors.blue.shade900 : Colors.grey.shade800,
              ),
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

  /// Build action buttons (Cancel and Save)
  Widget _buildActionButtons(BuildContext context, bool isEditMode) {
    return Row(
      children: [
        // Cancel button
        Expanded(
          child: OutlinedButton(
            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 16),

        // Save button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isSubmitting
                ? null
                : () => _handleSave(context, isEditMode),
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(isEditMode ? 'Update' : 'Create'),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // FORM HANDLING
  // ============================================================================

  /// Validate form inputs
  String? _validateForm() {
    final name = _nameController.text.trim();
    final studentCountText = _studentCountController.text.trim();

    if (name.isEmpty) {
      return 'Please enter a tuition name';
    }

    if (_selectedDays.isEmpty) {
      return 'Please select at least one day';
    }

    if (studentCountText.isEmpty) {
      return 'Please enter number of students';
    }

    final studentCount = int.tryParse(studentCountText);
    if (studentCount == null || studentCount <= 0) {
      return 'Number of students must be a positive number';
    }

    return null; // No errors
  }

  /// Handle save action (add or update)
  void _handleSave(BuildContext context, bool isEditMode) async {
    // Validate form
    final validationError = _validateForm();
    if (validationError != null) {
      _showErrorDialog(context, validationError);
      return;
    }

    setState(() => _isSubmitting = true);

    final provider = context.read<TuitionProvider>();
    final name = _nameController.text.trim();
    final studentCount = int.parse(_studentCountController.text.trim());
    final days = _selectedDays;

    bool success;

    if (isEditMode) {
      // Edit mode: call updateTuition
      success = await provider.updateTuition(
        tuitionId: widget.tuition!.id,
        name: name,
        days: days,
        studentCount: studentCount,
      );
    } else {
      // Add mode: call addTuition
      success = await provider.addTuition(
        name: name,
        days: days,
        studentCount: studentCount,
      );
    }

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (success) {
      // Success: pop back to home screen
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditMode ? 'Tuition updated' : 'Tuition created'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      // Error: show error message
      _showErrorDialog(context, provider.errorMessage ?? 'An error occurred');
    }
  }

  /// Show error dialog
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
