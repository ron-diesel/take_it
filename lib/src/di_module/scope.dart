// ignore_for_file: avoid_annotating_with_dynamic

/// An abstract interface for the take_it scope,
/// which provides access to registered objects.
abstract interface class Scope {
  /// Checks whether an object of the specified type [T] is registered
  /// within the current scope.
  ///
  /// Returns `true` if an instance of type [T] is registered,
  /// otherwise `false`.
  bool isRegistered<T extends Object>();

  /// Retrieves an object of the specified type [T] that is registered
  /// in the current scope.
  ///
  /// If a factory with parameters was registered using `registerFactoryParam`,
  /// the [param] argument can be passed to provide parameters to the factory.
  ///
  /// Throws an exception if no instance of type [T] is registered.
  T get<T extends Object>({
    dynamic param,
  });

  /// Attempts to retrieve an object of the specified
  /// type [T] that is registered in the current scope.
  ///
  /// If an object of type [T] is not registered, this method returns `null`
  /// instead of throwing an exception.
  ///
  /// [param] can be provided for factories registered with parameters.
  T? safeGet<T extends Object>({
    dynamic param,
  });
}
