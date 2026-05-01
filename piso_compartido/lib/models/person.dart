/// Representa a un inquilino del piso.
/// Usamos un ID único (uuid) en lugar del nombre como identificador
/// porque dos personas pueden llamarse igual, y además permite
/// renombrar sin romper referencias en los gastos.
class Person {
  final String id;   // UUID generado al crear el piso
  final String name; // Nombre visible en la UI

  const Person({required this.id, required this.name});

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory Person.fromJson(Map<String, dynamic> json) =>
      Person(id: json['id'], name: json['name']);
}