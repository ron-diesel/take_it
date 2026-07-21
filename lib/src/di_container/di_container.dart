// ignore_for_file: avoid_annotating_with_dynamic
import 'dart:async';

import 'package:take_it/src/di_container/entity.dart';
import 'package:take_it/take_it.dart';

class DiContainer implements SyncRegistrar, AsyncRegistrar {
  DiContainer();

  DiContainer.fromScope(DiContainer parent) {
    _parentEntities.addAll(parent._parentEntities);
    _parentEntities.addAll(parent._entities);
  }

  final Map<Type, Entity> _entities = {};
  final Map<Type, _DisposerWrapper> _disposers = {};

  final Map<Type, Entity> _parentEntities = {};

  @override
  void registerFactory<T extends Object>(
    CreateFunc<T> create,
  ) {
    _checkScope<T>();
    _entities[T] = Factory<T>(create);
  }

  @override
  void registerFactoryParam<T extends Object, P>(CreateFuncParam<T, P> create) {
    _checkScope<T>();
    _entities[T] = FactoryParam<T, P>(create);
  }

  @override
  T registerSingleton<T extends Object>(
    T instance, {
    DisposeFunc<T>? dispose,
  }) {
    _checkScope<T>();
    _entities[T] = Singleton<T>(instance);
    if (dispose != null) {
      _disposers[T] = _DisposerWrapper((instance) => dispose(instance as T));
    }
    return instance;
  }

  @override
  void registerLazySingleton<T extends Object>(
    CreateFunc<T> create, {
    DisposeFunc<T>? dispose,
  }) {
    _checkScope<T>();
    _entities[T] = Singleton<T>.lazy(create);
    if (dispose != null) {
      _disposers[T] = _DisposerWrapper((instance) => dispose(instance as T));
    }
  }

  T get<T extends Object>({dynamic param}) {
    if (_entities.containsKey(T)) {
      return _entities[T]!.getObject(param) as T;
    }
    if (_parentEntities.containsKey(T)) {
      return _parentEntities[T]!.getObject(param) as T;
    }
    throw Exception("Service of type $T not found");
  }

  Future<void> _dispose() async {
    for (var name in _disposers.keys) {
      if (_disposers.containsKey(name) && _entities.containsKey(name)) {
        await _disposers[name]!.dispose(_entities[name]!.getObject());
        _entities.remove(name);
      }
    }
  }

  @override
  void registerSingletonAsync<T extends Object>(
    CreateAsyncFunc<T> create, {
    DisposeFunc<T>? dispose,
  }) {
    _checkScope<T>();
    _entities[T] = SingletonAsync<T>(create);
    if (dispose != null) {
      _disposers[T] = _DisposerWrapper((instance) => dispose(instance as T));
    }
  }

  Future<void> allReady() async {
    await Future.wait(
      _entities.values
          .whereType<SingletonAsync>()
          .map((entity) => entity.createAsync()),
    );
  }

  Future<void> reset() async {
    await _dispose();
    _entities.clear();
  }

  bool isRegistered<T>() {
    return _entities.containsKey(T) ? true : _parentEntities.containsKey(T);
  }

  Future<void> updateScope(DiContainer? parent) async {
    _parentEntities.clear();
    if (parent != null) {
      _parentEntities.addAll(parent._parentEntities);
      _parentEntities.addAll(parent._entities);
    }
  }

  void mergeFrom(DiContainer other) {
    _parentEntities.addAll(other._parentEntities);
    _parentEntities.addAll(other._entities);
  }

  void _checkScope<T>() {
    if (_entities.containsKey(T)) {
      throw Exception("$T is already registered in current scope");
    }
  }
}

class _DisposerWrapper {
  _DisposerWrapper(this.dispose);

  final DisposeFunc dispose;
}
