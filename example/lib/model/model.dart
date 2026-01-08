import 'package:json_annotation/json_annotation.dart';

part 'model.g.dart';

@JsonSerializable()
class MyModel {
  final String value;

  const MyModel({required this.value});

  factory MyModel.fromJson(Map<String, dynamic> json) =>
      _$MyModelFromJson(json);

  Map<String, dynamic> toJson() => _$MyModelToJson(this);
}
