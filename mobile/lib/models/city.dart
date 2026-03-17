/// Desteklenen bir il.
class City {
  final String key;
  final String displayName;

  const City({required this.key, required this.displayName});

  factory City.fromJson(Map<String, dynamic> json) => City(
        key: json['key'] as String,
        displayName: json['display_name'] as String,
      );

  @override
  String toString() => displayName;
}
