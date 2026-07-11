import 'package:chatorai/core/permission/permission_service.dart';

void main() {
  final e = PermissionDeniedError('test', '*');
  print(e is Exception);
  print(e is PermissionDeniedError);
}
