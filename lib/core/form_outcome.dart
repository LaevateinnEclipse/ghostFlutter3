import 'package:flutter/material.dart';

import '../widgets/common.dart';
import 'api_exceptions.dart';
import 'errors.dart';

/// Результат разбора ответа сервера в форме.
sealed class FormOutcome {
  const FormOutcome();
}

class FormSaved extends FormOutcome {
  const FormSaved();
}

/// 422 — ошибки по полям. Ключи совпадают с именами полей модели.
class FormInvalid extends FormOutcome {
  final Map<String, String> errors;
  const FormInvalid(this.errors);
}

/// 409 — понятное сообщение о конфликте.
class FormConflict extends FormOutcome {
  final String message;
  const FormConflict(this.message);
}

class FormFailed extends FormOutcome {
  final String message;
  const FormFailed(this.message);
}

FormOutcome toFormOutcome(Object error) {
  if (error is ValidationException) return FormInvalid(error.errors);
  if (error is FieldValidationException) {
    return FormInvalid({error.field: error.message});
  }
  if (error is ConflictException || error is LinkedRecordsException) {
    return FormConflict(error.toString());
  }
  if (error is ApiException) return FormFailed(error.message);
  return FormFailed('Не удалось сохранить: $error');
}

void showFormError(BuildContext context, FormOutcome outcome) {
  if (outcome is FormConflict) {
    showOperationError(context, ConflictException(outcome.message));
    return;
  }
  final message = switch (outcome) {
    FormConflict(:final message) => message,
    FormFailed(:final message) => message,
    FormInvalid() => 'Проверьте отмеченные поля: сервер отклонил запись.',
    FormSaved() => '',
  };
  if (message.isNotEmpty) toast(context, message);
}

/// Раскладывает 422 по полям, а 409 и прочие ошибки показывает пользователю.
bool consumeFormError(
  BuildContext context,
  Object error, {
  required void Function(String field) reject,
  required void Function(Map<String, String> errors) showOnFields,
}) {
  final outcome = toFormOutcome(error);
  if (outcome is FormInvalid) {
    for (final field in outcome.errors.keys) {
      reject(field);
    }
    showOnFields(outcome.errors);
    return true;
  }
  if (context.mounted) showFormError(context, outcome);
  return false;
}
