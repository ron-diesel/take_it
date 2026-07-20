import 'dart:async';

/// An abstract interface for registering non-async factories and instances
/// in a synchronous manner within the current scope.
///
/// Attempting to register a type that is already registered within the
/// current scope will throw an exception. However, if the type is registered
/// in a parent scope, the new registration
/// will shadow the parent's registration
/// for the current and child scopes.
abstract interface class SyncRegistrar {
  /// Registers a factory for creating objects of type [T].
  ///
  /// The [create] function is used to generate a new instance every time
  /// an object of type [T] is requested.
  ///
  /// Throws an exception if [T] is already registered in the current scope.
  void registerFactory<T extends Object>(CreateFunc<T> create);

  /// Registers a factory with a parameter for creating objects of type [T].
  ///
  /// The [create] function accepts a parameter of type [P] and returns
  /// a new instance of [T] based on this parameter.
  ///
  /// This method is useful when retrieving objects with a parameter by using
  /// `scope.get(param)`, allowing you to pass
  /// a dynamic parameter to the factory at runtime.
  ///
  /// Throws an exception if [T] is already registered in the current scope.
  void registerFactoryParam<T extends Object, P>(CreateFuncParam<T, P> create);

  /// Registers an existing instance of type [T] as a singleton.
  ///
  /// The [instance] will always be returned
  /// for any subsequent requests for [T].
  /// Optionally, a [dispose] function can be provided to clean up resources
  /// when the scope is disposed.
  ///
  /// Throws an exception if [T] is already registered in the current scope.
  T registerSingleton<T extends Object>(
    T instance, {
    DisposeFunc<T>? dispose,
  });

  /// Registers a factory that lazily creates a singleton of type [T].
  ///
  /// The [create] function will be called only once, upon the first request
  /// for [T], and the created instance will be reused
  /// for all subsequent requests.
  /// Optionally, a [dispose] function can be provided for resource cleanup.
  ///
  /// Throws an exception if [T] is already registered in the current scope.
  void registerLazySingleton<T extends Object>(
    CreateFunc<T> create, {
    DisposeFunc<T>? dispose,
  });
}

/// Signature for a function that creates instances of type [T].
typedef CreateFunc<T> = T Function();

/// Signature for a function that creates instances of type [T]
/// with a parameter of type [P].
typedef CreateFuncParam<T, P> = T Function(P param);

/// Signature for a function that handles the disposal of instances of type [T].
typedef DisposeFunc<T> = FutureOr<void> Function(T instance);
