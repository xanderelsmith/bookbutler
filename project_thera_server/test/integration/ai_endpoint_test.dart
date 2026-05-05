import 'package:test/test.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given AI endpoint', (sessionBuilder, endpoints) {
    test(
      'when calling `askAboutPage` without API key then returns error message',
      () async {
        final response = await endpoints.ai.askAboutPage(
          sessionBuilder,
          'Sample page content',
          'What is this page about?',
        );
        expect(
          response,
          'AI API Key not configured. Please add "aiApiKey" to your config/passwords.yaml file.',
        );
      },
    );
  });
}
