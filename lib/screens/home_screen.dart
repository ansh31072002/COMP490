import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';
import 'admin_panel_screen.dart';
import 'login_screen.dart';
import 'create_group_screen.dart';
import 'group_chat_screen.dart';
import '../services/auth_service.dart';
import '../services/mfa_session_service.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _isManager = false;
  bool _roleChecked = false; // Prevent multiple role checks

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    if (_roleChecked) return;
    _roleChecked = true;
    
    try {
      final isManager = await _authService.isUserManager().timeout(
        Duration(seconds: 3),
        onTimeout: () => false,
      );
      if (mounted) {
        setState(() {
          _isManager = isManager;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isManager = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              'SECURELY',
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
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                switch (value) {
                  case 'admin':
                    if (_isManager) {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => AdminPanelScreen(),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            return SlideTransition(
                              position: animation.drive(
                                Tween(begin: Offset(1.0, 0.0), end: Offset.zero)
                                    .chain(CurveTween(curve: AppTheme.smoothCurve)),
                              ),
                              child: child,
                            );
                          },
                        ),
                      );
                    }
                    break;
                  case 'logout':
                    _signOut();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: AppTheme.errorRed),
                      SizedBox(width: 8),
                      Text('Logout'),
                    ],
                  ),
                ),
                if (_isManager)
                  PopupMenuItem(
                    value: 'admin',
                    child: Row(
                      children: [
                        Icon(Icons.admin_panel_settings, color: AppTheme.successGreen),
                        SizedBox(width: 8),
                        Text('Admin Panel'),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.lightGray, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Container(
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
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search users or groups...',
                    hintStyle: TextStyle(color: AppTheme.mediumGray),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Container(
                      margin: EdgeInsets.all(8),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.search, color: Colors.white, size: 18),
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: _searchUsers,
                ),
              ),
            ),
            
            // Content
            Expanded(
              child: _isSearching ? _buildSearchResults() : _buildMainContent(),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.warmGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentOrange.withOpacity(0.3),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _createGroup,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Icon(Icons.group_add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return Center(
        child: Container(
          padding: EdgeInsets.all(32),
          margin: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, AppTheme.lightGray],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primaryBlue.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.search_off, size: 32, color: Colors.white),
              ),
              SizedBox(height: 16),
              Text(
                'No users found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkSlate,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Try searching for a different name',
                style: TextStyle(
                  color: AppTheme.mediumGray,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_searchResults.isEmpty && _searchController.text.isEmpty) {
      return Center(
        child: Container(
          padding: EdgeInsets.all(32),
          margin: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, AppTheme.lightGray],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primaryBlue.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Loading users...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkSlate,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final user = _searchResults[index];
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, AppTheme.lightGray],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: ListTile(
                  onTap: () => _startChat(user),
                  leading: Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundColor: Colors.transparent,
                      child: Text(
                        user['name'][0].toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    user['name'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkSlate,
                    ),
                  ),
                  subtitle: Text(
                    user['email'],
                    style: TextStyle(
                      color: AppTheme.mediumGray,
                    ),
                  ),
                  trailing: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppTheme.warmGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentOrange.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(Icons.chat, color: Colors.white, size: 20),
                  ),
                ),
              );
            },
          );
  }

      Widget _buildChatList() {
        final String? currentUid = _auth.currentUser?.uid;
        if (currentUid == null) {
          return Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('chats')
              .where('participants', arrayContains: currentUid)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

            final chats = snapshot.data?.docs.toList() ?? [];

            // Sort locally by lastMessageTime desc to avoid server-side index requirement
            chats.sort((a, b) {
              final Map<String, dynamic> aData = a.data() as Map<String, dynamic>;
              final Map<String, dynamic> bData = b.data() as Map<String, dynamic>;
              final aTs = aData['lastMessageTime'];
              final bTs = bData['lastMessageTime'];
              final aMillis = (aTs is Timestamp) ? aTs.millisecondsSinceEpoch : 0;
              final bMillis = (bTs is Timestamp) ? bTs.millisecondsSinceEpoch : 0;
              return bMillis.compareTo(aMillis);
            });

        if (chats.isEmpty) {
          // Show all users when no chats exist
          return _buildAllUsersList();
        }

        return ListView.builder(
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chat = chats[index].data() as Map<String, dynamic>;
            return _buildChatTile(chat, chats[index].id);
          },
        );
      },
    );
  }

      Widget _buildChatTile(Map<String, dynamic> chat, String chatId) {
        final String? otherUserId = chat['otherUserId'];
        if (otherUserId == null || otherUserId.isEmpty) {
          return SizedBox.shrink();
        }
        return FutureBuilder<DocumentSnapshot>(
          future: _firestore.collection('users').doc(otherUserId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return ListTile(
            leading: CircularProgressIndicator(),
            title: Text('Loading...'),
          );
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        if (userData == null) return SizedBox.shrink();

        return FutureBuilder<QuerySnapshot>(
          future: _firestore
              .collection('chats')
              .doc(chatId)
              .collection('messages')
              .where('senderId', isNotEqualTo: _auth.currentUser?.uid)
              .get(),
          builder: (context, unreadSnapshot) {
            bool hasUnreadMessages = false;
            if (unreadSnapshot.hasData) {
              for (var doc in unreadSnapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final readBy = List<String>.from(data['readBy'] ?? []);
                if (!readBy.contains(_auth.currentUser?.uid)) {
                  hasUnreadMessages = true;
                  break;
                }
              }
            }
            
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: hasUnreadMessages ? AppTheme.primaryBlue.withOpacity(0.05) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: hasUnreadMessages 
                  ? Border.all(color: AppTheme.primaryBlue.withOpacity(0.3), width: 1)
                  : Border.all(color: AppTheme.primaryBlue.withOpacity(0.1), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: hasUnreadMessages 
                      ? AppTheme.primaryBlue.withOpacity(0.1)
                      : AppTheme.primaryBlue.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                leading: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        backgroundColor: Colors.transparent,
                        child: Text(
                          userData['name'][0].toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    if (hasUnreadMessages)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        userData['name'],
                        style: TextStyle(
                          fontWeight: hasUnreadMessages ? FontWeight.bold : FontWeight.normal,
                          color: AppTheme.darkSlate,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (hasUnreadMessages)
                      Icon(
                        Icons.circle,
                        color: Colors.blue,
                        size: 8,
                      ),
                  ],
                ),
                subtitle: Text(
                  chat['lastMessage'] ?? 'No messages yet',
                  style: TextStyle(
                    fontWeight: hasUnreadMessages ? FontWeight.w500 : FontWeight.normal,
                    color: hasUnreadMessages ? AppTheme.primaryBlue : AppTheme.mediumGray,
                    fontSize: 14,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        chatId: chatId,
                        otherUser: userData,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  void _searchUsers(String query) async {
    setState(() {
      _isSearching = true;
    });

    try {
      final allUsers = await _firestore.collection('users').get();
      final results = <Map<String, dynamic>>[];
      final currentUserId = _auth.currentUser?.uid;
      
      for (var doc in allUsers.docs) {
        if (doc.id == currentUserId) continue;
        
        final userData = doc.data();
        
        // If query is empty, show all users
        if (query.trim().isEmpty) {
          results.add({
            'uid': doc.id,
            ...userData,
          });
        } else {
          // Filter by search query
          final name = userData['name']?.toString().toLowerCase() ?? '';
          final email = userData['email']?.toString().toLowerCase() ?? '';
          final searchQuery = query.toLowerCase();
          
          if (name.contains(searchQuery) || email.contains(searchQuery)) {
            results.add({
              'uid': doc.id,
              ...userData,
            });
          }
        }
      }
      
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
      });
    }
  }

  void _startChat(Map<String, dynamic> user) async {
    try {
      // Check if chat already exists
      final existingChat = await _firestore
          .collection('chats')
          .where('participants', arrayContains: _auth.currentUser?.uid)
          .get();

      String chatId = '';
      for (var doc in existingChat.docs) {
        final data = doc.data();
        if (data['participants'].contains(user['uid'])) {
          chatId = doc.id;
          break;
        }
      }

      // Create new chat if doesn't exist
      if (chatId.isEmpty) {
        final chatData = {
          'participants': [_auth.currentUser?.uid, user['uid']],
          'lastMessage': null,
          'lastMessageTime': FieldValue.serverTimestamp(),
          'otherUserId': user['uid'],
        };
        final docRef = await _firestore.collection('chats').add(chatData);
        chatId = docRef.id;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: chatId,
            otherUser: user,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start chat'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildAllUsersList() {
    return FutureBuilder<QuerySnapshot>(
      future: _firestore.collection('users').get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading users...'),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text('Error loading users'),
                SizedBox(height: 8),
                Text('${snapshot.error}'),
              ],
            ),
          );
        }

        final users = snapshot.data?.docs ?? [];
        final currentUserId = _auth.currentUser?.uid;
        
        // Filter out current user
        final otherUsers = users.where((doc) => doc.id != currentUserId).toList();

        if (otherUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No other users found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                SizedBox(height: 8),
                Text('Register another account to start chatting'),
                SizedBox(height: 4),
                Text('🔒 All messages are encrypted', style: TextStyle(fontSize: 12, color: Colors.green)),
              ],
            ),
          );
        }

        return ListView.builder(
                itemCount: otherUsers.length,
                itemBuilder: (context, index) {
                  final user = otherUsers[index].data() as Map<String, dynamic>;
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      onTap: () => _startChat({
                        'uid': otherUsers[index].id,
                        ...user,
                      }),
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Text(
                          user['name'][0].toUpperCase(),
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        user['name'],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(user['email']),
                      trailing: Icon(Icons.chat, color: Colors.green),
                    ),
                  );
                },
              );
      },
    );
  }

  void _signOut() async {
    // Clear MFA session when user explicitly logs out
    await MFASessionService.clearMFASession();
    
    // Sign out from Firebase
    await _authService.signOut();
    
    // Navigate to login screen
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  Widget _buildMainContent() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: TabBar(
              indicator: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.mediumGray,
              labelStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              unselectedLabelStyle: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              dividerColor: Colors.transparent,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat, size: 18),
                      SizedBox(width: 6),
                      Text('Chats'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group, size: 18),
                      SizedBox(width: 6),
                      Text('Groups'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildChatList(),
                _buildGroupList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupList() {
    final String? currentUid = _auth.currentUser?.uid;
    if (currentUid == null) {
      return Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('chats')
          .where('type', isEqualTo: 'group')
          .where('participants', arrayContains: currentUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final groups = snapshot.data?.docs.toList() ?? [];

        if (groups.isEmpty) {
          return Center(
            child: Container(
              padding: EdgeInsets.all(32),
              margin: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, AppTheme.lightGray],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.accentCyan.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentCyan.withOpacity(0.1),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppTheme.warmGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.group, size: 32, color: Colors.white),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No groups yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkSlate,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Create a group to start chatting!',
                    style: TextStyle(
                      color: AppTheme.mediumGray,
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withOpacity(0.3),
                          blurRadius: 15,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _createGroup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      icon: Icon(Icons.group_add, color: Colors.white),
                      label: Text(
                        'Create Group',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index].data() as Map<String, dynamic>;
            return _buildGroupTile(group, groups[index].id);
          },
        );
      },
    );
  }

  Widget _buildGroupTile(Map<String, dynamic> group, String groupId) {
    final groupName = group['groupName'] ?? 'Unknown Group';
    final participants = List<String>.from(group['participants'] ?? []);
    
    return FutureBuilder<QuerySnapshot>(
      future: _firestore
          .collection('chats')
          .doc(groupId)
          .collection('messages')
          .where('senderId', isNotEqualTo: _auth.currentUser?.uid)
          .get(),
      builder: (context, unreadSnapshot) {
        bool hasUnreadMessages = false;
        if (unreadSnapshot.hasData) {
          for (var doc in unreadSnapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final readBy = List<String>.from(data['readBy'] ?? []);
            if (!readBy.contains(_auth.currentUser?.uid)) {
              hasUnreadMessages = true;
              break;
            }
          }
        }
        
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: hasUnreadMessages ? AppTheme.accentCyan.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: hasUnreadMessages 
              ? Border.all(color: AppTheme.accentCyan.withOpacity(0.3), width: 1)
              : Border.all(color: AppTheme.accentCyan.withOpacity(0.1), width: 1),
            boxShadow: [
              BoxShadow(
                color: hasUnreadMessages 
                  ? AppTheme.accentCyan.withOpacity(0.1)
                  : AppTheme.accentCyan.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            leading: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.warmGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentOrange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    child: Icon(Icons.group, color: Colors.white, size: 20),
                  ),
                ),
                if (hasUnreadMessages)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    groupName,
                    style: TextStyle(
                      fontWeight: hasUnreadMessages ? FontWeight.bold : FontWeight.normal,
                      color: AppTheme.darkSlate,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (hasUnreadMessages)
                  Icon(
                    Icons.circle,
                    color: Colors.blue,
                    size: 8,
                  ),
              ],
            ),
            subtitle: Text(
              '${participants.length} members • ${group['lastMessage'] ?? 'No messages yet'}',
              style: TextStyle(
                fontWeight: hasUnreadMessages ? FontWeight.w500 : FontWeight.normal,
                color: hasUnreadMessages ? AppTheme.accentCyan : AppTheme.mediumGray,
                fontSize: 14,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupChatScreen(
                    groupId: groupId,
                    groupName: groupName,
                    members: participants,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _createGroup() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateGroupScreen()),
    );
    
    if (result != null) {
      // Group created successfully
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Group created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
