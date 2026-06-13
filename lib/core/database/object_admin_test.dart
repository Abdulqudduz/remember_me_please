import 'dart:io';

void testObjectBoxAdmin() async {
  try {
    final request = await HttpClient().getUrl(
      Uri.parse('http://127.0.0.1:8090'),
    );
    final response = await request.close();
    print('STATUS: ${response.statusCode}');
  } catch (e) {
    print('ERROR: $e');
  }
}
