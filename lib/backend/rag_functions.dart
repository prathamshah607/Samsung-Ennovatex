import 'dart:convert';
import 'dart:io';
import '../data/data.dart';

Future<List<Message>> getRagContext(String query) async {
  try {
    final result = await Process.run(
      'python',
      ['rag_backend/retrieve_context_wrapper.py', query],
    );

    if (result.exitCode != 0) return [];

    List<dynamic> data = jsonDecode(result.stdout as String);
    return data.map((m) => Message.fromJson(m)).toList();
  } catch (e) {
    return [];
  }
}

void generateOffline(String userQuery, Function updateUI) async {
  addMessage("user", userQuery);
  updateUI();

  await Process.run(
    'python',
    ['rag_backend/ingest.py', 'user', userQuery, ""],
  );

  List<Message> contextAndResponse = await getRagContext(userQuery);

  if (contextAndResponse.isEmpty) {
    addMessage("generator", "Sorry, I couldn't generate a response.");
    updateUI();
    return;
  }

  for (var msg in contextAndResponse) {
    addMessage(msg.actor, msg.text, imagePath: msg.imagePath);
  }

  updateUI();
}
