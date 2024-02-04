import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'api.dart';

final logger = Logger();

void main(List<String> args) {
  logger.d("Logger is working!");
  logger.i("start");
  final dio = Dio(); // Provide a dio instance
  dio.options.headers['Demo-Header'] =
      'demo header'; // config your dio headers globally
  final client = RestClient(dio);

  client.getTasks().then((it) => it.forEach((task){print(task.name);}));
  logger.e("finish");
}
