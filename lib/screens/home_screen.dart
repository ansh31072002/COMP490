import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';
import 'admin_panel_screen.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';
import '../services/mfa_session_service.dart';

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
        title: Text('💬 SECURELY'),
        backgroundColor: Colors.blue,
        actions: [
          // Security features menu
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'admin':
                  if (_isManager) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AdminPanelScreen()),
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
                    Icon(Icons.logout, color: Colors.red),
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
                      Icon(Icons.admin_panel_settings, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Admin Panel'),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _searchUsers,
            ),
          ),
          
          // Content
          Expanded(
            child: _isSearching ? _buildSearchResults() : _buildAllUsersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No users found', style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text('Try searching for a different name'),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty && _searchController.text.isEmpty) {
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

    return ListView.builder(
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final user = _searchResults[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  onTap: () => _startChat(user),
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
              decoration: hasUnreadMessages ? BoxDecoration(
                color: Colors.blue[50],
                border: Border(left: BorderSide(color: Colors.blue, width: 4)),
              ) : null,
              child: ListTile(
                leading: Stack(
                  children: [
                    CircleAvatar(
                      child: Text(userData['name'][0].toUpperCase()),
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
                    color: hasUnreadMessages ? Colors.blue[700] : null,
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
}
