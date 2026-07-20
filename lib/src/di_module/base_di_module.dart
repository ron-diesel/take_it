// ignore_for_file: avoid_annotating_with_dynamic

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:take_it/src/di_container/di_container.dart';
import 'package:take_it/src/di_module/empty_di_module.dart';
import 'package:take_it/take_it.dart';

part '../di_scope_builder.dart';

part '../di_scope_root.dart';

part 'di_module.dart';

part 'di_module_async.dart';

/// Base class for managing Dependency Injection (DI) modules
/// in the application.
/// It provides the core logic for setting up, resetting, and managing scopes of
/// dependency registrations.
///
/// This class is sealed and extends [ChangeNotifier], which means it can notify
/// listeners about changes in the state.
sealed class BaseDiModule extends ChangeNotifier implements Scope {
  DiContainer _diContainer = DiContainer();

  bool _isInitialized = false;

  /// Asynchronously initializes the DI module.
  ///
  /// Depending on whether the module is synchronous
  /// or asynchronous ([DiModule] or [DiModuleAsync]),
  /// it sets up the internal [DiContainer] and marks the module as initialized.
  /// Returns a [Future] that completes once the initialization process is done.
  /// You can use it for initialize with native app splash screen
  Future<void> init() async {
    final completer = Completer();
    _init(() => completer.complete(), isNeedNotify: false);
    return completer.future;
  }

  /// Initializes the DI module
  /// by setting up the internal [DiContainer] and calling [onInit]
  /// after the setup process is complete.
  ///
  /// - [onInit]: Callback to be executed when initialization completes.
  /// - [isNeedNotify]: If `true`, notifies listeners after initialization.
  void _init(Function() onInit, {bool isNeedNotify = true}) {
    final module = this;

    switch (module) {
      case DiModule():
        module.setup(_diContainer);
        onInit();
        break;
      case DiModuleAsync():
        module.setup(_diContainer).then(
              (_) => _diContainer.allReady().then(
                    (_) => onInit(),
                  ),
            );
        break;
    }

    _isInitialized = true;
    if (isNeedNotify) _notify();
  }

  /// Notifies all listeners about changes in the module state.
  void _notify() {
    notifyListeners();
  }

  /// Pushes the current module's scope onto the stack and sets up the internal
  /// [DiContainer] by optionally inheriting the parent module's scope.
  ///
  /// - [onInit]: Callback to be executed after the scope is initialized.
  /// - [parent]: The parent DI module from which to inherit the scope.
  void _pushScope(Function() onInit, BaseDiModule? parent) {
    if (parent != null) {
      _diContainer = DiContainer.fromScope(parent._diContainer);
    }

    _init(onInit, isNeedNotify: false);
  }

  /// Updates the current module's scope with the parent module's scope.
  ///
  /// - [parent]: The parent DI module whose scope will be used for updating.
  void _updateScope(BaseDiModule? parent) {
    _diContainer.updateScope(parent?._diContainer);
  }

  /// Pops the current scope
  /// from the stack and resets the internal [DiContainer].
  ///
  /// Returns a [Future] that completes once the scope has been reset.
  Future<void> _popScope() async {
    await _reset(isNeedNotify: false);
  }

  /// Resets the current module's scope
  /// and optionally notifies listeners about the change.
  ///
  /// - [isNeedNotify]: If `true`, notifies listeners after the reset.
  Future<void> _reset({bool isNeedNotify = true}) async {
    await _diContainer.reset();
    if (isNeedNotify) _notify();
  }

  @visibleForTesting
  Future<void> resetTest() {
    return _reset();
  }

  @override
  bool isRegistered<T extends Object>() {
    return _diContainer.isRegistered<T>();
  }

  @override
  T get<T extends Object>({
    dynamic param,
  }) {
    if (isRegistered<T>()) {
      return _diContainer.get<T>(param: param);
    }
    throw Exception(
      "Error: Instance of type $T is not registered within $runtimeType or "
      "its subtree Scope. Please ensure that $T is correctly registered and "
      "available in the appropriate context.",
    );
  }

  @override
  T? safeGet<T extends Object>({
    dynamic param,
  }) {
    return isRegistered<T>()
        ? get<T>(
            param: param,
          )
        : null;
  }
}
