import 'package:take_it/src/registrar/sync_registrar.dart';

/// An abstract interface for registering asynchronous instances
/// in a scope, extending the capabilities of [SyncRegistrar]
/// with async operations.
///
/// Attempting to register a type that is already registered within the
/// current scope will throw an exception. However, if the type is registered
/// in a parent scope, the new registration
/// will shadow the parent's registration
/// for the current and child scopes.
abstract interface class AsyncRegistrar implements SyncRegistrar {
  /// Registers a factory that asynchronously creates a singleton of type [T].
  ///
  /// The [create] function will be called once, returning
  /// a `Future` that resolves to an instance of [T].
  /// The created instance will be reused for all subsequent
  /// requests for [T].
  ///
  /// Optionally, a [dispose] function can be provided to clean up
  /// resources when the scope is disposed.
  ///
  /// Throws an exception if [T] is already registered in the current scope.
  void registerSingletonAsync<T extends Object>(
    CreateAsyncFunc<T> create, {
    DisposeFunc<T>? dispose,
  });
}

/// Signature for a function that asynchronously creates instances of type [T].
typedef CreateAsyncFunc<T> = Future<T> Function();
