import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Quick diagnostic screen to test Firebase/Firestore connection
class FirebaseTestScreen extends StatefulWidget {
  const FirebaseTestScreen({super.key});

  @override
  State<FirebaseTestScreen> createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  String _status = 'Ready to test';
  bool _isTesting = false;
  final List<String> _logs = [];

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)} - $message');
    });
    print('[TEST] $message');
  }

  Future<void> _testFirebaseConnection() async {
    setState(() {
      _isTesting = true;
      _status = 'Testing...';
      _logs.clear();
    });

    try {
      _addLog('Starting Firebase connection test');
      
      // Test 1: Write a test document
      _addLog('Test 1: Writing test document...');
      final testRef = FirebaseFirestore.instance
          .collection('_test')
          .doc('connection_test');
      
      await testRef.set({
        'timestamp': FieldValue.serverTimestamp(),
        'test': true,
      }).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Write operation timed out after 10 seconds');
        },
      );
      _addLog('✓ Write test PASSED');

      // Test 2: Read the test document
      _addLog('Test 2: Reading test document...');
      final snapshot = await testRef.get().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Read operation timed out after 10 seconds');
        },
      );
      
      if (snapshot.exists) {
        _addLog('✓ Read test PASSED');
        _addLog('  Data: ${snapshot.data()}');
      } else {
        _addLog('✗ Read test FAILED: Document not found');
      }

      // Test 3: Write to tuitions collection
      _addLog('Test 3: Writing to tuitions collection...');
      final tuitionRef = await FirebaseFirestore.instance
          .collection('tuitions')
          .add({
            'name': 'TEST TUITION - DELETE ME',
            'days': ['Monday'],
            'studentCount': 1,
            'sessionCount': 0,
            'createdAt': DateTime.now(),
            'lastUpdated': DateTime.now(),
          })
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Tuition write timed out after 10 seconds');
        },
      );
      _addLog('✓ Tuitions write PASSED');
      _addLog('  Document ID: ${tuitionRef.id}');

      // Test 4: Delete the test tuition
      _addLog('Test 4: Deleting test tuition...');
      await tuitionRef.delete();
      _addLog('✓ Delete test PASSED');

      // Test 5: Delete test document
      await testRef.delete();
      _addLog('✓ Cleanup PASSED');

      setState(() {
        _status = '✓ ALL TESTS PASSED - Firebase is working!';
        _isTesting = false;
      });
    } catch (e, stackTrace) {
      _addLog('✗ TEST FAILED');
      _addLog('Error: $e');
      _addLog('Stack trace: $stackTrace');
      
      setState(() {
        _status = '✗ Tests failed - see logs';
        _isTesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Connection Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status card
            Card(
              color: _status.contains('PASSED')
                  ? Colors.green[50]
                  : _status.contains('failed')
                      ? Colors.red[50]
                      : Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      _status.contains('PASSED')
                          ? Icons.check_circle
                          : _status.contains('failed')
                              ? Icons.error
                              : Icons.info,
                      size: 48,
                      color: _status.contains('PASSED')
                          ? Colors.green
                          : _status.contains('failed')
                              ? Colors.red
                              : Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Test button
            ElevatedButton.icon(
              onPressed: _isTesting ? null : _testFirebaseConnection,
              icon: _isTesting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(_isTesting ? 'Testing...' : 'Run Tests'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),

            // Logs
            if (_logs.isNotEmpty)
              Expanded(
                child: Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Test Logs:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => setState(() => _logs.clear()),
                              icon: const Icon(Icons.clear, size: 16),
                              label: const Text('Clear'),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _logs.length,
                          itemBuilder: (context, index) {
                            final log = _logs[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                log,
                                style: TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 12,
                                  color: log.contains('✓')
                                      ? Colors.green[700]
                                      : log.contains('✗')
                                          ? Colors.red[700]
                                          : Colors.black87,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
