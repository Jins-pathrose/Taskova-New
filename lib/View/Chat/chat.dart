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

class _ChatPageState extends State<ChatPage> {
  late WebSocketChannel _channel;
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
  await _fetchMessageHistory();
  await _connectToWebSocket();
}
  Future<void> _fetchMessageHistory() async {
  print('Fetching message history for chat room: ${widget.chatRoomId}');
  final prefs = await SharedPreferences.getInstance();
  final accessToken = prefs.getString('access_token');
  
  try {
    final response = await http.get(
      Uri.parse('http://192.168.20.29:8000/api/chat-history/${widget.chatRoomId}/'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> messages = jsonDecode(response.body);
      setState(() {
        _messages.addAll(messages.map((msg) {
          // Get sender ID from nested object
          final senderId = msg['sender']?['id']?.toString();
          final isMe = senderId == widget.driverId.toString();
          final messageText = msg['message'] ?? '';
          
          print('Processing message: $messageText, senderId: $senderId, isMe: $isMe');
          
          return {
            'text': messageText,
            'isMe': isMe,
            'timestamp': msg['timestamp'] != null 
                ? DateTime.tryParse(msg['timestamp']) ?? DateTime.now()
                : DateTime.now(),
          };
        }).where((msg) => msg['text'].isNotEmpty).toList()); // Filter out empty messages
      });
      print('Total messages after fetch: ${_messages.length}');
      _scrollToBottom();
    } else {
      print('Failed to load message history: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
  } catch (e) {
    print('Error fetching message history: $e');
  }
}

 Future<void> _connectToWebSocket() async {
  final prefs = await SharedPreferences.getInstance();
  final accessToken = prefs.getString('access_token');
  
  print('Driver ID: ${widget.driverId}');
  print('Connecting to chat room: ${widget.chatRoomId}');
  print('Business: ${widget.businessName}');
  print('Access token: ${accessToken != null ? '*' : 'null'}');

  if (accessToken == null) {
    print('No access token found');
    Navigator.pop(context);
    return;
  }

  try {
    _channel = WebSocketChannel.connect(
      Uri.parse('ws://192.168.20.29:8000/ws/chat/${widget.chatRoomId}/?token=$accessToken'),
    );

    print('WebSocket connection established');

    _channel.stream.listen((message) {
      print('Received message: $message');
      try {
        final data = jsonDecode(message);
        final senderId = data['sender']?.toString(); // Assuming the WebSocket message includes sender ID
        final isMe = senderId == widget.driverId.toString();
        setState(() {
          _messages.add({
            'text': data['message'],
            'isMe': isMe,
            'timestamp': DateTime.now(),
          });
        });
        _scrollToBottom();
      } catch (e) {
        print('Error parsing message: $e');
      }
    }, 
    onError: (error) {
      print('WebSocket error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error. Try again.')),
      );
    }, 
    onDone: () {
      print('WebSocket connection closed');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection closed')),
      );
    });

    await _channel.ready;
    print('WebSocket connection is ready');

  } catch (e) {
    print('WebSocket connection failed: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to connect to chat. Please try again.')),
    );
    Navigator.pop(context);
  }
}

  void _sendMessage() {
  if (_messageController.text.trim().isEmpty) return;

  final message = _messageController.text;
  _channel.sink.add(jsonEncode({
    'message': message,
  }));

  // Remove the local addition of the message to _messages
  // The message will be added when received via WebSocket

  _messageController.clear();
  _scrollToBottom();
}

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _channel.sink.close();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.businessName),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return Align(
                    alignment: message['isMe']
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: message['isMe']
                            ? CupertinoColors.activeBlue
                            : CupertinoColors.systemGrey5,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        message['text'],
                        style: TextStyle(
                          color: message['isMe']
                              ? CupertinoColors.white
                              : CupertinoColors.black,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoTextField(
                      controller: _messageController,
                      placeholder: 'Type a message...',
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  CupertinoButton(
                    padding: EdgeInsets.all(12),
                    borderRadius: BorderRadius.circular(20),
                    color: CupertinoColors.activeBlue,
                    child: Icon(CupertinoIcons.paperplane_fill,
                        color: CupertinoColors.white),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}