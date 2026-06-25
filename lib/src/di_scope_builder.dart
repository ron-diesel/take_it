part of 'di_module/base_di_module.dart';

/// A widget for initializing an instance of [BaseDiModule]
/// and managing its lifecycle.
///
/// [DiScopeBuilder] is responsible for creating
/// and managing a [BaseDiModule] instance
/// within the widget tree. It supports both synchronous
/// and asynchronous modules and provides
/// the module to its children via the [ChildBuilder].
///
/// It automatically handles scope management,
/// including initializing, updating, and disposing
/// the module as needed. This ensures
/// that the correct DI scope is available throughout the
/// widget tree.
///
/// - [createModule]: A factory function used to create
/// an instance of the module.
///    if null, used [EmptyDiModule] to access parent [Scope]
/// - [builder]: A callback that builds the widget tree using the context
/// and the provided module.
/// - [initializationPlaceholder]: A widget that is shown
/// while the module is initializing (e.g., for async modules).
///
/// [initializationPlaceholder] is used specifically
/// when dealing with asynchronous modules.
class DiScopeBuilder extends StatefulWidget {
  const DiScopeBuilder({
    this.createModule,
    this.initializationPlaceholder,
    required this.builder,
    super.key,
  });

  /// A function that creates the DI module instance of type [BaseDiModule].
  final CreateModule<BaseDiModule>? createModule;

  /// A builder function that takes the current [BuildContext]
  /// and the provided [Scope] (the module) to build the UI.
  final ChildBuilder builder;

  /// A widget to display while the module is being initialized,
  /// typically for asynchronous modules.
  final Widget? initializationPlaceholder;

  @override
  State<StatefulWidget> createState() => DiScopeBuilderState();
}

/// State class for [DiScopeBuilder], responsible
/// for managing the module's lifecycle.
@visibleForTesting
class DiScopeBuilderState extends State<DiScopeBuilder> {
  BaseDiModule? module;
  bool isInitialized = false;

  /// Creates the module once, then keeps its scope in sync with the parent.
  ///
  /// [didChangeDependencies] fires not only on first mount but any time an
  /// ancestor [BaseDiModule] calls `notifyListeners()` (since the parent is
  /// provided via [InheritedNotifier]). [createModule] must therefore only
  /// be invoked once per [State] lifetime; otherwise a fresh module instance
  /// would be created and the whole subtree disposed on every unrelated
  /// notification from an ancestor scope.
  ///
  /// `_updateScope` still has to run on every call though:
  /// [DiContainer.fromScope] snapshots the parent's entities at creation
  /// time rather than holding a live reference, so the snapshot needs to be
  /// refreshed whenever the parent's registrations may have changed
  /// (reparenting via a [GlobalKey], or the parent resetting its scope).
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final currentModule = module;
    if (currentModule == null) {
      final newModule = widget.createModule?.call() ?? EmptyDiModule();
      module = newModule;
      if (newModule._isInitialized) {
        isInitialized = true;
        newModule._updateScope(_ParentModuleProvider.of(context));
      } else {
        newModule._pushScope(
          () {
            if (mounted) {
              setState(() {
                isInitialized = true;
              });
            }
          },
          _ParentModuleProvider.of(context),
        );
      }
    } else {
      currentModule._updateScope(_ParentModuleProvider.of(context));
    }
  }

  /// Disposes the module and removes its scope when the widget is disposed.
  @override
  void dispose() {
    module?._popScope();
    super.dispose();
  }

  /// Builds the widget tree with the module once it is initialized,
  /// or shows the initialization placeholder if not.
  @override
  Widget build(BuildContext context) {
    final module = this.module;
    return isInitialized && module != null
        ? _ParentModuleProvider(
            module: module,

            /// [Builder] for providing the correct context.
            child: Builder(builder: (context) {
              return widget.builder.call(context, module);
            }),
          )
        : widget.initializationPlaceholder ?? const SizedBox.shrink();
  }
}

/// Signature for the widget builder function used by [DiScopeBuilder].
///
/// This function receives the [BuildContext] and the current [Scope] (module)
/// and returns a widget that uses the module.
typedef ChildBuilder<T> = Widget Function(BuildContext context, Scope scope);

/// Signature for the function used to create a [BaseDiModule] instance.
typedef CreateModule<T> = T Function();
