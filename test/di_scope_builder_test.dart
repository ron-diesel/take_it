import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:take_it/src/di_module/base_di_module.dart';
import 'package:take_it/src/registrar/sync_registrar.dart';

int count = 0;

class MockModule extends DiModule {
  @override
  void setup(SyncRegistrar it) {
    it.registerFactory(() => get<int>().toString());
  }
}

class MockParentModule extends DiModule {
  @override
  void setup(SyncRegistrar it) {
    count++;
    final result = count;
    it.registerFactory(() => result);
  }
}

void main() {
  testWidgets('didChangeDependencies is called and module is reinitialized',
      (tester) async {
    final module = MockModule();
    final builderKey = GlobalKey();
    await module.init();

    Widget uut({Key? key}) => MaterialApp(
          key: key,
          home: DiScopeBuilder(
            createModule: () => MockParentModule(),
            builder: (context, scope) {
              return DiScopeBuilder(
                key: builderKey,
                createModule: () => module,
                builder: (context, module) {
                  return const Text('DiScopeBuilder Test');
                },
              );
            },
          ),
        );

    await tester.pumpWidget(uut());

    var context = tester.element(find.text('DiScopeBuilder Test'));
    var state =
        context.findAncestorStateOfType<DiScopeBuilderState>()!;

    expect(state.module, isNotNull);
    expect(state.module!.get<int>(), count);
    expect(state.module!.get<String>(), count.toString());
    expect(state.isInitialized, isTrue);

    // didChangeDependencies
    await tester.pumpWidget(uut(key: UniqueKey()));

    context = tester.element(find.text('DiScopeBuilder Test'));
    state = context.findAncestorStateOfType<DiScopeBuilderState>()!;

    expect(state.module, isNotNull);
    expect(state.module!.get<int>(), count);
    expect(state.module!.get<String>(), count.toString());
    expect(state.isInitialized, isTrue);
  });

  testWidgets(
    'parent notifyListeners (e.g. via navigation) does not recreate '
    'an already-created child module',
    (tester) async {
      var createCount = 0;
      late MockParentModule parentModule;

      await tester.pumpWidget(
        MaterialApp(
          home: DiScopeBuilder(
            createModule: () {
              parentModule = MockParentModule();
              return parentModule;
            },
            builder: (context, parentScope) {
              return DiScopeBuilder(
                createModule: () {
                  createCount++;
                  return MockModule();
                },
                builder: (context, module) {
                  return const Text('DiScopeBuilder Test');
                },
              );
            },
          ),
        ),
      );

      expect(createCount, 1);

      var context = tester.element(find.text('DiScopeBuilder Test'));
      final childState =
          context.findAncestorStateOfType<DiScopeBuilderState>()!;
      final childModule = childState.module;

      // Simulate what happens on navigation: an ancestor module (e.g. used
      // as a GoRouter refreshListenable) notifies its listeners without the
      // widget tree itself changing.
      parentModule.notifyListeners();
      await tester.pump();

      expect(
        createCount,
        1,
        reason: 'createModule must not be invoked again on a plain '
            'dependency notification',
      );
      expect(childState.module, same(childModule));
    },
  );
}
