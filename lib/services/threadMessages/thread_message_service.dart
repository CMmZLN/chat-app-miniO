import 'package:dio/dio.dart';
import 'package:flutter_frontend/dotenv.dart';
import 'package:flutter_frontend/model/Thread.dart';
import 'package:retrofit/http.dart';

part 'thread_message_service.g.dart';

@RestApi(baseUrl: '$baseUrl/thread')
abstract class ThreadService {
  factory ThreadService(Dio dio) => _ThreadService(dio);

  @GET('')
  Future<Threads> getAllThreads(
      @Query('user_id') int userId, @Header('Authorization') String token);
}
