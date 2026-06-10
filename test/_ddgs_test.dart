import 'package:ddgs/ddgs.dart';

void main() async {
  print('Testing ddgs...');
  final ddgs = DDGS(timeout: Duration(seconds: 10));

  try {
    print('Calling ddgs.text()...');
    final results = await ddgs
        .text('dart programming', maxResults: 3, backend: 'duckduckgo')
        .timeout(Duration(seconds: 15));
    print('Got ${results.length} results');
    for (final r in results.take(3)) {
      print('  - ${r['title']}: ${r['href']}');
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    ddgs.close();
  }
}
