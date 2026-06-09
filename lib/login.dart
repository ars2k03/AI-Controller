import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  static const _storage = FlutterSecureStorage();
  static const _baseUrl = 'https://whatsapp-ai-assistant-ee5w.onrender.com';
  static const _timeout = Duration(seconds: 10);
  String? _apiKey;
  bool _obscureText = true;
  bool _isLoading = false;
  bool _isCheckingLogin = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkSavedLogin();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkSavedLogin() async {
    try {
      final key = await _storage.read(key: 'api_key');
      if (key != null && key.isNotEmpty && mounted) {
        _goToControlPage();
        return;
      }
    } catch (e) {
      debugPrint('Storage read error: $e');
    }

    if (mounted) {
      setState(() => _isCheckingLogin = false);
    }
  }

  void _goToControlPage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ControllerPage()),
    );
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _apiKey = _controller.text.trim();

      final response = await http
          .get(Uri.parse('$_baseUrl/status'),headers: {
            'x-api-key': _apiKey ?? '',
          })
          .timeout(_timeout);

      if (!mounted) return;

      if(response.statusCode == 200){
        await _storage.write(key: 'api_key', value: _apiKey);

        _goToControlPage();
      }else if(response.statusCode == 401 || response.statusCode == 403){
        setState(() {
          _errorMessage = 'Invalid API key. Please try again.';
        });
      }else{
        setState(() {
          _errorMessage = 'Failed to connect to server. Please try again.';
        });
      }

    } catch (e) {

      if (!mounted) return;

      setState(() {
        _errorMessage = 'Failed to save API key. Please try again.';
      });

      debugPrint('Login error: $e');

    } finally {

      if (mounted) setState(() => _isLoading = false);

    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingLogin) {
      return Scaffold(
        body: Center(
          child: Lottie.asset(
            "assets/lottiefiles/Sandy Loading.json",
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Login'),
        backgroundColor: const Color(0xFF5C6BC0),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5C6BC0).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      size: 40,
                      color: Color(0xFF5C6BC0),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'WhatsApp AI Controller',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    'Enter your API key to continue',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 32),

                  TextFormField(
                    controller: _controller,
                    obscureText: _obscureText,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'API Key',
                      hintText: 'Enter your API key',
                      prefixIcon: const Icon(Icons.vpn_key_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                        ),
                        onPressed: () {
                          setState(() => _obscureText = !_obscureText);
                        },
                        tooltip:
                        _obscureText ? 'Show Password' : 'Hide Password',
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'API key cannot be empty';
                      }
                      if (value.trim().length < 6) {
                        return 'API key must be at least 6 characters long';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _handleLogin(),
                  ),

                  const SizedBox(height: 16),

                  if (_errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red.shade700,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleLogin,
                    icon: _isLoading
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(Icons.login_rounded),
                    label: Text(
                      _isLoading ? 'Signing In...' : 'Sign In',
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shield_rounded,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Your key is stored securely in encrypted storage',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}