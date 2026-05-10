class User {
  final String uid;
  final String name;
  final String mobileNumber;
  final String city;
  final String zipcode;
  final String email;

  User({
    required this.uid,
    required this.name,
    required this.mobileNumber,
    required this.city,
    required this.zipcode,
    required this.email,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'mobileNumber': mobileNumber,
      'city': city,
      'zipcode': zipcode,
      'email': email,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      mobileNumber: map['mobileNumber'] ?? '',
      city: map['city'] ?? '',
      zipcode: map['zipcode'] ?? '',
      email: map['email'] ?? '',
    );
  }
}