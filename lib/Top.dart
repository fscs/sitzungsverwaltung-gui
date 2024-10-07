import 'package:uuid/uuid.dart';

class Top {
  final Uuid id;
  final TopKind kind;
  final String name;
  final int weight;

  const Top({
    required this.kind,
    required this.id,
    required this.name,
    required this.weight,
  });

  factory Top.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'id': Uuid id,
        'kind': TopKind kind,
        'name': String name,
        'weight': int weight,
      } =>
        Top(
          kind: kind,
          id: id,
          name: name,
          weight: weight,
        ),
      _ => throw const FormatException('Failed to load Top.'),
    };
  }
}

enum TopKind { regularia, bericht, normal, verschiedenes }
