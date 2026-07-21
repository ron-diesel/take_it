# take_it

![Logo](./logo.png)

`take_it` is a **Scoped Service Locator** with **Constructor Injections** for Dart and Flutter. It helps you manage
dependencies in your application in a clean, efficient, and testable manner.

## Overview

This is a lightweight dependency management library that combines the simplicity of the **Service Locator** pattern with
the flexibility of **Inversion of Control (IoC) Containers**. This hybrid approach allows you to efficiently manage your
application's dependencies while maintaining clean and modular architecture.

### Key Features:

- 🛠️ **No Code Generation:** Unlike some dependency management solutions, take_it does not require code generation. It
  provides a straightforward API for dependency registration and retrieval, minimizing setup complexity and reducing
  build times.
- ❤️ **Familiar API:** take_it offers a syntax and API similar to get_it, making it easy for users familiar with get_it
  to adopt and integrate it into their projects. This ensures a smooth learning curve and compatibility with existing
  codebases.
- 🔐 **Scoped Service Locator & Modular Configuration:** Dependencies are encapsulated within specialized modules,
  preventing global access to services and providing better control over their lifecycle. Each module manages only the
  dependencies it needs, avoiding the clutter of a globally accessible service locator. This method simplifies testing,
  maintenance, and scalability, keeping your codebase organized and manageable.
- 🏗️ **Constructor Injections:** Instead of relying on the service locator throughout the codebase, take_it encourages
  injecting dependencies directly through constructors, promoting explicit and testable dependencies while still
  leveraging the ease of service registration.
- 🧪 **Clean and Testable Code:** By avoiding global dependency access and focusing on constructor-based injection,
  take_it makes it easy to mock dependencies and write unit tests, while also keeping the architecture transparent and
  maintainable.
- 🚀 **Performance Optimization:** The library’s design ensures minimal overhead and fast dependency resolution,
  validated by performance tests included within the package.

### When to Use `take_it`:

- **Modular Applications**: Ideal for larger projects where you want clear separation of concerns and modular
  architecture.
- **Testability**: Encourages constructor injection, making it easier to mock and test dependencies.
- **Performance**: For applications where performance and low overhead in dependency resolution are critical.

## Installation

Add `take_it` to your project's dependencies in `pubspec.yaml`:

```yaml
dependencies:
  take_it: ^1.0.0
```

## Getting started

To start using take_it, define your dependencies within a DiModule, which is a container for services, ensuring that
dependencies are isolated to a particular module or scope.

### Example: Registering Dependencies in a DiModule

```dart
import 'package:take_it/take_it.dart';

class ExampleDiModule extends DiModule {
  @override
  void setup(SyncRegistrar it) {
    it.registerFactory(() => ExampleBloc());
  }
}
```

### Embedding a module into a widget tree

Wrap your widget tree with DiScopeBuilder to initialize the module and inject the necessary dependencies. This ensures
that the module's lifecycle is managed correctly.

```dart
  Widget build(BuildContext context) {
  return DiScopeBuilder(
    createModule: () => ExampleDiModule(),
    builder: (context, scope) => ExampleScreen(bloc: scope.get()),
  );
}
```

In this example:

- DiScopeBuilder embeds a module into a widget tree.
- scope.get() is used to retrieve the dependency injected via the module.

## Usage

### Example: Dependency Hierarchy

The scope has access to all objects registered higher in the hierarchy but cannot access objects registered in lower
scopes. The hierarchy follows the structure defined by the DiScopeBuilder<DiModule> placement within the widget tree.

```dart
@override
void setup(SyncRegistrar it) {
  it.registerFactory(() => ClassB(a: get<ClassA>));
}
```

### Composing Modules

A module can include the registrations of another module by calling its `setup` with the same registrar:

```dart
class FeatureDiModule extends DiModule {
  @override
  void setup(SyncRegistrar it) {
    it.registerFactory(() => FeatureBloc());

    // Include all registrations from NetworkDiModule into this scope.
    NetworkDiModule().setup(it);
  }
}
```

