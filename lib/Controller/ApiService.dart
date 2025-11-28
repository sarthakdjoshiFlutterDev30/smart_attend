import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://smartattendnotification.onrender.com',
      headers: {'Content-Type': 'application/json'},
    ),
  );
  Future<void> sendNotification(String title, String body) async {
    final res = await _dio.post(
      '/send-notification',
      data: {'title': title, 'body': body},
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to send notification');
    }
  }

}
