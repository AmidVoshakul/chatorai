import 'dart:async';
import 'package:ddgs/ddgs.dart';

void main() async {
  print('Testing ddgs in flutter test...');
  final ddgs = DDGS(timeout: Duration(seconds: 5));

  try {
    print('Calling ddgs.text() with 10s timeout...');
    final results = await ddgs
        .text('dart programming', maxResults: 3, backend: 'duckduckgo')
        .timeout(Duration(seconds: 10));
    print('Got ${results.length} results');
  } catch (e) {
    print('Error: $e');
  } finally {
    ddgs.close();
  }
  print('Done');
}
