import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:attendence_app/providers/tuition_provider.dart';

/// Screen for adding a new tuition - WITH COMPREHENSIVE DEBUGGING
class AddTuitionScreenDebug extends StatefulWidget {
  const AddTuitionScreenDebug({super.key});

  @override
  State<AddTuitionScreenDebug> createState() => _AddTuitionScreenDebugState();
}

class _AddTuitionScreenDebugState extends State<AddTuitionScreenDebug> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _studentCountController = TextEditingController();
  final List<String> _selectedDays = [];
  bool _isSubmitting = false;
  String _debugLog = '';

  static const List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  void _addDebugLog(String message) {
    setState(() {
      _debugLog += '${DateTime.now().toString().substring(11, 19)} - $message\n';
    });
    print('[DEBUG] $message');
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
      appBar: AppBar(title: const Text('Add Tuition (Debug Mode)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Debug log section
            if (_debugLog.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Debug Log:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () => setState(() => _debugLog = ''),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 150),
                      child: SingleChildScrollView(
                        child: Text(
                          _debugLog,
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

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
                        : () {
                            _addDebugLog('Cancel button pressed');
                            Navigator.pop(context);
                          },
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _handleSaveDebug,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Create'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

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
                    _addDebugLog('Added day: $day');
                  } else {
                    _selectedDays.remove(day);
                    _addDebugLog('Removed day: $day');
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red,
                  ),
            ),
          ),
      ],
    );
  }

  String? _validateForm() {
    _addDebugLog('Starting validation...');
    
    final name = _nameController.text.trim();
    final studentCountText = _studentCountController.text.trim();
    
    if (name.isEmpty) {
      _addDebugLog('Validation FAILED: Empty name');
      return 'Please enter a tuition name';
    }
    _addDebugLog('Name validation passed: $name');
    
    if (_selectedDays.isEmpty) {
      _addDebugLog('Validation FAILED: No days selected');
      return 'Please select at least one day';
    }
    _addDebugLog('Days validation passed: $_selectedDays');
    
    if (studentCountText.isEmpty) {
      _addDebugLog('Validation FAILED: Empty student count');
      return 'Please enter number of students';
    }
    
    final studentCount = int.tryParse(studentCountText);
    if (studentCount == null || studentCount <= 0) {
      _addDebugLog('Validation FAILED: Invalid student count');
      return 'Number of students must be a positive number';
    }
    _addDebugLog('Student count validation passed: $studentCount');
    
    _addDebugLog('✓ All validations passed!');
    return null;
  }

  void _handleSaveDebug() async {
    _addDebugLog('========================================');
    _addDebugLog('CREATE BUTTON PRESSED');
    _addDebugLog('========================================');
    
    // Validation
    final validationError = _validateForm();
    if (validationError != null) {
      _addDebugLog('Showing validation error dialog');
      _showErrorDialog(context, validationError);
      return;
    }

    _addDebugLog('Setting isSubmitting = true');
    setState(() => _isSubmitting = true);
    
    try {
      _addDebugLog('Getting TuitionProvider from context...');
      final provider = context.read<TuitionProvider>();
      _addDebugLog('Provider obtained successfully');
      
      final name = _nameController.text.trim();
      final studentCount = int.parse(_studentCountController.text.trim());
      final days = _selectedDays;
      
      _addDebugLog('Data prepared:');
      _addDebugLog('  - Name: $name');
      _addDebugLog('  - Days: $days');
      _addDebugLog('  - Student Count: $studentCount');
      
      _addDebugLog('Calling provider.addTuition()...');
      final stopwatch = Stopwatch()..start();
      
      final success = await provider.addTuition(
        name: name,
        days: days,
        studentCount: studentCount,
      );
      
      stopwatch.stop();
      _addDebugLog('addTuition() returned after ${stopwatch.elapsedMilliseconds}ms');
      _addDebugLog('Result: success=$success');
      
      if (!mounted) {
        _addDebugLog('Widget not mounted, returning');
        return;
      }
      
      _addDebugLog('Setting isSubmitting = false');
      setState(() => _isSubmitting = false);

      if (success) {
        _addDebugLog('SUCCESS! Closing screen...');
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tuition created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _addDebugLog('FAILED! Error: ${provider.errorMessage}');
        _showErrorDialog(
          context,
          provider.errorMessage ?? 'Unknown error occurred',
        );
      }
    } catch (e, stackTrace) {
      _addDebugLog('EXCEPTION CAUGHT: $e');
      _addDebugLog('Stack trace: $stackTrace');
      
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      
      _showErrorDialog(context, 'Exception: $e');
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    _addDebugLog('Showing error dialog: $message');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              _addDebugLog('Error dialog dismissed');
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
