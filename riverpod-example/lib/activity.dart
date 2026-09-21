import 'package:freezed_annotation/freezed_annotation.dart';

part 'activity.freezed.dart';
part 'activity.g.dart';

/// The response of the Bored API's random-activity endpoint.
///
/// It is defined using `freezed` and `json_serializable`.
///
/// The fields follow what the API actually returns today. The original
/// `boredapi.com` example carried a `key` field; that host is gone and its
/// successor does not return one.
@freezed
class Activity with _$Activity {
  factory Activity({
    required String activity,
    required String type,
    required int participants,
    required double price,
  }) = _Activity;

  /// Convert a JSON object into an [Activity] instance.
  /// This enables type-safe reading of the API response.
  factory Activity.fromJson(Map<String, dynamic> json) =>
      _$ActivityFromJson(json);
}
