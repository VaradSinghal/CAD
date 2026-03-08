import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  var url = Uri.parse('https://jsonbox.io/box_cad_game_varad_test');
  
  print('Testing jsonbox.io...');
  try {
    var res = await http.post(url, 
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"scores": [{"name": "Varad", "score": 100}]}));
    print('POST status: \${res.statusCode}');
    print('POST body: \${res.body}');
    
    var res2 = await http.get(url);
    print('GET status: \${res2.statusCode}');
    print('GET body: \${res2.body}');
  } catch (e) {
    print('Error: \$e');
  }
}
