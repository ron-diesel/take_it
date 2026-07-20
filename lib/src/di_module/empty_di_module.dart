import 'package:take_it/src/di_module/base_di_module.dart';
import 'package:take_it/src/registrar/sync_registrar.dart';

class EmptyDiModule extends DiModule {
  @override
  void setup(SyncRegistrar it) {}
}
