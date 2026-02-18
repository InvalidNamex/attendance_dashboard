class ApiEndpoints {
  ApiEndpoints._();

  static const String login = '/users/login';
  static const String users = '/users/';
  static String user(int id) => '/users/$id';
  static const String settings = '/settings/';
  static const String transactions = '/transactions/';
  static String transaction(int id) => '/transactions/$id';
}
