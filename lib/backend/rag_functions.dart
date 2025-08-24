import 'dart:convert';
import 'dart:io';
import '../data.dart';

Future<List<Message>> getRagContext(String query) async {
  try {
    final pythonPath = r"D:\python.exe"; // Your Python path
    final result = await Process.run(
      pythonPath,
      ['rag_backend/retrieve_context_wrapper.py', query],
      workingDirectory: Directory.current.path, 
    );

    if (result.exitCode != 0) {
      print("retrieve_context_wrapper.py error: ${result.stderr}");
      return [];
    }

    if (result.stdout == null || result.stdout.toString().trim().isEmpty) {
      return [];
    }

    final decoded = jsonDecode(result.stdout.toString());
    if (decoded is! List) return [];

    return decoded.map<Message>((m) {
      if (m is Map<String, dynamic>) {
        return Message.fromJson(m);
      } else if (m is Map) {
        return Message.fromJson(Map<String, dynamic>.from(m));
      } else {
        return Message(actor: "generator", text: m.toString());
      }
    }).toList();
  } catch (e) {
    print("getRagContext exception: $e");
    return [];
  }
}

Future<String> callPhi3(String prompt) async {
  try {
    final pythonPath = r"D:\python.exe"; // Your Python path
    final result = await Process.run(
      pythonPath,
      ['rag_backend/generate_phi3.py', prompt],
    );

    if (result.exitCode != 0) {
      print("generate_phi3.py error: ${result.stderr}");
      return "Error: ${result.stderr}";
    }

    return result.stdout.toString().trim();
  } catch (e) {
    print("callPhi3 exception: $e");
    return "Error calling Phi-3: $e";
  }
}

Future<void> ingestMessage(String actor, String message, {String? imagePath}) async {
  final pythonPath = r"D:\python.exe"; // Your Python path
  final result = await Process.run(
    pythonPath,
    ['rag_backend/ingest.py', actor, message, imagePath ?? ""],
  );

  // Debug prints to check Python execution
  print("stdout: ${result.stdout}");
  print("stderr: ${result.stderr}");
  print("exitCode: ${result.exitCode}");

  if (result.exitCode != 0) {
    print("ingest.py encountered an error.");
  } else {
    print("ingest.py executed successfully.");
  }
}

void generateWithPhi3(String userQuery, Function updateUI) async {
  // Add user message locally
  addMessage("user", userQuery);
  updateUI();

  // Ingest user message
  await ingestMessage("user", userQuery);

  // Retrieve relevant previous messages
  final List<Message> context = await getRagContext(userQuery);

  // Sort context chronologically by timestamp
  context.sort((Message a, Message b) => a.timestamp.compareTo(b.timestamp));

  // Format context text for prompt
  final String contextText = context.isNotEmpty
      ? context.map((m) {
          final role = m.actor == 'generator' ? 'Assistant' : 'User';
          return "$role: ${m.text}";
        }).join("\n---\n")
      : "";

  // Construct prompt for Phi3
  final String phi3Prompt = """
$contextText
User: $userQuery
Assistant:""";

  // Generate Phi3 response
  final String phi3Response = await callPhi3(phi3Prompt);

  // Add assistant response locally
  addMessage("generator", phi3Response);

  // Ingest assistant response
  await ingestMessage("generator", phi3Response);

  updateUI();
}

