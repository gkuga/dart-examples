import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';
part 'models.g.dart';

@freezed
class MyClass with _$MyClass {
  factory MyClass({String? a, int? b}) = _MyClass;
}

@freezed
class Union with _$Union {
  const factory Union(int value) = Data;
  const factory Union.loading() = Loading;
  const factory Union.error([String? message]) = ErrorDetails;
  const factory Union.complex(int a, String b) = Complex;

  factory Union.fromJson(Map<String, Object?> json) => _$UnionFromJson(json);
}

@freezed
class SharedProperty with _$SharedProperty {
  factory SharedProperty.person({
    String? name,
    int? age,
  }) = SharedProperty0;

  factory SharedProperty.city({
    String? name,
    int? population,
  }) = SharedProperty1;
}
