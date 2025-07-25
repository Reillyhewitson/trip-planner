import 'package:envied/envied.dart';

part 'environment.g.dart';

@Envied(obfuscate: true, allowOptionalFields: true, requireEnvFile: true)
abstract class Env {
  @EnviedField(varName: 'MAPSAPI')
  static String? mapsApi = _Env.mapsApi;
  @EnviedField(varName: "NAVITIMEAPI")
  static String? navitime = _Env.navitime;
}
