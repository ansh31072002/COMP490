import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../services/auth_service.dart';
import '../services/mfa_service.dart';
import '../models/user_role.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SignupFlowScreen extends StatefulWidget {
  final String email;
  final String password;
  final String name;
  final UserRole selectedRole;

  SignupFlowScreen({
    required this.email,
    required this.password,
    required this.name,
    required this.selectedRole,
  });

  @override
  _SignupFlowScreenState createState() => _SignupFlowScreenState();
}

class _SignupFlowScreenState extends State<SignupFlowScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _mfaCodeController = TextEditingController();
  
  bool _isLoading = false;
  String? _currentTOTPCode;
  String _currentStep = 'register'; // 'register', 'mfa_setup', 'mfa_verify'

  @override
  void initState() {
    super.initState();
    _startSignupFlow();
  }

  Future<void> _startSignupFlow() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authService.registerWithEmailAndPassword(
        widget.email,
        widget.password,
        widget.name,
      );

      if (user != null) {
        await _authService.setUserRole(user.uid, widget.selectedRole);
        
        setState(() {
          _currentStep = 'mfa_setup';
          _isLoading = false;
        });
        
        await Future.delayed(Duration(milliseconds: 500));
        await _setupMFA();
      } else {
        _showError('Registration failed. Please try again.');
      }
    } catch (e) {
      _showError('Registration error: $e');
    }
  }

  Future<void> _setupMFA() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showError('User not found. Please try again.');
        return;
      }
      
      print('Setting up MFA for user: ${user.uid}');
      
      // Setup MFA without timeout - just do it
      final success = await MFAService.setupMFAForUser(user.uid);
      
      if (success) {
        print('MFA setup successful, moving to verification');
        setState(() {
          _currentStep = 'mfa_verify';
        });
        await _getCurrentCode();
      } else {
        print('MFA setup failed - continuing anyway');
        // Continue to verification even if setup "failed"
        setState(() {
          _currentStep = 'mfa_verify';
        });
        await _getCurrentCode();
      }
    } catch (e) {
      print('MFA setup error: $e - continuing anyway');
      // Continue to verification even if there's an error
      setState(() {
        _currentStep = 'mfa_verify';
      });
      await _getCurrentCode();
    }
  }

  Future<void> _getCurrentCode() async {
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
      setState(() {
        _currentTOTPCode = '';
      });
    }
  }

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

  Future<void> _skipMFA() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (!mounted) return;
      // Signup successful - go to home automatically
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Complete Signup'),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            // Go back to login screen
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => LoginScreen()),
            );
          },
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: _getProgressValue(),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            
            SizedBox(height: 20),
            
            // Step content
            Expanded(
              child: _buildCurrentStep(),
            ),
          ],
        ),
      ),
    );
  }

  double _getProgressValue() {
    switch (_currentStep) {
      case 'register':
        return 0.33;
      case 'mfa_setup':
        return 0.66;
      case 'mfa_verify':
        return 1.0;
      default:
        return 0.0;
    }
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 'register':
        return _buildRegisterStep();
      case 'mfa_setup':
        return _buildMFASetupStep();
      case 'mfa_verify':
        return _buildMFAVerifyStep();
      default:
        return Container();
    }
  }

  Widget _buildRegisterStep() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isLoading) ...[
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Creating your account...'),
          ] else ...[
            Icon(Icons.person_add, size: 64, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'Setting up your account',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Please wait while we create your account...'),
          ],
        ],
      ),
    );
  }

  Widget _buildMFASetupStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.security, size: 64, color: Colors.green),
        SizedBox(height: 16),
        Text(
          'Setting up 2FA',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),
        Text(
          'Setting up security for your account...',
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20),
        if (_isLoading) ...[
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Setting up MFA...'),
        ] else ...[
          // Skip MFA button for testing
          TextButton(
            onPressed: _skipMFA,
            child: Text('Skip 2FA (for testing)'),
          ),
        ],
      ],
    );
  }

  Widget _buildMFAVerifyStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.verified_user, size: 64, color: Colors.orange),
        SizedBox(height: 16),
        Text(
          'Verify 2FA',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),
        Text(
          'Enter the 6-digit code:',
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
        
        SizedBox(height: 20),
        
        // Current TOTP code display (for testing)
        if (_currentTOTPCode != null) ...[
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
                    _currentTOTPCode!,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
        ],
        
        // Code input
        TextField(
          controller: _mfaCodeController,
          decoration: InputDecoration(
            labelText: 'Enter 6-digit code',
            border: OutlineInputBorder(),
            hintText: '123456',
          ),
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
        ),
        
        SizedBox(height: 20),
        
        // Verify button
        ElevatedButton(
          onPressed: _isLoading ? null : _verifyMFA,
          child: _isLoading 
            ? CircularProgressIndicator(color: Colors.white)
            : Text('Complete Signup'),
        ),
        
        SizedBox(height: 16),
        
        // Skip MFA button for testing
        TextButton(
          onPressed: _isLoading ? null : _skipMFA,
          child: Text('Skip for now'),
        ),
        
        SizedBox(height: 16),
        
        // Help text
        Card(
          color: Colors.grey[100],
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'How to get your code:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  '• Use the code above (for testing)\n'
                  '• Or use an authenticator app\n'
                  '• Code changes every 30 seconds',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mfaCodeController.dispose();
    super.dispose();
  }
}
