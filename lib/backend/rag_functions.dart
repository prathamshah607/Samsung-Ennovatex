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

Future<String> callPhi3(String prompt) async {
  try {
    final result = await Process.run(
      'python',
      ['rag_backend/generate_phi3.py', prompt],
    );

    if (result.exitCode != 0) return "Error: ${result.stderr}";
    return result.stdout.toString().trim();
  } catch (e) {
    return "Error calling Phi-3: $e";
  }
}

void generateWithPhi3(String userQuery, Function updateUI) async {
  addMessage("user", userQuery);
  updateUI();

  await Process.run(
    'python',
    ['rag_backend/ingest.py', 'user', userQuery, ""],
  );

  List<Message> context = await getRagContext(userQuery);
  String contextText = context.map((m) => m.text).join("\n");

  String phi3Prompt = "Context:\n$contextText\nUser: $userQuery";
  String phi3Response = await callPhi3(phi3Prompt);

  addMessage("generator", phi3Response);
  await Process.run(
    'python',
    ['rag_backend/ingest.py', 'generator', phi3Response, ""],
  );

  updateUI();
}
