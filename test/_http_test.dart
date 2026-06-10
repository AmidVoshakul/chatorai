import 'package:http/http.dart' as http;

void main() async {
  print('Testing http.Client...');
  final client = http.Client();

  try {
    print('GET https://html.duckduckgo.com/html/?q=test');
    final resp = await client
        .get(
          Uri.parse('https://html.duckduckgo.com/html/?q=test&l=wt-wt&p=-1'),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36',
          },
        )
        .timeout(Duration(seconds: 10));
    print('Status: ${resp.statusCode}');
    print('Body length: ${resp.body.length}');
  } catch (e) {
    print('Error: $e');
  } finally {
    client.close();
  }
}
