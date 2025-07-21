import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:memory_pins_app/providers/pin_provider.dart';
import 'package:memory_pins_app/providers/tapu_provider.dart';
import 'package:memory_pins_app/providers/user_provider.dart';
import 'package:memory_pins_app/services/report_service.dart';

class DebugTestScreen extends StatefulWidget {
  const DebugTestScreen({Key? key}) : super(key: key);

  @override
  State<DebugTestScreen> createState() => _DebugTestScreenState();
}

class _DebugTestScreenState extends State<DebugTestScreen> {
  final ReportService _reportService = ReportService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131F2B),
      appBar: AppBar(
        title: const Text('Debug Test Screen'),
        backgroundColor: const Color(0xFF15212F),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Debug Test Controls',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Debug Info Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1D2B36),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current State:',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Consumer<PinProvider>(
                    builder: (context, pinProvider, child) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Pins: ${pinProvider.nearbyPins.length}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          Text(
                            'Filtered Pins: ${pinProvider.filteredPins.length}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          Text(
                            'Hidden Content Loaded: ${pinProvider.isInitialized}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Test Report Functionality
            const Text(
              'Test Report Functionality:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () => _testReportPin(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Test Report Pin',
                style: TextStyle(color: Colors.white),
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () => _testBlockUser(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Test Block User',
                style: TextStyle(color: Colors.white),
              ),
            ),

            const SizedBox(height: 20),

            // Clear Functions
            const Text(
              'Clear Hidden Content:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () => _clearAllHiddenContent(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Clear All Hidden Content',
                style: TextStyle(color: Colors.white),
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () => _clearReportedPins(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Clear Only Reported Pins',
                style: TextStyle(color: Colors.white),
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () => _clearBlockedUsers(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Clear Only Blocked Users',
                style: TextStyle(color: Colors.white),
              ),
            ),

            const SizedBox(height: 20),

            // Debug Functions
            const Text(
              'Debug Functions:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () => _debugFilteringState(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Debug Filtering State',
                style: TextStyle(color: Colors.white),
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () => _testFiltering(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Test Filtering Logic',
                style: TextStyle(color: Colors.white),
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () => _debugPinCreators(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Debug Pin Creators',
                style: TextStyle(color: Colors.white),
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () => _showHiddenContentSummary(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Show Hidden Content Summary',
                style: TextStyle(color: Colors.white),
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () => _forceRefreshHiddenContent(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Force Refresh Hidden Content',
                style: TextStyle(color: Colors.white),
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () => _showCurrentUserInfo(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Show Current User Info',
                style: TextStyle(color: Colors.white),
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () => _testUserScenarios(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Test User Scenarios',
                style: TextStyle(color: Colors.white),
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () => _checkHiddenContentStability(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lime,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Check Hidden Content Stability',
                style: TextStyle(color: Colors.white),
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () => _simulateUserLogin(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Simulate User Login (Fix Map Issue)',
                style: TextStyle(color: Colors.white),
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () => _checkTapuHiddenContentStability(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Check Tapu Hidden Content Stability',
                style: TextStyle(color: Colors.white),
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () => _simulateTapuUserLogin(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Simulate Tapu User Login (Fix Tapu Map Issue)',
                style: TextStyle(color: Colors.white),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Quick Fix Buttons:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () => _clearAllHiddenContent(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'CLEAR ALL HIDDEN CONTENT (FIX)',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () => _testLogoutLogin(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'TEST LOGOUT/LOGIN CACHE CLEARING',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _testReportPin() async {
    try {
      // Test reporting a specific pin
      final success = await _reportService.reportPin(
        reportedUserId: 'testUser123',
        reportedPinId: 'testPin123',
        reason: 'Test report',
        description: 'Testing report functionality',
      );

      if (success) {
        _showSnackBar('Test report created successfully', Colors.green);
        // Refresh the provider
        final pinProvider = Provider.of<PinProvider>(context, listen: false);
        await pinProvider.refreshHiddenContent();
      } else {
        _showSnackBar('Failed to create test report', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  void _testBlockUser() async {
    try {
      // Test blocking a specific user
      final success = await _reportService.blockUser(
        blockedUserId: 'testUser123',
        reason: 'Test block',
      );

      if (success) {
        _showSnackBar('Test block created successfully', Colors.green);
        // Refresh the provider
        final pinProvider = Provider.of<PinProvider>(context, listen: false);
        await pinProvider.refreshHiddenContent();
      } else {
        _showSnackBar('Failed to create test block', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  void _clearAllHiddenContent() async {
    try {
      final pinProvider = Provider.of<PinProvider>(context, listen: false);
      await pinProvider.clearAllHiddenContent();
      _showSnackBar('All hidden content cleared', Colors.green);
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  void _testLogoutLogin() async {
    try {
      _showSnackBar('Testing logout/login cache clearing...', Colors.blue);

      // Clear all provider caches
      final pinProvider = Provider.of<PinProvider>(context, listen: false);
      final tapuProvider = Provider.of<TapuProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      await pinProvider.clearAllCaches();
      await tapuProvider.clearAllCaches();
      userProvider.clearUserData();

      _showSnackBar(
          'All caches cleared! Now log out and log in as different user',
          Colors.green);

      // Show instructions
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF15212F),
          title: const Text(
            'Cache Clearing Test',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'All caches have been cleared!\n\n'
            'Now:\n'
            '1. Log out of current user\n'
            '2. Log in as a different user\n'
            '3. Check if hidden content is properly cleared\n'
            '4. Test reporting/blocking with the new user',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  void _clearReportedPins() async {
    try {
      final pinProvider = Provider.of<PinProvider>(context, listen: false);
      await pinProvider.clearReportedPins();
      _showSnackBar('Reported pins cleared', Colors.green);
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  void _clearBlockedUsers() async {
    try {
      final pinProvider = Provider.of<PinProvider>(context, listen: false);
      await pinProvider.clearBlockedUsers();
      _showSnackBar('Blocked users cleared', Colors.green);
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  void _debugFilteringState() {
    final pinProvider = Provider.of<PinProvider>(context, listen: false);
    pinProvider.debugDetailedFilteringState();
    _showSnackBar('Check console for debug info', Colors.blue);
  }

  void _testFiltering() {
    final pinProvider = Provider.of<PinProvider>(context, listen: false);
    pinProvider.testFiltering();
    _showSnackBar('Check console for filtering test', Colors.blue);
  }

  void _debugPinCreators() {
    final pinProvider = Provider.of<PinProvider>(context, listen: false);
    pinProvider.debugPinCreators();
    _showSnackBar('Check console for pin creators info', Colors.blue);
  }

  void _showHiddenContentSummary() async {
    try {
      final summary = await _reportService.getHiddenContentSummary();

      final message = '''
Hidden Content Summary:
- Reported Pins: ${summary['reportedPins']?.length ?? 0}
- Blocked Users: ${summary['blockedUsers']?.length ?? 0}
- Total Hidden Content: ${summary['totalHiddenContent'] ?? 0}

Reported Pin IDs: ${summary['reportedPins'] ?? []}
Blocked User IDs: ${summary['blockedUsers'] ?? []}
''';

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF15212F),
          title: const Text(
            'Hidden Content Summary',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  void _forceRefreshHiddenContent() async {
    try {
      final pinProvider = Provider.of<PinProvider>(context, listen: false);
      await pinProvider.forceRefreshHiddenContent();
      _showSnackBar('Hidden content force refreshed', Colors.green);
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  void _showCurrentUserInfo() {
    try {
      final userInfo = _reportService.getCurrentUserInfo();

      final message = '''
Current User Info:
- UID: ${userInfo['uid'] ?? 'null'}
- Email: ${userInfo['email'] ?? 'null'}
- Display Name: ${userInfo['displayName'] ?? 'null'}
- Is Anonymous: ${userInfo['isAnonymous'] ?? 'null'}
- Email Verified: ${userInfo['emailVerified'] ?? 'null'}
''';

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF15212F),
          title: const Text(
            'Current User Info',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  void _testUserScenarios() async {
    try {
      final scenarios = await _reportService.testUserScenarios();

      final message = '''
User Scenarios Test:
- Current User ID: ${scenarios['currentUserId'] ?? 'null'}
- Hidden Content Count: ${scenarios['hiddenContentCount'] ?? 0}
- Hidden Pins: ${scenarios['hiddenPins'] ?? []}
- Hidden Users: ${scenarios['hiddenUsers'] ?? []}

Pin Creators:
${(scenarios['pinCreators'] as Map<String, String>?)?.entries.map((e) => '  - ${e.key}: ${e.value}').join('\n') ?? 'No pins found'}
''';

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF15212F),
          title: const Text(
            'User Scenarios Test',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  void _checkHiddenContentStability() {
    try {
      final pinProvider = Provider.of<PinProvider>(context, listen: false);
      final summary = pinProvider.getHiddenContentSummary();

      final message = '''
Hidden Content Stability Check:
- Content Loaded: ${summary['loaded']}
- Hidden Pin Count: ${summary['hiddenPinCount']}
- Hidden User Count: ${summary['hiddenUserCount']}
- Is Stable: ${pinProvider.isHiddenContentStable}

Hidden Pin IDs: ${summary['hiddenPinIds']}
Hidden User IDs: ${summary['hiddenUserIds']}

Current State:
- Total Pins: ${pinProvider.nearbyPins.length}
- Filtered Pins: ${pinProvider.filteredPins.length}
- Is Initialized: ${pinProvider.isInitialized}
''';

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF15212F),
          title: const Text(
            'Hidden Content Stability',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  void _simulateUserLogin() async {
    try {
      _showSnackBar(
          'Simulating user login and fixing map issue...', Colors.blue);

      final pinProvider = Provider.of<PinProvider>(context, listen: false);

      // Force refresh hidden content (simulates login)
      await pinProvider.forceRefreshHiddenContent();

      // Check if hidden content is now stable
      final isStable = pinProvider.isHiddenContentStable;

      if (isStable) {
        _showSnackBar(
            'User login simulation successful! Map should now show correct pins.',
            Colors.green);

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF15212F),
            title: const Text(
              'Login Simulation Complete',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Hidden content has been refreshed!\n\n'
              'The map should now correctly show:\n'
              '✓ Only visible pins (not reported/blocked)\n'
              '✓ Proper filtering applied immediately\n'
              '✓ No need to click on pins to see correct content\n\n'
              'This fixes the issue where pins were showing incorrectly after login.',
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'OK',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        );
      } else {
        _showSnackBar(
            'Hidden content still not stable. Check console for errors.',
            Colors.orange);
      }
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  void _checkTapuHiddenContentStability() {
    try {
      final tapuProvider = Provider.of<TapuProvider>(context, listen: false);
      final summary = tapuProvider.getHiddenContentSummary();

      final message = '''
Tapu Hidden Content Stability Check:
- Content Loaded: ${summary['loaded']}
- Hidden Pin Count: ${summary['hiddenPinCount']}
- Hidden Tapu Count: ${summary['hiddenTapuCount']}
- Hidden User Count: ${summary['hiddenUserCount']}
- Is Stable: ${tapuProvider.isHiddenContentStable}

Hidden Pin IDs: ${summary['hiddenPinIds']}
Hidden Tapu IDs: ${summary['hiddenTapuIds']}
Hidden User IDs: ${summary['hiddenUserIds']}

Current State:
- Total Tapus: ${tapuProvider.nearbyTapus.length}
- Is Initialized: ${tapuProvider.isInitialized}
''';

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF15212F),
          title: const Text(
            'Tapu Hidden Content Stability',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  void _simulateTapuUserLogin() async {
    try {
      _showSnackBar('Simulating tapu user login and fixing tapu map issue...',
          Colors.blue);

      final tapuProvider = Provider.of<TapuProvider>(context, listen: false);

      // Force refresh hidden content (simulates login)
      await tapuProvider.forceRefreshHiddenContent();

      // Check if hidden content is now stable
      final isStable = tapuProvider.isHiddenContentStable;

      if (isStable) {
        _showSnackBar(
            'Tapu user login simulation successful! Tapu map should now show correct content.',
            Colors.green);

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF15212F),
            title: const Text(
              'Tapu Login Simulation Complete',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Tapu hidden content has been refreshed!\n\n'
              'The tapu map should now correctly show:\n'
              '✓ Only visible tapus (not reported/blocked)\n'
              '✓ Only visible pins within tapus (not reported/blocked)\n'
              '✓ Proper filtering applied immediately\n'
              '✓ No need to click on tapus to see correct content\n\n'
              'This fixes the issue where tapus and their pins were showing incorrectly after login.',
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'OK',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        );
      } else {
        _showSnackBar(
            'Tapu hidden content still not stable. Check console for errors.',
            Colors.orange);
      }
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