This is **composition, not scope inheritance**: the nested module registers its services directly into the outer
module's container, so everything ends up in one shared scope. This is useful for splitting a large module into
reusable parts without introducing extra levels in the widget tree.

Keep in mind:

- The nested module instance itself is never initialized — it only contributes registrations and cannot be used as a
  scope on its own.
- Since all registrations land in the same scope, a type registered by both modules will throw an
  "already registered in current scope" exception. Overriding a type is only possible in a child scope created via
  `DiScopeBuilder`.
- Calling `init()` on a module inside another module's `setup` does **not** share anything: the nested module gets its
  own isolated container, with no access to the outer module's registrations.

### Asynchronous Dependencies

You can register asynchronous dependencies using DiModuleAsync. This allows for waiting on async operations, like
fetching data from an API, before providing a dependency to the rest of the app.

```dart
class ExampleDiModule extends DiModuleAsync {

  @override
  Future<void> setup(AsyncRegistrar it) async {
    await ...// here
    it.registerSingletonAsync(() async{
    await ... // or here
    return Example();
    } );
  }

}
```

In this example:

You can register async dependencies within the module using registerSingletonAsync.

### Initialization Placeholder for Async Operations

While the module is initializing, you can display a loading indicator or placeholder widget.

```dart
Widget build(BuildContext context) {
  return DiScopeBuilder(
    initializationPlaceholder: CircularProgressIndicator(),
    createModule: ...,
    builder: ...,
  );
}
```

This ensures the user sees a loading state while the necessary dependencies are being initialized.

### Module Dependencies

Instead of nesting multiple `DiScopeBuilder` widgets, a module can declare its own dependencies via the `dependencies`
constructor parameter. Dependency modules are initialized before the main module's `setup()` runs, and their
registrations are available through the same scope.

```dart
// Before: nested DiScopeBuilder widgets
DiScopeBuilder(
  createModule: MediaDiModule.new,
  builder: (_, __) => DiScopeBuilder(
    createModule: BannerDiModule.new,
    builder: (_, __) => DiScopeBuilder(
      createModule: ToursDiModule.new,
      builder: (context, scope) => ToursScreen(
        toursBloc: scope.get<ToursBloc>(),
        bannerBloc: scope.get<BannerBloc>(),
      ),
    ),
  ),
)

// After: single DiScopeBuilder, deps declared in the module
class ToursDiModule extends DiModule {
  ToursDiModule() : super(dependencies: [MediaDiModule(), BannerDiModule()]);

  @override
  void setup(SyncRegistrar it) {
    it.registerFactory(() => ToursBloc(repo: get<ToursRepo>()));
  }
}

DiScopeBuilder(
  createModule: ToursDiModule.new,
  builder: (context, scope) => ToursScreen(
    toursBloc: scope.get<ToursBloc>(),
    bannerBloc: scope.get<BannerBloc>(), // inherited from BannerDiModule
  ),
)
```

All dependency registrations are merged into the same `_parentEntities` map via `mergeFrom` — later deps overwrite
earlier ones for the same type. The main module's own `setup()` writes to `_entities`, which is always checked first
by `get()`.

```dart
class MyModule extends DiModule {
  // ModuleB is merged after ModuleA — its String registration wins over ModuleA's
  MyModule() : super(dependencies: [ModuleA(), ModuleB()]);

  @override
  void setup(SyncRegistrar it) {
    // registered in _entities — always wins over anything in _parentEntities
    it.registerFactory<String>(() => 'own');
  }
}
```

Dependencies are disposed automatically when the main module is disposed.

## Advanced Topics

### Scoped Hierarchies

One of the key features of take_it is its ability to create scoped hierarchies of services. For example, you can define
different modules for different parts of your application, which are isolated from each other. This is particularly
useful in large applications, ensuring that services are only accessible in specific parts of your app.

### Lifecycle Management

With take_it, the lifecycle of dependencies is tied to the scope in which they are registered. Dependencies are
initialized when the scope is created and disposed of when the scope is destroyed, ensuring efficient memory management.

## License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.
