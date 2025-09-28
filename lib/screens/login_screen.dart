import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/mfa_service.dart';
import '../models/user_role.dart';
import 'home_screen.dart';
import 'signup_flow_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _mfaCodeController = TextEditingController();
  
  bool _isLogin = true;
  bool _isLoading = false;
  bool _showMFA = false;
  String _currentTOTPCode = '';
  UserRole _selectedRole = UserRole.employee;
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_showMFA ? 'Verify 2FA' : 'SECURELY'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_showMFA) ...[
                // App title
                Text(
                  'SECURELY',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
              
              // Name field (only for registration)
              if (!_isLogin) ...[
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                
                // Role selection (simple dropdown)
                DropdownButtonFormField<UserRole>(
                  value: _selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: UserRole.employee,
                      child: Text('Employee'),
                    ),
                    DropdownMenuItem(
                      value: UserRole.manager,
                      child: Text('Manager'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value!;
                    });
                  },
                ),
                SizedBox(height: 16),
              ],
              
              // Email field
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              // Password field
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
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
              SizedBox(height: 24),
              
              // Login/Register button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleAuth,
                child: _isLoading 
                  ? CircularProgressIndicator() 
                  : Text(_isLogin ? 'Login' : 'Register'),
              ),
              SizedBox(height: 16),
              
              // Toggle between login and register
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                  });
                },
                child: Text(_isLogin ? 'Need an account? Register' : 'Have an account? Login'),
              ),
              
              SizedBox(height: 16),
              
              // Debug logout button
              TextButton(
                onPressed: () async {
                  await _authService.signOut();
                },
                child: Text('Force Logout (Debug)', style: TextStyle(color: Colors.red)),
              ),
              ],
              
              // MFA verification UI
              if (_showMFA) ...[
                Icon(Icons.security, size: 64, color: Colors.orange),
                SizedBox(height: 16),
                Text(
                  'Enter 2FA Code',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text(
                  'Enter the 6-digit code from your authenticator app:',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                
                // Current TOTP code display (for testing)
                if (_currentTOTPCode.isNotEmpty) ...[
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            'Current Code (for testing):',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(
                            _currentTOTPCode,
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                ],
                
                // MFA code input
                TextFormField(
                  controller: _mfaCodeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: '2FA Code',
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter the 6-digit code';
                    }
                    if (value.length != 6) {
                      return 'Code must be 6 digits';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                
                // Verify button
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyMFA,
                  child: _isLoading 
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Verify & Login'),
                ),
                
                SizedBox(height: 16),
                
                // Skip MFA button (for testing)
                TextButton(
                  onPressed: _isLoading ? null : _skipMFA,
                  child: Text('Skip 2FA (for testing)'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      User? user;
      if (_isLogin) {
        user = await _authService.signInWithEmailAndPassword(
          _emailController.text,
          _passwordController.text,
        );
      } else {
        // Navigate to signup flow with MFA setup
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SignupFlowScreen(
              email: _emailController.text,
              password: _passwordController.text,
              name: _nameController.text,
              selectedRole: _selectedRole,
            ),
          ),
        );
        return; // Don't continue with normal flow
      }

      if (user != null) {
        // Check if user has MFA enabled and show MFA step
        final hasMFA = await MFAService.hasMFAEnabled();
        if (hasMFA) {
          // Show MFA verification step
          setState(() {
            _showMFA = true;
            _isLoading = false;
          });
          await _getCurrentTOTPCode();
        } else {
          // Login successful - go to home automatically
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => HomeScreen()),
            (route) => false,
          );
        }
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Auth error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Get current TOTP code for display
  Future<void> _getCurrentTOTPCode() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
         final code = await MFAService.getCurrentTOTPCodeForUser(user.uid);
         setState(() {
           _currentTOTPCode = code ?? '';
         });
      }
    } catch (e) {
      print('Error getting TOTP code: $e');
    }
  }

  // Verify MFA code
  Future<void> _verifyMFA() async {
    final code = _mfaCodeController.text.trim();
    if (code.isEmpty) {
      _showError('Enter the code');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showError('Something went wrong');
        return;
      }
      
      final isValid = await MFAService.verifyTOTPForUser(user.uid, code);
      
      if (isValid) {
        // MFA verified - go to home automatically
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => HomeScreen()),
          (route) => false,
        );
      } else {
        _showError('Wrong code');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Skip MFA (for testing)
  Future<void> _skipMFA() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (!mounted) return;
      // MFA skipped - go to home automatically
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

}
