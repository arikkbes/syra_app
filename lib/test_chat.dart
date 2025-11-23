import 'package:flutter/material.dart';
import 'services/flortiq_service.dart';

class TestChatPage extends StatefulWidget {
  const TestChatPage({super.key});

  @override
  State<TestChatPage> createState() => _TestChatPageState();
}

class _TestChatPageState extends State<TestChatPage> {
  final _controller = TextEditingController();
  final flortIQ = FlortIQService();

  String _reply = '';

  void _sendMessage() async {
    final userMessage = _controller.text.trim();
    if (userMessage.isEmpty) return;

    setState(() {
      _reply = "Yükleniyor...";
    });

    final reply = await flortIQ.sendMessage(userMessage);

    setState(() {
      _reply = reply;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SYRA Test")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: "Mesajını yaz",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _sendMessage,
              child: const Text("Gönder"),
            ),
            const SizedBox(height: 24),
            Text(_reply, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
