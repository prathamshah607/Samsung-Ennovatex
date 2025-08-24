import 'package:flutter/material.dart';
import 'package:ollama/ollama.dart';
import 'backend/rag_functions.dart';

Ollama _ollama = Ollama();
List<Message> conversations = [];

class Message {
  final String actor;
  final String text;
  final String? imagePath;
  final DateTime timestamp; // added timestamp for chronological context

  Message({
    required this.actor,
    required this.text,
    this.imagePath,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now(); // default to current time

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      actor: json['actor'] ?? "unknown",
      text: json['message'] ?? "",
      imagePath: json['image_path'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'actor': actor,
      'message': text,
      'image_path': imagePath,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

void addMessage(String actor, String text, {String? imagePath}) {
  conversations.add(Message(actor: actor, text: text, imagePath: imagePath));
}

void generateWithRag(String userQuery, Function updateUI) async {
  // Add user message
  addMessage("user", userQuery);

  // Initialize generator message
  Message generatorMessage = Message(actor: "generator", text: "");
  conversations.add(generatorMessage);
  updateUI();

  // Get context
  final List<Message> context = await getRagContext(userQuery) ?? [];

  // Sort context by timestamp
  context.sort((a, b) => a.timestamp.compareTo(b.timestamp));

  String contextText = context.isNotEmpty
      ? context.map((m) => "${m.actor}: ${m.text}").join("\n\n")
      : "";

  String prompt = contextText.isNotEmpty
      ? "$contextText\n\nUser: $userQuery\nAssistant:"
      : "User: $userQuery\nAssistant:";

  try {
    final stream = _ollama.generate(prompt, model: "phi3");

    await for (final chunk in stream) {
      // Append new text to the generator message
      generatorMessage = Message(
        actor: "generator",
        text: generatorMessage.text + chunk.text,
        timestamp: generatorMessage.timestamp,
      );
      conversations[conversations.length - 1] = generatorMessage;
      updateUI();
    }
  } catch (e) {
    generatorMessage = Message(actor: "generator", text: "Error: $e");
    conversations[conversations.length - 1] = generatorMessage;
    updateUI();
  }
}

void testPhi3() async {
  try {
    final stream = _ollama.generate("Hello, who are you?", model: "phi3");
    await for (final chunk in stream) {
      print("Phi3 chunk: ${chunk.text}");
    }
  } catch (e) {
    print("Phi3 error: $e");
  }
}
