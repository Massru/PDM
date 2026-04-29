class Person {
  final String id;
  final String name;

  const Person({required this.id, required this.name});

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory Person.fromJson(Map<String, dynamic> json) =>
      Person(id: json['id'], name: json['name']);
}