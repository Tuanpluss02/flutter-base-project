// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../../src/core/storage/session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Session _$SessionFromJson(Map<String, dynamic> json) => _Session(
  accessToken: json['access_token'] as String,
  refreshToken: json['refresh_token'] as String,
  tokenType: json['token_type'] as String,
  expiresAt: DateTime.parse(json['expires_at'] as String),
);

Map<String, dynamic> _$SessionToJson(_Session instance) => <String, dynamic>{
  'access_token': instance.accessToken,
  'refresh_token': instance.refreshToken,
  'token_type': instance.tokenType,
  'expires_at': instance.expiresAt.toIso8601String(),
};

_SessionRecord _$SessionRecordFromJson(Map<String, dynamic> json) =>
    _SessionRecord(
      status: $enumDecode(_$SessionStatusEnumMap, json['status']),
      session: json['session'] == null
          ? null
          : Session.fromJson(json['session'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SessionRecordToJson(_SessionRecord instance) =>
    <String, dynamic>{
      'status': _$SessionStatusEnumMap[instance.status]!,
      'session': ?instance.session?.toJson(),
    };

const _$SessionStatusEnumMap = {
  SessionStatus.active: 'active',
  SessionStatus.logoutPending: 'logoutPending',
  SessionStatus.sessionInvalidationPending: 'sessionInvalidationPending',
  SessionStatus.signedOut: 'signedOut',
};
