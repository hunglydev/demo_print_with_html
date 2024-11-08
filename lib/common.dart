import 'dart:convert';
import 'dart:typed_data';

String decodeBase64ToHtml(String base64String) {
  // Giải mã Base64 thành bytes
  Uint8List bytes = base64Decode(base64String);

  // Chuyển bytes thành chuỗi UTF-8
  String htmlContent = utf8.decode(bytes);

  return htmlContent;
}
