class StudentModel {
  final String id;
  final String name;
  final String email;
  final String enrollment;
  final String course;
  final String semester;
  final String photourl;
  final String? password;
  final String role;

  StudentModel({
    required this.id,
    required this.name,
    required this.email,
    required this.enrollment,
    required this.course,
    required this.semester,
    required this.photourl,
    required this.password,
    required this.role,
  });

  factory StudentModel.fromSnapshot(String id, Map<String, dynamic> json) {
    return StudentModel(
      id: id,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      enrollment: json['enrollment'] ?? '',
      course: json['course'] ?? '',
      semester: json['semester'] ?? '',
      photourl: json['photourl'] ?? '',
      password: json['password'] ?? '',
      role: json['role'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'enrollment': enrollment,
      'course': course,
      'semester': semester,
      'photourl': photourl,
      'role': role,
    };
  }
}
