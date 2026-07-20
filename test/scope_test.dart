import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:take_it/src/di_module/base_di_module.dart';
import 'package:take_it/src/registrar/sync_registrar.dart';

void main() {
  final blueKey = Key("blue_key");


  Widget getUut() => MaterialApp(
        home: DiScopeBuilder(
            createModule: () => _RedDiModule(),
            builder: (context, module) {
              return Column(
                children: [
                  DiScopeBuilder(
                      createModule: () => _GreenDiModule(),
                      builder: (context, module) {
                        return Text(
                          module.get(),
                          style: TextStyle(color: Colors.green),
                        );
                      }),
                  DiScopeBuilder(
                    key: blueKey,
                      createModule: () => _BlueDiModule(),
                      builder: (context, module) {
                        return Column(
                          children: [
                            Text(
                              module.get(),
                              style: TextStyle(color: Colors.blue),
                            ),
                            Builder(
                              builder: (context) {
                                return DiScopeBuilder(
                                    createModule: () => _EmptyDiModule(),
                                    builder: (context, module) {
                                      return Text(
                                        module.get(),
                                        style: TextStyle(color: Colors.black),
                                      );
                                    });
                              }
                            ),
                          ],
                        );
                      }),
                  Text(
                    module.get(),
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              );
            }),
      );

  Finder findTextByColor(Color color) {
    return find.byWidgetPredicate(
        (widget) => widget is Text && widget.style?.color == color);
  }

  group("Scope tests", () {
    testWidgets("Value inheritance and override", (tester) async {
      await tester.pumpWidget(getUut());
      await tester.pumpAndSettle();

      final redTextWidget = tester.widget<Text>(findTextByColor(Colors.red));
      final greenTextWidget =
          tester.widget<Text>(findTextByColor(Colors.green));
      final blueTextWidget = tester.widget<Text>(findTextByColor(Colors.blue));
      final blackTextWidget =
          tester.widget<Text>(findTextByColor(Colors.black));

      expect(redTextWidget.data, 'red');

      /// override check
      expect(greenTextWidget.data, 'green');
      expect(blueTextWidget.data, 'blue');

      /// inheritance check
      expect(blackTextWidget.data, 'blue');
    });

    testWidgets("Remove dependency", (tester) async {
      await tester.pumpWidget(getUut());
      await tester.pumpAndSettle();

      final blueDiScopeFinder = find.byKey(blueKey);

      final blueDiScopeBuilderState =
      tester.state<DiScopeBuilderState>(blueDiScopeFinder);

      blueDiScopeBuilderState.module?.resetTest();
      await tester.pumpAndSettle();
      final blackTextWidget =
      tester.widget<Text>(findTextByColor(Colors.black));
      expect(blackTextWidget.data, 'red');
    });
  });
}

class _RedDiModule extends DiModule {
  @override
  void setup(SyncRegistrar it) {
    it.registerFactory(() => "red");
  }
}

class _GreenDiModule extends DiModule {
  @override
  void setup(SyncRegistrar it) {
    it.registerFactory(() => "green");
  }
}

class _BlueDiModule extends DiModule {
  @override
  void setup(SyncRegistrar it) {
    it.registerFactory(() => "blue");
  }
}

class _EmptyDiModule extends DiModule {
  @override
  void setup(SyncRegistrar it) {
  }
}
