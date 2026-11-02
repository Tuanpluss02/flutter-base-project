import 'package:freezed_annotation/freezed_annotation.dart';

part '../../../generated/src/core/scope/data_scope.freezed.dart';

@freezed
abstract class DataScope with _$DataScope {
  const factory DataScope({required String accountId, String? tenantId}) =
      _DataScope;
}
