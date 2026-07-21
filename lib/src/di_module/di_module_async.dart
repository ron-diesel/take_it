part of 'base_di_module.dart';

/// An abstract class that represents an asynchronous DI module,
/// extending the functionality
/// of [BaseDiModule] and implementing the [Scope] interface.
///
/// This module is responsible for setting up dependency
/// registrations asynchronously
/// using an [AsyncRegistrar], which handles the registration of async
/// factories and instances.
abstract class DiModuleAsync extends BaseDiModule implements Scope {
  DiModuleAsync({super.dependencies = const []});

  /// Asynchronously sets up the module by registering dependencies
  /// into the provided [AsyncRegistrar].
  ///
  /// This method should be implemented by subclasses
  /// to define the asynchronous dependency
  /// registration logic, including registering async singletons
  /// and factories that will be used
  /// within the module's scope.
  ///
  /// - [it]: The [AsyncRegistrar] used for registering
  /// dependencies asynchronously.
  ///
  /// Returns a [Future] that completes once the setup is done.
  Future<void> setup(AsyncRegistrar it);
}
