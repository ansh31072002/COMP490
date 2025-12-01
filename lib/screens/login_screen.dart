import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/mfa_service.dart';
import '../services/mfa_session_service.dart';
import '../models/user_role.dart';
import '../theme/app_theme.dart';
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
  String _mfaMethod = 'email';
  String _userEmail = '';
  String _userPhone = '';
  UserRole _selectedRole = UserRole.employee;
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(Icons.chat_bubble_outline, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Text(
              _showMFA ? 'Verify 2FA' : 'SECURELY',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.lightGray, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                // --------------------------
                // LOGIN / REGISTER SECTION
                // --------------------------
                if (!_showMFA) ...[
                  _buildTitleSection(),
                  if (!_isLogin) ...[
                    _buildNameField(),
                    SizedBox(height: 20),
                    _buildPhoneField(),
                    SizedBox(height: 20),
                    _buildRoleDropdown(),
                    SizedBox(height: 20),
                  ],
                  _buildEmailField(),
                  SizedBox(height: 20),
                  _buildPasswordField(),
                  SizedBox(height: 32),
                  _buildAuthButton(),
                  SizedBox(height: 16),
                  _buildToggleButton(),
                  SizedBox(height: 16),
                ],

                // --------------------------
                // MFA SECTION
                // --------------------------
                if (_showMFA) ...[
                  _buildMfaIntro(),
                  _buildMfaButtons(),
                  SizedBox(height: 20),
                  Text(
                    _mfaMethod == 'email'
                        ? 'Check your email: $_userEmail\nWe sent you a verification code.'
                        : 'Check your phone: $_userPhone\nWe sent you a verification code.',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  _buildMfaCodeField(),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _verifyMFA,
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('Verify & Login'),
                  ),
                  SizedBox(height: 16),
                  TextButton(
                    onPressed: _isLoading ? null : _skipMFA,
                    child: Text('Skip 2FA (for testing)'),
                  ),
                ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================
  // SUB-WIDGET BUILDERS
  // ===========================

  Widget _buildTitleSection() => Container(
        padding: EdgeInsets.all(32),
        margin: EdgeInsets.only(bottom: 32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, AppTheme.lightGray],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(Icons.chat_bubble_outline, color: Colors.white, size: 36),
            ),
            SizedBox(height: 20),
            Text(
              'SECURELY',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkSlate,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Secure Chat Application',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.mediumGray,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.accentCyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.accentCyan.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.security, color: AppTheme.accentCyan, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'End-to-End Encrypted',
                    style: TextStyle(
                      color: AppTheme.accentCyan,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildNameField() => _decoratedField(
        TextFormField(
          controller: _nameController,
          style: TextStyle(
            color: AppTheme.darkSlate,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          decoration: _inputDecoration('Full Name'),
          validator: (v) =>
              v == null || v.isEmpty ? 'Please enter your name' : null,
        ),
      );

  Widget _buildPhoneField() => _decoratedField(
        TextFormField(
          controller: _phoneController,
          style: TextStyle(
            color: AppTheme.darkSlate,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          decoration: _inputDecoration('Phone Number').copyWith(
            hintText: '+1234567890',
          ),
          validator: (v) =>
              v == null || v.isEmpty ? 'Please enter your phone number' : null,
        ),
      );

  Widget _buildRoleDropdown() => _decoratedField(
        DropdownButtonFormField<UserRole>(
          value: _selectedRole,
          decoration: _inputDecoration('Role'),
          items: [
            DropdownMenuItem(
                value: UserRole.employee, child: Text('Employee')),
            DropdownMenuItem(value: UserRole.manager, child: Text('Manager')),
          ],
          onChanged: (v) => setState(() => _selectedRole = v!),
        ),
      );

  Widget _buildEmailField() => _decoratedField(
        TextFormField(
          controller: _emailController,
          style: TextStyle(
            color: AppTheme.darkSlate,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          decoration: _inputDecoration('Email'),
          validator: (v) =>
              v == null || v.isEmpty ? 'Please enter your email' : null,
        ),
      );

  Widget _buildPasswordField() => _decoratedField(
        TextFormField(
          controller: _passwordController,
          obscureText: true,
          style: TextStyle(
            color: AppTheme.darkSlate,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          decoration: _inputDecoration('Password'),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Please enter your password';
            if (v.length < 6) return 'Password must be at least 6 characters';
            return null;
          },
        ),
      );

  Widget _buildAuthButton() => Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: _isLoading ? null : AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: _isLoading
              ? null
              : [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleAuth,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _isLoading ? AppTheme.mediumGray : Colors.transparent,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: _isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Processing...',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_isLogin ? Icons.login : Icons.person_add,
                        color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Text(
                      _isLogin ? 'Login' : 'Register',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
        ),
      );

  Widget _buildToggleButton() => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryPurple.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: TextButton(
          onPressed: () => setState(() => _isLogin = !_isLogin),
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            _isLogin ? 'Need an account? Register' : 'Have an account? Login',
            style: TextStyle(
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      );

  Widget _buildMfaIntro() => Container(
        padding: EdgeInsets.all(32),
        margin: EdgeInsets.only(bottom: 32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, AppTheme.lightGray],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppTheme.goldGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.security, color: Colors.white, size: 32),
            ),
            SizedBox(height: 16),
            Text('Verify Your Identity',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkSlate)),
            SizedBox(height: 8),
            Text('Choose your verification method',
                style: TextStyle(fontSize: 16, color: AppTheme.mediumGray)),
          ],
        ),
      );

  Widget _buildMfaButtons() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildMfaButton('email', Icons.email, AppTheme.primaryGradient),
          SizedBox(width: 16),
          _buildMfaButton('sms', Icons.sms, AppTheme.secondaryGradient),
        ],
      );

  Widget _buildMfaButton(String method, IconData icon, Gradient gradient) =>
      Container(
        decoration: BoxDecoration(
          gradient: _mfaMethod == method ? gradient : null,
          color: _mfaMethod == method ? null : AppTheme.lightGray,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            setState(() => _mfaMethod = method);
            _sendMFACode();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  color: _mfaMethod == method
                      ? Colors.white
                      : AppTheme.mediumGray),
              SizedBox(width: 8),
              Text(
                method == 'email' ? 'Email Code' : 'SMS Code',
                style: TextStyle(
                  color: _mfaMethod == method
                      ? Colors.white
                      : AppTheme.mediumGray,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildMfaCodeField() => TextFormField(
        controller: _mfaCodeController,
        keyboardType: TextInputType.number,
        maxLength: 6,
        decoration: InputDecoration(
          labelText: '2FA Code',
          border: OutlineInputBorder(),
          counterText: '',
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Enter the 6-digit code';
          if (value.length != 6) return 'Code must be 6 digits';
          return null;
        },
      );

  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppTheme.primaryBlue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
        ),
      );

  Widget _decoratedField(Widget child) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: child,
      );

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
