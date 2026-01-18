import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/serverpod_provider.dart';
import '../providers/user_provider.dart';
import '../models/user.dart';
import 'package:project_thera_client/src/protocol/user/user.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _isLoading = false;
  bool _isLoginMode = true;
  bool _obscureText = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final service = ref.read(serverpodServiceProvider);
      await service.initialize();

      if (_isLoginMode) {
        UserModel? user = await service.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (user != null) ref.read(userProvider.notifier).setUser(user);
      } else {
        UserModel? user = await service.registerAndLogin(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          username: _nicknameController.text.trim().isNotEmpty
              ? _nicknameController.text.trim()
              : null,
        );
        ref.read(userProvider.notifier).setUser(user);
      }

      ref.invalidate(authUserProvider);
      ref.invalidate(isSignedInProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = _isLoginMode ? 'Login failed' : 'Sign up failed';

        // Extract the actual error message from the exception
        String errorString = e.toString();

        // Try to extract the message from Exception: message format
        if (errorString.contains('Exception: ')) {
          final match = RegExp(
            r'Exception:\s*(.+?)(?:\n|$)',
          ).firstMatch(errorString);
          if (match != null) {
            errorString = match.group(1) ?? errorString;
          }
        }

        // Remove "Exception: " prefix if present
        errorString = errorString.replaceFirst(RegExp(r'^Exception:\s*'), '');

        // Normalize for matching
        final lowerErrorString = errorString.toLowerCase();

        // Check for specific error types and provide user-friendly messages
        if (lowerErrorString.contains('already exists') ||
            lowerErrorString.contains('email already')) {
          errorMessage =
              'An account with this email already exists. Please login instead.';
        } else if (lowerErrorString.contains('invalid credentials') ||
            lowerErrorString.contains('wrong password') ||
            lowerErrorString.contains('invalid email') ||
            lowerErrorString.contains('authentication failed')) {
          errorMessage = 'Invalid email or password. Please try again.';
        } else if (lowerErrorString.contains('network') ||
            lowerErrorString.contains('connection') ||
            lowerErrorString.contains('socketexception') ||
            lowerErrorString.contains('failed host lookup')) {
          errorMessage =
              'Network error. Please check your connection and try again.';
        } else if (lowerErrorString.contains('timeout')) {
          errorMessage = 'Request timed out. Please try again.';
        } else {
          // Show the actual error message from the server
          errorMessage = errorString.trim();
          // Limit message length for snackbar
          if (errorMessage.length > 150) {
            errorMessage = '${errorMessage.substring(0, 147)}...';
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLoginMode ? 'Login' : 'Sign Up')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: Image.asset(
                      'images/appicon.jpg',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Icon(
                          Icons.error,
                          size: 56,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _isLoginMode ? 'Welcome Back' : 'Create Account',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLoginMode
                        ? 'Sign in to continue'
                        : 'Sign up to get started',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (!_isLoginMode) ...[
                    TextFormField(
                      controller: _nicknameController,
                      decoration: const InputDecoration(
                        labelText: 'Nickname',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a nickname';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscureText,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() => _obscureText = !_obscureText);
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isLoginMode ? 'Login' : 'Sign Up'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => setState(() => _isLoginMode = !_isLoginMode),
                    child: Text(
                      _isLoginMode
                          ? "Don't have an account? Sign Up"
                          : 'Already have an account? Login',
                    ),
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
