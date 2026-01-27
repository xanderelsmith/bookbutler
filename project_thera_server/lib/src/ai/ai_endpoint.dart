import 'package:serverpod/serverpod.dart';
import 'package:dartantic_ai/dartantic_ai.dart';
import 'package:dartantic_interface/dartantic_interface.dart';
import 'dart:developer';

class AiEndpoint extends Endpoint {
  /// Asks the AI a question about a specific page content.
  Future<String> askAboutPage(
    Session session,
    String pageContent,
    String userQuestion,
  ) async {
    log('running');
    final apiKey = session.passwords['aiApiKey'];
    if (apiKey == null) {
      return 'AI API Key not configured. Please add "aiApiKey" to your config/passwords.yaml file.';
    }

    // Initialize the model (using OpenAI as default for now, can be swapped)
    // You might need to adjust the model class based on the specific provider you want to use
    // e.g. OpenAIModel, GoogleModel, etc. provided by dartantic_ai
    final agent = Agent.forProvider(
      GoogleProvider(apiKey: apiKey),
      chatModelName: 'gemini-2.5-flash-lite',
    );
    try {
      // Run the agent with the context and question
      final response = await agent.send(
        'Page Content:\n$pageContent\n\nUser Question:\n$userQuestion',
        history: [
          ChatMessage.system(
            'You are a helpful assistant analyzing the content of a mobile app page. Answer the user\'s question based on the provided page content.',
          ),
        ],
      );

      return response.messages.last.text;
    } catch (e) {
      return 'Error querying AI: $e';
    }
  }
}
