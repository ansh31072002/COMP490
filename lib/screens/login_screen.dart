import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/mfa_service.dart';
import '../services/mfa_session_service.dart';
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
  final _phoneController = TextEditingController();
  final _mfaCodeController = TextEditingController();
  
  bool _isLogin = true;
  bool _isLoading = false;
  bool _showMFA = false;
  String _mfaMethod = 'email'; // 'email' or 'sms'
  String _userEmail = '';
  String _userPhone = '';
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
                
                // Phone number field (only for registration)
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                    hintText: '+1234567890',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
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
              ],
              
              // MFA verification UI
              if (_showMFA) ...[
                Icon(Icons.security, size: 64, color: Colors.orange),
                SizedBox(height: 16),
                Text(
                  'Verify Your Identity',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                
                // MFA method selection
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _mfaMethod = 'email';
                        });
                        _sendMFACode();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _mfaMethod == 'email' ? Colors.blue : Colors.grey,
                      ),
                      child: Text('Email Code'),
                    ),
                    SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _mfaMethod = 'sms';
                        });
                        _sendMFACode();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _mfaMethod == 'sms' ? Colors.blue : Colors.grey,
                      ),
                      child: Text('SMS Code'),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                
                Text(
                  _mfaMethod == 'email' 
                    ? 'Check your email: $_userEmail\nWe sent you a verification code.'
                    : 'Check your phone: $_userPhone\nWe sent you a verification code.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                
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
          // Store user info for MFA
          _userEmail = _emailController.text;
          _userPhone = _phoneController.text.isNotEmpty ? _phoneController.text : '+1234567890';
          
          // Show MFA verification step
          setState(() {
            _showMFA = true;
            _isLoading = false;
          });
          
          // Send initial MFA code
          await _sendMFACode();
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Send MFA code based on selected method
  Future<void> _sendMFACode() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      bool sent = false;
      if (_mfaMethod == 'email') {
        sent = await MFAService.sendEmailMFA(_userEmail);
      } else {
        sent = await MFAService.sendSMSMFA(_userPhone);
      }
      
      if (sent) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Code sent successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send code. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error sending MFA code: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
      bool isValid = false;
      
      if (_mfaMethod == 'email') {
        isValid = MFAService.verifyEmailMFA(code);
      } else {
        isValid = MFAService.verifySMSMFA(code);
      }
      
      if (isValid) {
        // MFA verified - mark session as completed
        await MFASessionService.markMFACompleted();
        
        // Go to home automatically
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => HomeScreen()),
          (route) => false,
        );
      } else {
        if (MFAService.isCodeExpired()) {
          _showError('Code expired. Please request a new one.');
        } else {
          _showError('Wrong code. Please try again.');
        }
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
