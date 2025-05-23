// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';

// class ChatPage extends StatefulWidget {
//   final String driverId;
//   final String chatRoomId;
//   final String businessName;

//   const ChatPage({
//     Key? key,
//     required this.driverId,
//     required this.chatRoomId,
//     required this.businessName,
//   }) : super(key: key);

//   @override
//   _ChatPageState createState() => _ChatPageState();
// }

// class _ChatPageState extends State<ChatPage> {
//   late WebSocketChannel _channel;
//   final TextEditingController _messageController = TextEditingController();
//   final List<Map<String, dynamic>> _messages = [];
//   final ScrollController _scrollController = ScrollController();

//   @override
//   void initState() {
//     super.initState();
//     _initializeChat();
//   }

//   Future<void> _initializeChat() async {
//   await _fetchMessageHistory();
//   await _connectToWebSocket();
// }
//   Future<void> _fetchMessageHistory() async {
//   print('Fetching message history for chat room: ${widget.chatRoomId}');
//   final prefs = await SharedPreferences.getInstance();
//   final accessToken = prefs.getString('access_token');
  
//   try {
//     final response = await http.get(
//       Uri.parse('http://192.168.20.29:8000/api/chat-history/${widget.chatRoomId}/'),
//       headers: {'Authorization': 'Bearer $accessToken'},
//     );

//     if (response.statusCode == 200) {
//       final List<dynamic> messages = jsonDecode(response.body);
//       setState(() {
//         _messages.addAll(messages.map((msg) {
//           // Get sender ID from nested object
//           final senderId = msg['sender']?['id']?.toString();
//           final isMe = senderId == widget.driverId.toString();
//           final messageText = msg['message'] ?? '';
          
//           print('Processing message: $messageText, senderId: $senderId, isMe: $isMe');
          
//           return {
//             'text': messageText,
//             'isMe': isMe,
//             'timestamp': msg['timestamp'] != null 
//                 ? DateTime.tryParse(msg['timestamp']) ?? DateTime.now()
//                 : DateTime.now(),
//           };
//         }).where((msg) => msg['text'].isNotEmpty).toList()); // Filter out empty messages
//       });
//       print('Total messages after fetch: ${_messages.length}');
//       _scrollToBottom();
//     } else {
//       print('Failed to load message history: ${response.statusCode}');
//       print('Response body: ${response.body}');
//     }
//   } catch (e) {
//     print('Error fetching message history: $e');
//   }
// }

//  Future<void> _connectToWebSocket() async {
//   final prefs = await SharedPreferences.getInstance();
//   final accessToken = prefs.getString('access_token');
  
//   print('Driver ID: ${widget.driverId}');
//   print('Connecting to chat room: ${widget.chatRoomId}');
//   print('Business: ${widget.businessName}');
//   print('Access token: ${accessToken != null ? '*' : 'null'}');

//   if (accessToken == null) {
//     print('No access token found');
//     Navigator.pop(context);
//     return;
//   }

//   try {
//     _channel = WebSocketChannel.connect(
//       Uri.parse('ws://192.168.20.29:8000/ws/chat/${widget.chatRoomId}/?token=$accessToken'),
//     );

//     print('WebSocket connection established');

//     _channel.stream.listen((message) {
//       print('Received message: $message');
//       try {
//         final data = jsonDecode(message);
//         final senderId = data['sender']?.toString(); // Assuming the WebSocket message includes sender ID
//         final isMe = senderId == widget.driverId.toString();
//         setState(() {
//           _messages.add({
//             'text': data['message'],
//             'isMe': isMe,
//             'timestamp': DateTime.now(),
//           });
//         });

//         _scrollToBottom();
//       } catch (e) {
//         print('Error parsing message: $e');
//       }
//     }, 
//     onError: (error) {
//       print('WebSocket error: $error');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Connection error. Try again.')),
//       );
//     }, 
//     onDone: () {
//       print('WebSocket connection closed');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Connection closed')),
//       );
//     });

//     await _channel.ready;
//     print('WebSocket connection is ready');

//   } catch (e) {
//     print('WebSocket connection failed: $e');
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Failed to connect to chat. Please try again.')),
//     );
//     Navigator.pop(context);
//   }
// }

