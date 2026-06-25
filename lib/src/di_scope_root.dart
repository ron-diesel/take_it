part of 'di_module/base_di_module.dart';

/// A root widget that provides the given [BaseDiModule]
/// to the entire widget tree.
///
/// [DiScopeRoot] serves as the entry point
/// for dependency injection (DI) in the app.
/// It ensures that the provided [BaseDiModule] is correctly initialized before
/// being exposed to the widget tree via an internal [_ParentModuleProvider].
///
/// Example usage:
/// ```dart
/// Future<void> main() async {
///   // Ensures that Flutter engine and bindings are fully initialized
///   WidgetsFlutterBinding.ensureInitialized();
///
///   // Create and asynchronously initialize the module
///   final module = MyAppModule();
///   await module.init();
///
///   // Provide the module to the widget tree
///   runApp(
///     DiScopeRoot(
///       module: module,
///       app: MaterialApp(
///         home: MyHomePage(),
///       ),
///     ),
///   );
/// }
/// ```
///
/// - [module]: The root DI module that manages dependencies
/// for the application.
/// - [app]: The root widget of the application
/// (commonly a [MaterialApp] or [CupertinoApp])
///   that will consume the provided DI scope.
class DiScopeRoot extends StatelessWidget {
  const DiScopeRoot({
    required this.module,
    required this.app,
    super.key,
  });

  /// The root dependency injection module.
  final BaseDiModule module;

  /// The root application widget
  /// that will have access to the provided DI module.
  final Widget app;

  @override
  Widget build(BuildContext context) {
    assert(
      module._isInitialized,
      "BaseDiModule must be initialized before being passed into DiScopeRoot.",
    );
    assert(
      _ParentModuleProvider.of(context) == null,
      "Another BaseDiModule is already provided higher in the widget tree. "
      "Ensure that DiScopeRoot is only used once at the top level of your app.",
    );

    return _ParentModuleProvider(
      module: module,
      key: null,
      // Using null ensures the provider is not unnecessarily rebuilt.
      child: app,
    );
  }
}

/// Provides the parent [BaseDiModule]
/// to the widget tree via [InheritedNotifier].
///
/// This widget acts as a bridge between the [BaseDiModule] and the Flutter
/// widget tree, making the module accessible to any descendant widgets.
/// It rebuilds dependents whenever the [BaseDiModule] notifies its listeners.
///
/// Normally, this is used internally by [DiScopeRoot] and does not need to
/// be instantiated directly by the developer.
class _ParentModuleProvider extends InheritedNotifier<BaseDiModule> {
  _ParentModuleProvider({
    required this.module,
    required super.child,
    super.key,
  }) : super(notifier: module);

  /// The current [BaseDiModule] being provided to the widget tree.
  final BaseDiModule module;

  /// Retrieves the current [BaseDiModule] from the widget tree.
  ///
  /// This method searches up the widget tree for an instance of
  /// [_ParentModuleProvider] and returns the module it provides.
  ///
  /// Returns `null` if no provider is found in the current [BuildContext].
  ///
  /// Example:
  /// ```dart
  /// final module = _ParentModuleProvider.of(context);
  /// if (module != null) {
  ///   // Use the module
  /// }
  /// ```
  static BaseDiModule? of(BuildContext context) {
    final result =
        context.dependOnInheritedWidgetOfExactType<_ParentModuleProvider>();
    return result?.notifier;
  }
}
