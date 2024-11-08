import 'dart:convert';

import 'package:demo_print_api_pos/const.dart';
import 'package:demo_print_api_pos/model/template_printer.dart';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> getAllTemplatePrinter() async {
  try {
    var response = await http.get(
      Uri.parse("http://api-v2.masterpro.vn//api/invoiceforms/getAllWeb"),
      headers: {
        'Authorization': 'Bearer $bearerToken',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body);
      List<TemplatePrinter> templatePrinter =
          (jsonDecode(jsonData) as List<dynamic>)
              .map(
                (e) => TemplatePrinter.fromJson(e),
              )
              .toList();
      return {
        'status': 1,
        'data': templatePrinter,
        'error': null,
      };
    } else {
      return {
        'status': 0,
        'data': null,
        'error': "Fail to load data",
      };
    }
  } catch (e) {
    return {
      'status': 0,
      'data': null,
      'error': e.toString(),
    };
  }
}
