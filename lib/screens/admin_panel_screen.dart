import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_role.dart';

class AdminPanelScreen extends StatefulWidget {
  @override
  _AdminPanelScreenState createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  UserRoleModel? _currentUserRole;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      final userRole = await _authService.getCurrentUserRole();
      setState(() {
        _currentUserRole = userRole;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user role: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _changeUserRole(String userId, UserRole newRole) async {
    try {
      await _firestore.collection('user_roles').doc(userId).update({
        'role': newRole.toString().split('.').last,
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User role updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating role: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Admin Panel')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUserRole == null || !_currentUserRole!.isManager()) {
      return Scaffold(
        appBar: AppBar(title: Text('Access Denied')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.block, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Access Denied',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'You need manager privileges to access this panel.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // Admin status card
          Card(
            margin: EdgeInsets.all(16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.admin_panel_settings, color: Colors.blue, size: 32),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manager Access',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'You have administrative privileges',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // User management section
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User Management',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _firestore.collection('user_roles').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        }

                        final users = snapshot.data?.docs ?? [];

                        if (users.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('No users found'),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final userData = users[index].data() as Map<String, dynamic>;
                            final userRole = UserRoleModel.fromMap(userData);
                            final isCurrentUser = userRole.userId == FirebaseAuth.instance.currentUser?.uid;

                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: userRole.isManager() ? Colors.blue : Colors.grey,
                                  child: Icon(
                                    userRole.isManager() ? Icons.admin_panel_settings : Icons.person,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(userRole.email),
                                subtitle: Text(
                                  userRole.isManager() ? 'Manager' : 'Employee',
                                  style: TextStyle(
                                    color: userRole.isManager() ? Colors.blue : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                trailing: isCurrentUser 
                                  ? Text('You', style: TextStyle(color: Colors.grey))
                                  : PopupMenuButton<String>(
                                      onSelected: (value) {
                                        final newRole = value == 'manager' ? UserRole.manager : UserRole.employee;
                                        _changeUserRole(userRole.userId, newRole);
                                      },
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          value: 'employee',
                                          child: Text('Set as Employee'),
                                        ),
                                        PopupMenuItem(
                                          value: 'manager',
                                          child: Text('Set as Manager'),
                                        ),
                                      ],
                                    ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Security features info
          Card(
            margin: EdgeInsets.all(16),
            color: Colors.green[50],
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Security Features',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• AES-256 End-to-End Encryption\n'
                    '• Multi-Factor Authentication (MFA)\n'
                    '• Role-Based Access Control\n'
                    '• OAuth 2.0 Integration',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
