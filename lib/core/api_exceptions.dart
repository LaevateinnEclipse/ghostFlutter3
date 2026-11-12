import 'package:dio/dio.dart';

/// Исключения предметной области.
///
/// Виджеты не знают о Dio: наружу из сетевого слоя выходят только эти типы.
sealed class ApiException implements Exception {
  final String message;

  const ApiException(this.message);

  @override
  String toString() => message;
}

/// Нет соединения, таймаут, сервер недоступен, заблокировано CORS.
class NetworkException extends ApiException {
  const NetworkException([
    super.message = 'Сервер недоступен. Проверьте соединение.',
  ]);
}

/// 401 — не аутентифицирован либо срок действия токена истёк.
class UnauthorizedException extends ApiException {
  const UnauthorizedException([super.message = 'Требуется вход в систему.']);
}

/// 403 — роль не позволяет выполнить операцию.
class ForbiddenException extends ApiException {
  const ForbiddenException([
    super.message = 'Недостаточно прав для этого действия.',
  ]);
}

/// 404.
class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'Запись не найдена.']);
}

/// 409 — нарушено ограничение целостности.
class ConflictException extends ApiException {
  const ConflictException(super.message);
}

/// 422 — ошибки валидации по полям.
class ValidationException extends ApiException {
  final Map<String, String> errors;

  const ValidationException(super.message, this.errors);

  String? errorFor(String field) => errors[field];
}

/// 5xx — сервер упал.
class ServerException extends ApiException {
  const ServerException([
    super.message = 'Ошибка на сервере. Попробуйте позже.',
  ]);
}

/// Запрос отменён: он устарел, потому что условия отбора уже изменились.
class CancelledException extends ApiException {
  const CancelledException([super.message = 'Запрос отменён.']);
}

/// Преобразует HTTP-ответ с кодом ошибки в исключение предметной области.
ApiException mapHttpError(int status, dynamic body) {
  final message = (body is Map && body['message'] is String)
      ? body['message'] as String
      : null;

  return switch (status) {
    401 => UnauthorizedException(message ?? 'Требуется вход в систему.'),
    403 => ForbiddenException(
        message ?? 'Недостаточно прав для этого действия.',
      ),
    404 => NotFoundException(message ?? 'Запись не найдена.'),
    409 => ConflictException(message ?? 'Операция невозможна.'),
    422 => ValidationException(
        message ?? 'Ошибка валидации',
        (body is Map && body['errors'] is Map)
            ? (body['errors'] as Map).map(
                (key, value) => MapEntry('$key', '$value'),
              )
            : const {},
      ),
    _ => ServerException(message ?? 'Неизвестная ошибка (код $status).'),
  };
}

/// Преобразует `DioException` в исключение предметной области.
ApiException mapDioError(DioException error) {
  final existing = error.error;
  if (existing is ApiException) return existing;

  final status = error.response?.statusCode;
  if (status != null && status >= 400) {
    return mapHttpError(status, error.response?.data);
  }

  return switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout =>
      const NetworkException('Сервер не ответил вовремя.'),
    DioExceptionType.connectionError => const NetworkException(
        'Не удалось соединиться с сервером. '
        'Если сервер запущен, откройте консоль браузера и проверьте '
        'наличие ошибки CORS.',
      ),
    DioExceptionType.cancel => const CancelledException(),
    _ => const ServerException(),
  };
}

/// Не выпускает `DioException` наружу: в приложение попадают только
/// исключения предметной области.
Future<T> guard<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on DioException catch (error) {
    throw mapDioError(error);
  }
}
