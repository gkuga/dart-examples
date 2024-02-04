import 'package:dio/dio.dart';

void main() async {
  final dio = Dio();
  final response = await dio.get('https://pub.dev');
  print(response.data);
}