//   void _sendMessage() {
//   if (_messageController.text.trim().isEmpty) return;

//   final message = _messageController.text;
//   _channel.sink.add(jsonEncode({
//     'message': message,
//   }));

//   // Remove the local addition of the message to _messages
//   // The message will be added when received via WebSocket

//   _messageController.clear();
//   _scrollToBottom();
// }

//   void _scrollToBottom() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (_scrollController.hasClients) {
//         _scrollController.animateTo(
//           _scrollController.position.maxScrollExtent,
//           duration: Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _channel.sink.close();
//     _messageController.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return CupertinoPageScaffold(
//       navigationBar: CupertinoNavigationBar(
//         middle: Text(widget.businessName),
//       ),
//       child: SafeArea(
//         child: Column(
//           children: [
//             Expanded(
//               child: ListView.builder(
//                 controller: _scrollController,
//                 padding: EdgeInsets.all(16),
//                 itemCount: _messages.length,
//                 itemBuilder: (context, index) {
//                   final message = _messages[index];
//                   return Align(
//                     alignment: message['isMe']
//                         ? Alignment.centerRight
//                         : Alignment.centerLeft,
//                     child: Container(
//                       margin: EdgeInsets.symmetric(vertical: 4),
//                       padding: EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: message['isMe']
//                             ? CupertinoColors.activeBlue
//                             : CupertinoColors.systemGrey5,
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Text(
//                         message['text'],
//                         style: TextStyle(
//                           color: message['isMe']
//                               ? CupertinoColors.white
//                               : CupertinoColors.black,
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//             Padding(
//               padding: EdgeInsets.all(8),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: CupertinoTextField(
//                       controller: _messageController,
//                       placeholder: 'Type a message...',
//                       padding: EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 12,
//                       ),
//                       decoration: BoxDecoration(
//                         color: CupertinoColors.systemGrey6,
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                     ),
//                   ),
//                   SizedBox(width: 8),
//                   CupertinoButton(
//                     padding: EdgeInsets.all(12),
//                     borderRadius: BorderRadius.circular(20),
//                     color: CupertinoColors.activeBlue,
//                     child: Icon(CupertinoIcons.paperplane_fill,
//                         color: CupertinoColors.white),
//                     onPressed: _sendMessage,
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatPage extends StatefulWidget {
  final String driverId;
  final String chatRoomId;
  final String businessName;

  const ChatPage({
    Key? key,
    required this.driverId,
    required this.chatRoomId,
    required this.businessName,
  }) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  WebSocketChannel? _channel;
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isConnected = false;
  bool _isLoading = true;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const String _baseUrl = 'http://192.168.20.29:8001';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeChat();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && !_isConnected) {
      _reconnectWebSocket();
    } else if (state == AppLifecycleState.paused) {
      _disconnectWebSocket();
    }
  }

  Future<void> _initializeChat() async {
    try {
      await _fetchMessageHistory();
      await _connectToWebSocket();
    } catch (e) {
      print('Failed to initialize chat: $e');
      _showErrorSnackBar('Failed to initialize chat');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchMessageHistory() async {
    print('Fetching message history for chat room: ${widget.chatRoomId}');
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    
    if (accessToken == null) {
      throw Exception('No access token found');
    }
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/chat-history/${widget.chatRoomId}/'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> messages = jsonDecode(response.body);
        final processedMessages = messages
            .map((msg) => _processMessage(msg))
            .where((msg) => msg != null && msg['text'].toString().trim().isNotEmpty)
            .cast<Map<String, dynamic>>()
            .toList();
        
        setState(() {
          _messages.clear();
          _messages.addAll(processedMessages);
        });
        
        print('Loaded ${_messages.length} messages');
        _scrollToBottom();
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed');
      } else {
        throw Exception('Failed to load messages: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Request timeout');
    } catch (e) {
      print('Error fetching message history: $e');
      rethrow;
    }
  }

  Map<String, dynamic>? _processMessage(Map<String, dynamic> msg) {
    try {
      final senderId = msg['sender']?['id']?.toString();
      final isMe = senderId == widget.driverId.toString();
      final messageText = msg['message']?.toString() ?? '';
      
      if (messageText.isEmpty) return null;
      
      return {
        'text': messageText,
        'isMe': isMe,
        'timestamp': _parseTimestamp(msg['timestamp']),
        'id': msg['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      };
    } catch (e) {
      print('Error processing message: $e');
      return null;
    }
  }

  DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    try {
      return DateTime.parse(timestamp.toString());
    } catch (e) {
      return DateTime.now();
    }
  }

  Future<void> _connectToWebSocket() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    
    if (accessToken == null) {
      throw Exception('No access token found');
    }

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('ws://192.168.20.29:8001/ws/chat/${widget.chatRoomId}/?token=$accessToken'),
      );

      _channel!.stream.listen(
        _handleWebSocketMessage,
        onError: _handleWebSocketError,
        onDone: _handleWebSocketClose,
      );

      await _channel!.ready.timeout(const Duration(seconds: 10));
      
      setState(() {
        _isConnected = true;
        _reconnectAttempts = 0;
      });
      
      print('WebSocket connected successfully');
    } catch (e) {
      print('WebSocket connection failed: $e');
      setState(() {
        _isConnected = false;
      });
      _scheduleReconnect();
      rethrow;
    }
  }

  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = jsonDecode(message.toString());
      final processedMessage = _processWebSocketMessage(data);
      
      if (processedMessage != null) {
        setState(() {
          // Remove temporary message with same text if it exists
          _messages.removeWhere((msg) => 
              msg['text'] == processedMessage['text'] && 
              msg['isTemporary'] == true);
          
          // Check for duplicates more thoroughly
          final isDuplicate = _messages.any((msg) => 
              msg['text'] == processedMessage['text'] && 
              msg['isMe'] == processedMessage['isMe'] &&
              msg['isTemporary'] != true &&
              msg['timestamp'].difference(processedMessage['timestamp']).abs().inSeconds < 5);
          
          if (!isDuplicate) {
            _messages.add(processedMessage);
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('Error parsing WebSocket message: $e');
    }
  }

  Map<String, dynamic>? _processWebSocketMessage(Map<String, dynamic> data) {
    final messageText = data['message']?.toString();
    if (messageText == null || messageText.trim().isEmpty) return null;
    
    // Multiple ways to identify the sender
    String? senderId;
    
    // Try different possible sender ID fields from the WebSocket message
    if (data['sender_id'] != null) {
      senderId = data['sender_id'].toString();
    } else if (data['sender'] != null) {
      // Handle both string and object cases
      if (data['sender'] is String) {
        senderId = data['sender'].toString();
      } else if (data['sender'] is Map && data['sender']['id'] != null) {
        senderId = data['sender']['id'].toString();
      }
    } else if (data['user_id'] != null) {
      senderId = data['user_id'].toString();
    } else if (data['from'] != null) {
      senderId = data['from'].toString();
    }
    
    // Debug logging
    print('WebSocket message data: $data');
    print('Extracted sender ID: $senderId');
    print('Current driver ID: ${widget.driverId}');
    
    final isMe = senderId == widget.driverId.toString();
    print('Is message from me: $isMe');
    
    return {
      'text': messageText,
      'isMe': isMe,
      'timestamp': DateTime.now(),
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'senderId': senderId, // Store for debugging
    };
  }

  void _handleWebSocketError(dynamic error) {
    print('WebSocket error: $error');
    setState(() {
      _isConnected = false;
    });
    _showErrorSnackBar('Connection error');
    _scheduleReconnect();
  }

  void _handleWebSocketClose() {
    print('WebSocket connection closed');
    setState(() {
      _isConnected = false;
    });
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _showErrorSnackBar('Failed to connect after multiple attempts');
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      Duration(seconds: 2 * (_reconnectAttempts + 1)), // Exponential backoff
      _reconnectWebSocket,
    );
  }

  void _reconnectWebSocket() {
    if (_isConnected) return;
    
    _reconnectAttempts++;
    print('Attempting to reconnect (attempt $_reconnectAttempts)');
    
    _connectToWebSocket().catchError((e) {
      print('Reconnection failed: $e');
    });
  }

  void _disconnectWebSocket() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    setState(() {
      _isConnected = false;
    });
  }

  void _sendMessage() {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || !_isConnected) return;

    try {
      // Add message locally first to show immediate feedback
      final tempMessage = {
        'text': messageText,
        'isMe': true,
        'timestamp': DateTime.now(),
        'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
        'isTemporary': true, // Mark as temporary
      };
      
      setState(() {
        _messages.add(tempMessage);
      });
      
      // Send message to WebSocket
      _channel?.sink.add(jsonEncode({
        'message': messageText,
        'sender': widget.driverId,
        'sender_id': widget.driverId,
        'user_id': widget.driverId,
        'type': 'chat_message',
      }));

      _messageController.clear();
      _scrollToBottom();
      
      // Set a timer to remove temporary message if no confirmation received
      Timer(const Duration(seconds: 5), () {
        setState(() {
          _messages.removeWhere((msg) => 
              msg['id'] == tempMessage['id'] && 
              msg['isTemporary'] == true);
        });
      });
      
    } catch (e) {
      print('Error sending message: $e');
      _showErrorSnackBar('Failed to send message');
      
      // Remove the temporary message on error
      setState(() {
        _messages.removeWhere((msg) => 
            msg['text'] == messageText && 
            msg['isTemporary'] == true);
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: CupertinoColors.destructiveRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildConnectionStatus() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(8),
        color: CupertinoColors.systemYellow.withOpacity(0.1),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CupertinoActivityIndicator(),
            SizedBox(width: 8),
            Text('Loading chat...'),
          ],
        ),
      );
    }

    if (!_isConnected) {
      return Container(
        padding: const EdgeInsets.all(8),
        color: CupertinoColors.destructiveRed.withOpacity(0.1),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.wifi_slash,
              size: 16,
              color: CupertinoColors.destructiveRed,
            ),
            const SizedBox(width: 8),
            Text(
              _reconnectAttempts > 0 
                  ? 'Reconnecting... (${_reconnectAttempts}/$_maxReconnectAttempts)'
                  : 'Connection lost',
              style: const TextStyle(color: CupertinoColors.destructiveRed),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, int index) {
    final isMe = message['isMe'] as bool;
    final timestamp = message['timestamp'] as DateTime;
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe
                    ? CupertinoColors.activeBlue
                    : CupertinoColors.systemGrey5,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                message['text'].toString(),
                style: TextStyle(
                  color: isMe ? CupertinoColors.white : CupertinoColors.black,
                  fontSize: 16,
                ),
              ),
            ),
            if (index == _messages.length - 1 || 
                _shouldShowTimestamp(message, index))
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 12, right: 12),
                child: Text(
                  _formatTimestamp(timestamp),
                  style: const TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _shouldShowTimestamp(Map<String, dynamic> message, int index) {
    if (index == _messages.length - 1) return true;
    
    final currentTime = message['timestamp'] as DateTime;
    final nextTime = _messages[index + 1]['timestamp'] as DateTime;
    
    return nextTime.difference(currentTime).inMinutes > 5;
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inHours > 0) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return 'Just now';
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _reconnectTimer?.cancel();
    _disconnectWebSocket();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.businessName),
        trailing: _isConnected
            ? const Icon(
                CupertinoIcons.circle_fill,
                color: CupertinoColors.systemGreen,
                size: 12,
              )
            : const Icon(
                CupertinoIcons.circle_fill,
                color: CupertinoColors.systemRed,
                size: 12,
              ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildConnectionStatus(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : _messages.isEmpty
                      ? const Center(
                          child: Text(
                            'No messages yet.\nStart the conversation!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: CupertinoColors.systemGrey,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) =>
                              _buildMessageBubble(_messages[index], index),
                        ),
            ),
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: CupertinoColors.systemGrey4,
                    width: 0.5,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoTextField(
                        controller: _messageController,
                        placeholder: 'Type a message...',
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey6,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: CupertinoColors.systemGrey4,
                            width: 0.5,
                          ),
                        ),
                        maxLines: 5,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    CupertinoButton(
                      padding: const EdgeInsets.all(12),
                      borderRadius: BorderRadius.circular(25),
                      color: _isConnected
                          ? CupertinoColors.activeBlue
                          : CupertinoColors.systemGrey,
                      onPressed: _isConnected ? _sendMessage : null,
                      child: const Icon(
                        CupertinoIcons.paperplane_fill,
                        color: CupertinoColors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}