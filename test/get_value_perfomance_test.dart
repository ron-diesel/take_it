import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:take_it/src/di_module/base_di_module.dart';
import 'package:take_it/src/registrar/sync_registrar.dart';

void main() {
  Future<void> runComparisonTestFor(
    WidgetTester widgetTester,
    int containerCount,
    int scopeCount, {
    bool ignoreLogs = false,
  }) async {
    void log(Object? value) {
      if (ignoreLogs) return;
// ignore: avoid_print
      print(value);
    }

    const value = 'val';
    final getIt = GetIt.asNewInstance()
      ..registerFactory<_ValueClass1>(() => _ValueClass1(value))
      ..registerFactory<_ValueClass2>(() => _ValueClass2(value));

    Widget flutterDiWidget = DiScopeBuilder(
      createModule: () => _EmptyModule(),
      builder: (context, scope) {
        final sw = Stopwatch()..start();
        final value = scope.get<_ValueClass1>().value;
        sw.stop();
        final label = 'ComparisonTestFor containers:';
        log("$label $containerCount scopeCount: $scopeCount");
        log('take_it 1: ${sw.elapsedMicroseconds} µs');
        final sw2 = Stopwatch()..start();
        // ignore: unused_local_variable
        final value2 = scope.get<_ValueClass2>().value;
        sw2.stop();
        log('take_it 2: ${sw2.elapsedMicroseconds} µs');
        return Text(value);
      },
    );

    Widget getItWidget = Builder(
      builder: (context) {
        final sw = Stopwatch()..start();
        if (getIt.isRegistered<_ValueClass1>()) {
          // ignore: unused_local_variable
          final value = getIt.get<_ValueClass1>().value;
          sw.stop();
          log('get_it 1: ${sw.elapsedMicroseconds} µs');
        }
        final sw2 = Stopwatch()..start();
        if (getIt.isRegistered<_ValueClass2>()) {
          // ignore: unused_local_variable
          final value2 = getIt.get<_ValueClass2>().value;
          sw2.stop();
          log('get_it 2: ${sw2.elapsedMicroseconds} µs');
        }
        return Text(value);
      },
    );

    Widget wrapWithContainersAndScope(Widget widget) {
      final newWidget = _wrapWithContainers(widget, containerCount);
      final anotherNewWidget = _wrapWithEmptyScopes(newWidget, scopeCount - 1);
      return _wrapWithValueScopes(anotherNewWidget, value, 1);
    }

    await widgetTester.pumpWidget(
      MaterialApp(home: wrapWithContainersAndScope(flutterDiWidget)),
    );

    await widgetTester.pumpWidget(
      MaterialApp(home: wrapWithContainersAndScope(getItWidget)),
    );
  }

  group(
    'Comparison with get_it',
    () {
      const containersCount = 1000;

      final variants = _ScopeCountVariants({
        (containersCount, 1),
        (containersCount, 2),
        (containersCount, 5),
        (containersCount, 10),
        (containersCount, 20),
        (containersCount, 100),
        (containersCount, 1000),
      });

      testWidgets(
        'Warm up',
        (widgetTester) => runComparisonTestFor(
          widgetTester,
          1,
          2,
          ignoreLogs: true,
        ),
      );

      testWidgets(
        'Diff depths',
        variant: variants,
        (widgetTester) => runComparisonTestFor(
          widgetTester,
          variants.currentValue!.$1,
          variants.currentValue!.$2,
        ),
      );
    },
  );
}

class _ScopeCountVariants extends ValueVariant<(int, int)> {
  _ScopeCountVariants(super.values);

  @override
  String describeValue((int, int) value) {
    return 'Containers: ${value.$1}, Scopes: ${value.$2}';
  }
}

Widget _wrapWithContainers(Widget widget, int containerCount) {
  var widgetToReturn = widget;
  for (var i = 0; i < containerCount; i++) {
    final lastWidget = widgetToReturn;
    widgetToReturn = Container(child: lastWidget);
  }
  return widgetToReturn;
}

Widget _wrapWithEmptyScopes(
  Widget widget,
  int scopesCount,
) {
  var widgetToReturn = widget;
  for (var i = 0; i < scopesCount; i++) {
    final lastWidget = widgetToReturn;
    widgetToReturn = DiScopeBuilder(
      createModule: () => _EmptyModule(),
      builder: (_, __) => lastWidget,
    );
  }
  return widgetToReturn;
}

Widget _wrapWithValueScopes(
  Widget widget,
  String value,
  int scopesCount,
) {
  var widgetToReturn = widget;
  for (var i = 0; i < scopesCount; i++) {
    final lastWidget = widgetToReturn;
    widgetToReturn = DiScopeBuilder(
      createModule: () => _ValueDiModule(value),
      builder: (_, __) => lastWidget,
    );
  }
  return widgetToReturn;
}

class _EmptyModule extends DiModule {
  @override
  void setup(SyncRegistrar it) {}
}

class _ValueDiModule extends DiModule {
  _ValueDiModule(this.value);

  final String value;

  @override
  void setup(SyncRegistrar it) {
    it
      ..registerFactory<_ValueClass1>(() => _ValueClass1(value))
      ..registerFactory<_ValueClass2>(() => _ValueClass2(value));
  }
}

class _ValueClass1 {
  const _ValueClass1(this.value);

  final String value;
}

class _ValueClass2 {
  const _ValueClass2(this.value);

  final String value;
}
