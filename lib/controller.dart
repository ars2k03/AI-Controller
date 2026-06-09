import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'login.dart';

class ControllerPage extends StatefulWidget {
  const ControllerPage({super.key});

  @override
  State<ControllerPage> createState() => _ControllerPageState();
}

class _ControllerPageState extends State<ControllerPage> {
  static const _storage = FlutterSecureStorage();
  static const _baseUrl = 'https://whatsapp-ai-assistant-ee5w.onrender.com';
  static const _timeout = Duration(seconds: 10);

  String? _apiKey;
  bool _isEnabled = false;
  bool _isLoadingStatus = true;
  bool _isUpdating = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _apiKey = await _storage.read(key: 'api_key');
    await _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() {
      _isLoadingStatus = true;
      _errorMessage = null;
    });

    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/status'))
          .timeout(_timeout);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _isEnabled = data['aiEnabled'] as bool? ?? false;
        });
      } else {
        setState(() {
          _errorMessage =
          'Failed to load status (${response.statusCode})';
        });
      }
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _errorMessage =
        'Server did not respond in time. Please try again.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
        'Connection failed. Please check your internet connection.';
      });
      debugPrint('Load status error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingStatus = false);
    }
  }

  Future<void> _updateStatus(bool newValue) async {
    setState(() {
      _isUpdating = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final response = await http
          .post(
        Uri.parse('$_baseUrl/status'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey ?? '',
        },
        body: jsonEncode({'enabled': newValue}),
      )
          .timeout(_timeout);

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _isEnabled = newValue;
          _successMessage =
          newValue
              ? 'AI has been enabled successfully.'
              : 'AI has been disabled successfully.';
        });

        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _successMessage = null);
        });
      } else if (response.statusCode == 401 ||
          response.statusCode == 403) {
        setState(() {
          _errorMessage =
          'Invalid API key. Please log in again.';
        });
      } else {
        setState(() {
          _errorMessage =
          'Update failed (${response.statusCode}). Please try again.';
        });
      }
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _errorMessage =
        'Server did not respond in time.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
        'Connection failed. Please check your internet connection.';
      });
      debugPrint('Update status error: $e');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }


  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text(
          'Your API key will be removed and you will need to sign in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    await _storage.delete(key: 'api_key');

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WhatsApp AI Controller'),
        backgroundColor: const Color(0xFF5C6BC0),
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoadingStatus
            ? const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading status...'),
            ],
          ),
        )
            : RefreshIndicator(
          onRefresh: _loadStatus,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [

                if (_errorMessage != null)
                  _buildBanner(
                    message: _errorMessage!,
                    color: Colors.red,
                    icon: Icons.error_outline_rounded,
                    onDismiss: () =>
                        setState(() => _errorMessage = null),
                  ),


                if (_successMessage != null)
                  _buildBanner(
                    message: _successMessage!,
                    color: Colors.green,
                    icon: Icons.check_circle_outline_rounded,
                    onDismiss: () =>
                        setState(() => _successMessage = null),
                  ),

                const SizedBox(height: 16),


                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: Colors.grey.shade200,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [

                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: _isEnabled
                                ? const Color(0xFF5C6BC0).withOpacity(0.1)
                                : Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.smart_toy_rounded,
                            size: 56,
                            color: _isEnabled
                                ? const Color(0xFF5C6BC0)
                                : Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(height: 20),


                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _StatusBadge(
                            key: ValueKey(_isEnabled),
                            isEnabled: _isEnabled,
                          ),
                        ),
                        const SizedBox(height: 8),

                        Text(
                          _isEnabled
                              ? 'AI is automatically replying to WhatsApp messages'
                              : 'AI is disabled and not sending replies',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 28),

                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'AI Auto Reply',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            _isUpdating
                                ? const SizedBox(
                              width: 36,
                              height: 20,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                                : Switch.adaptive(
                              value: _isEnabled,
                              activeColor:
                              const Color(0xFF5C6BC0),
                              onChanged: _updateStatus,
                            ),
                          ],
                        ),
                        const Divider(height: 32),


                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _errorMessage != null
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _errorMessage != null
                                  ? 'Server Disconnected'
                                  : 'Server Connected',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Render.com',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Pull to refresh hint
                Text(
                  'Pull down to refresh',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBanner({
    required String message,
    required Color color,
    required IconData icon,
    required VoidCallback onDismiss,
  }) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: color, fontSize: 13),
              ),
            ),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(Icons.close_rounded, color: color, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

// Status badge আলাদা widget হিসেবে AnimatedSwitcher-এ ব্যবহারের জন্য
class _StatusBadge extends StatelessWidget {
  final bool isEnabled;

  const _StatusBadge({super.key, required this.isEnabled});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isEnabled
            ? Colors.green.shade50
            : Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isEnabled ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isEnabled
                ? Icons.check_circle_rounded
                : Icons.cancel_rounded,
            size: 16,
            color: isEnabled ? Colors.green.shade700 : Colors.red.shade700,
          ),
          const SizedBox(width: 6),
          Text(
            isEnabled ? 'AI Enabled' : 'AI Disabled',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color:
              isEnabled ? Colors.green.shade700 : Colors.red.shade700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}