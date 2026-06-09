import 'package:bridge_k/core/models/result.dart';
import 'package:bridge_k/core/network/api_error.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('failureFromDioException prefers backend ApiResponse data message', () {
    final RequestOptions requestOptions = RequestOptions(path: '/test');
    final Failure<void> failure = failureFromDioException<void>(
      DioException(
        requestOptions: requestOptions,
        response: Response<dynamic>(
          requestOptions: requestOptions,
          statusCode: 400,
          data: <String, dynamic>{
            'isSuccess': false,
            'code': 'COMMON400',
            'message': '잘못된 요청입니다.',
            'data': '정책이 없습니다.',
          },
        ),
      ),
    );

    expect(failure.message, '정책이 없습니다.');
    expect(failure.cause, 'COMMON400');
  });

  test('errorCodeOf maps backend mission codes to app aliases', () {
    final RequestOptions requestOptions = RequestOptions(path: '/missions/1');
    final DioException exception = DioException(
      requestOptions: requestOptions,
      response: Response<dynamic>(
        requestOptions: requestOptions,
        statusCode: 404,
        data: <String, dynamic>{
          'isSuccess': false,
          'code': 'MISSION404',
          'message': '해당 미션을 찾을 수 없습니다.',
        },
      ),
    );

    expect(errorCodeOf(exception), 'MISSION_NOT_FOUND');
  });
}
