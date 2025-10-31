import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/encryption_service.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final Map<String, dynamic> otherUser;

  ChatScreen({required this.chatId, required this.otherUser});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
  }

  Future<void> _markMessagesAsRead() async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      // Get all messages in this chat that haven't been read by current user
      final messages = await _firestore
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: currentUserId) // Only messages from others
          .get();

      // Mark each message as read by current user
      for (var doc in messages.docs) {
        final data = doc.data();
        final readBy = List<String>.from(data['readBy'] ?? []);
        
        if (!readBy.contains(currentUserId)) {
          readBy.add(currentUserId);
          await doc.reference.update({
            'readBy': readBy,
            'isRead': true,
          });
        }
      }
      
    } catch (e) {
      // Handle error silently
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser['name'] ?? 'Chat',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    'Encrypted Chat',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: Colors.white70,
                    ),
                  ),
                ],
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.lightGray, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Security notice
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryBlue.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.security, color: Colors.white, size: 16),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'SECURELY - Encrypted Chat',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
          // Messages list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final messages = snapshot.data?.docs ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Container(
                      padding: EdgeInsets.all(32),
                      margin: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.chat_bubble_outline, size: 32, color: Colors.white),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No messages yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkSlate,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Start the conversation!',
                            style: TextStyle(
                              color: AppTheme.mediumGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index].data() as Map<String, dynamic>;
                    final isCurrentUser = message['senderId'] == _auth.currentUser?.uid;
                    return _buildMessageBubble(message, isCurrentUser);
                  },
                );
              },
            ),
          ),

            // Message input
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    blurRadius: 20,
                    offset: Offset(0, -8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.lightGray,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: AppTheme.primaryBlue.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: TextStyle(
                          color: AppTheme.darkSlate,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: TextStyle(color: AppTheme.mediumGray),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          filled: true,
                          fillColor: Colors.transparent,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withOpacity(0.3),
                          blurRadius: 15,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: FloatingActionButton(
                      onPressed: _sendMessage,
                      mini: true,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      child: Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isCurrentUser) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isCurrentUser) ...[
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
                radius: 16,
                backgroundColor: Colors.transparent,
                child: Text(
                  (message['senderName'] ?? widget.otherUser['name'])[0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isCurrentUser ? AppTheme.primaryGradient : AppTheme.secondaryGradient,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isCurrentUser ? 16 : 0),
                  topRight: Radius.circular(isCurrentUser ? 0 : 16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isCurrentUser ? AppTheme.primaryBlue : AppTheme.secondaryBlue).withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isCurrentUser)
                    Text(
                      message['senderName'] ?? 'Unknown',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppTheme.darkSlate,
                      ),
                    ),
                  if (!isCurrentUser) SizedBox(height: 4),
                  FutureBuilder<String>(
                    future: _getDecryptedMessage(message['message'], message['isEncrypted'] ?? false),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Text(
                          'Decrypting...',
                          style: TextStyle(
                            color: AppTheme.darkSlate,
                            fontStyle: FontStyle.italic,
                          ),
                        );
                      }
                      
                      return Text(
                        snapshot.data ?? message['message'],
                        style: TextStyle(
                          color: AppTheme.darkSlate,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 4),
                  Text(
                    _formatTime(message['timestamp']),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.mediumGray,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isCurrentUser) ...[
            SizedBox(width: 8),
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
                radius: 16,
                backgroundColor: Colors.transparent,
                child: Text(
                  _auth.currentUser?.displayName?[0].toUpperCase() ?? 'U',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getDisplayMessage(String message) {
    // For now, show message as-is since we need async for decryption
    // This will be handled in the message bubble widget
    return message;
  }
  
  Future<String> _getDecryptedMessage(String message, bool isEncrypted) async {
    try {
      if (!isEncrypted) {
        return message; // Message is not encrypted, return as-is
      }
      
      // Try fallback decryption first
      final result = await EncryptionService.decryptWithFallback(message, widget.chatId);
      
      // If fallback failed and it's still encrypted, handle as legacy message
      if (result.contains('[Encrypted message - key not available]')) {
        return EncryptionService.handleLegacyMessage(message, isEncrypted);
      }
      
      return result;
    } catch (e) {
      print('Decryption error: $e');
      return EncryptionService.handleLegacyMessage(message, isEncrypted);
    }
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();

    try {
      // Get or create shared encryption key for this chat
      final sharedKey = await EncryptionService.getOrCreateSharedKey(widget.chatId);
      
      // Get participant IDs for this chat (you might need to implement this based on your chat structure)
      final participantIds = [widget.chatId]; // This should be the actual participant IDs
      
      // Store the shared key in Firebase for persistence
      await EncryptionService.storeSharedKey(widget.chatId, sharedKey, participantIds);
      
      // Encrypt the message using AES-256
      final encryptedMessage = EncryptionService.encryptMessage(message, sharedKey);
      
      await _firestore
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        'message': encryptedMessage,
        'senderId': _auth.currentUser?.uid,
        'senderName': _auth.currentUser?.displayName ?? _auth.currentUser?.email?.split('@')[0] ?? 'You',
        'timestamp': FieldValue.serverTimestamp(),
        'readBy': [_auth.currentUser?.uid],
        'isRead': true,
        'isEncrypted': true, // Flag to indicate this message is encrypted
      });

      await _firestore.collection('chats').doc(widget.chatId).update({
        'lastMessage': '[Encrypted Message]', // Don't show actual content
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending encrypted message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    
    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else {
      dateTime = DateTime.now();
    }
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
