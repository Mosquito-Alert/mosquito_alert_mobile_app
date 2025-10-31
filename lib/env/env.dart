import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'OLD_PASSWORD', obfuscate: true)
  static final String oldPassword = _Env.oldPassword;
}
