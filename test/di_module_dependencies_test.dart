import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:take_it/src/di_module/base_di_module.dart';
import 'package:take_it/src/registrar/sync_registrar.dart';

// ignore_for_file: prefer_const_constructors

class _ModuleA extends DiModule {
  @override
  void setup(SyncRegistrar it) {
    it.registerFactory<String>(() => 'A');
  }
}

class _ModuleB extends DiModule {
  @override
  void setup(SyncRegistrar it) {
    it.registerFactory<String>(() => 'B');
    it.registerFactory<double>(() => 2.0);
  }
}

class _ModuleC extends DiModule {
  @override
  void setup(SyncRegistrar it) {
    it.registerFactory<int>(() => 42);
  }
}

class _ModuleBWithDepC extends DiModule {
  _ModuleBWithDepC() : super(dependencies: [_ModuleC()]);

  @override
  void setup(SyncRegistrar it) {
    it.registerFactory<double>(() => 2.0);
  }
}

bool _disposed = false;

class _DisposableModule extends DiModule {
  @override
  void setup(SyncRegistrar it) {
    it.registerSingleton<String>(
      'dep_value',
      dispose: (_) {
        _disposed = true;
      },
    );
  }
}

class _MainWithDisposableDep extends DiModule {
  _MainWithDisposableDep() : super(dependencies: [_DisposableModule()]);

  @override
  void setup(SyncRegistrar it) {
    it.registerFactory<int>(() => 1);
  }
}

void main() {
  testWidgets(
    '1. dep registrations are visible from main module',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DiScopeBuilder(
            createModule: () => DiModule$WithDep([_ModuleA()]),
            builder: (context, scope) {
              return Text(scope.get<String>());
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('A'), findsOneWidget);
    },
  );

  testWidgets(
    '2. last dep overrides first dep for same type',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DiScopeBuilder(
            createModule: () => _MainNoOwnString([_ModuleA(), _ModuleB()]),
            builder: (context, scope) {
              return Text(scope.get<String>());
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      // B is last → wins
      expect(find.text('B'), findsOneWidget);
    },
  );

  testWidgets(
    '3. main module own registration overrides dep registration',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DiScopeBuilder(
            createModule: () => _MainOverridesString([_ModuleA()]),
            builder: (context, scope) {
              return Text(scope.get<String>());
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('own'), findsOneWidget);
    },
  );

  testWidgets(
    '4. dep registration overrides widget-tree parent registration',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DiScopeBuilder(
            createModule: _ModuleA.new, // registers String='A' as parent
            builder: (context, _) {
              return DiScopeBuilder(
                createModule: () => _MainNoOwnString([_ModuleB()]),
                builder: (context, scope) {
                  return Text(scope.get<String>());
                },
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      // dep B ('B') overrides widget-tree parent A ('A')
      expect(find.text('B'), findsOneWidget);
    },
  );

  testWidgets(
    '5. dep is disposed when main module is disposed',
    (tester) async {
      _disposed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: DiScopeBuilder(
            createModule: _MainWithDisposableDep.new,
            builder: (context, scope) => const SizedBox(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_disposed, isFalse);

      // Remove the widget → dispose
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pumpAndSettle();

      expect(_disposed, isTrue);
    },
  );

  testWidgets(
    '6. notifyListeners from widget-tree parent '
    'does not lose dep registrations',
    (tester) async {
      late _ModuleA parentModule;

      await tester.pumpWidget(
        MaterialApp(
          home: DiScopeBuilder(
            createModule: () {
              parentModule = _ModuleA();
              return parentModule;
            },
            builder: (context, _) {
              return DiScopeBuilder(
                createModule: () => _MainNoOwnString([_ModuleB()]),
                builder: (context, scope) {
                  return Text(scope.get<String>());
                },
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('B'), findsOneWidget);

      parentModule.notifyListeners();
      await tester.pump();

      // After parent notification, dep entities must still be accessible
      expect(find.text('B'), findsOneWidget);
    },
  );

  testWidgets(
    '7. recursive deps: A(deps:[B(deps:[C])]) — C registrations visible from A',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DiScopeBuilder(
            createModule: () => _MainNoOwnInt([_ModuleBWithDepC()]),
            builder: (context, scope) {
              return Text('${scope.get<int>()}');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('42'), findsOneWidget);
    },
  );
}

// Helper modules defined inline to avoid cluttering top-level

class DiModule$WithDep extends DiModule {
  DiModule$WithDep(List<BaseDiModule> deps) : super(dependencies: deps);

  @override
  void setup(SyncRegistrar it) {}
}

class _MainNoOwnString extends DiModule {
  _MainNoOwnString(List<BaseDiModule> deps) : super(dependencies: deps);

  @override
  void setup(SyncRegistrar it) {}
}

class _MainNoOwnInt extends DiModule {
  _MainNoOwnInt(List<BaseDiModule> deps) : super(dependencies: deps);

  @override
  void setup(SyncRegistrar it) {}
}

class _MainOverridesString extends DiModule {
  _MainOverridesString(List<BaseDiModule> deps) : super(dependencies: deps);

  @override
  void setup(SyncRegistrar it) {
    it.registerFactory<String>(() => 'own');
  }
}
