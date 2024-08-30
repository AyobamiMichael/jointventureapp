class User {
  final String userid;
  final String username;
  final String email;
  final String password; // Add password field

  User({
    required this.userid,
    required this.username,
    required this.email,
    required this.password,
  });
}

// Example mock data
final List<User> mockUsers = [
  User(
      userid: '1',
      username: 'user1',
      email: 'user1@example.com',
      password: 'pass123'),
  User(
      userid: '2',
      username: 'user2',
      email: 'user2@example.com',
      password: 'pass456'),
  User(
      userid: '3',
      username: 'user3',
      email: 'user3@example.com',
      password: 'pass789'),
];
