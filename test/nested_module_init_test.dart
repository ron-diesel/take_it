import 'package:flutter_test/flutter_test.dart';
import 'package:take_it/src/di_module/base_di_module.dart';
import 'package:take_it/src/registrar/sync_registrar.dart';

/// Verifies what happens when a module's [DiModule.setup] is called manually
/// inside another module's [DiModule.setup] with the same registrar, e.g.:
///
/// ```dart
/// class ModuleA extends DiModule {
///   @override
///   void setup(SyncRegistrar it) {
///     ModuleB().setup(it);
///   }
/// }
/// ```
///
/// This is composition, not scope inheritance: module B registers its
/// services directly into module A's container, so everything ends up in
/// one shared scope. The B instance itself is never initialized and cannot
/// be used as a scope on its own.
void main() {
  group("Module composed via setup(it) inside another module's setup()", () {
    late _ModuleA moduleA;

    setUp(() async {
      moduleA = _ModuleA();
      await moduleA.init();
    });

    test("registers the nested module's services into the outer scope", () {
      expect(moduleA.isRegistered<_ServiceA>(), isTrue);
      expect(moduleA.isRegistered<_ServiceB>(), isTrue);
      expect(moduleA.get<_ServiceB>(), isA<_ServiceB>());
    });

    test("the nested module instance itself remains unusable as a scope", () {
      final moduleB = moduleA.nestedModule!;

      expect(moduleB.isRegistered<_ServiceB>(), isFalse);
      expect(() => moduleB.get<_ServiceB>(), throwsException);
    });
  });
}

class _ServiceA {}

class _ServiceB {}

class _ModuleA extends DiModule {
  _ModuleB? nestedModule;

  @override
  void setup(SyncRegistrar it) {
    it.registerSingleton(_ServiceA());

    nestedModule = _ModuleB()..setup(it);
  }
}

class _ModuleB extends DiModule {
  @override
  void setup(SyncRegistrar it) {
    it.registerSingleton(_ServiceB());
  }
}
