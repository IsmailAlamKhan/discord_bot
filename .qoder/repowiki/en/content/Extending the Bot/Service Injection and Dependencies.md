# Service Injection and Dependencies

<cite>
**Referenced Files in This Document**   
- [main.dart](file://bin/main.dart)
- [config.dart](file://src/config.dart)
- [db.dart](file://src/db.dart)
- [bot.dart](file://src/bot.dart)
- [config_runnable.dart](file://src/runnables/config_runnable.dart)
- [waifu_points.dart](file://src/runnables/waifu_points.dart)
- [runnables.dart](file://src/runnables/runnables.dart)
- [env.dart](file://src/env.dart)
- [waifu_command.dart](file://src/commands/waifu_command.dart)
- [ask_command.dart](file://src/commands/ask_command.dart)
</cite>

## Table of Contents
1. [Introduction](#introduction)
2. [ProviderContainer Setup in main.dart](#providercontainer-setup-in-maindart)
3. [Core Providers: botProvider, configProvider, dbProvider](#core-providers-botprovider-configprovider-dbprovider)
4. [Dependency Access via Ref in Runnable Constructors](#dependency-access-via-ref-in-runnable-constructors)
5. [Creating and Injecting Custom Services](#creating-and-injecting-custom-services)
6. [Provider Scoping and Lifecycle Management](#provider-scoping-and-lifecycle-management)
7. [Testing with Mocked Providers](#testing-with-mocked-providers)
8. [Extending Functionality: Adding New Services](#extending-functionality-adding-new-services)
9. [Common Pitfalls and Best Practices](#common-pitfalls-and-best-practices)
10. [Conclusion](#conclusion)

## Introduction
This document provides a comprehensive guide on leveraging Riverpod for service injection within the Discord bot application. It details how dependency injection is implemented using Riverpod's `ProviderContainer`, enabling clean, testable, and modular code architecture. The system allows services such as configuration, database, and bot instances to be centrally managed and injected into various components—particularly `Runnable` classes—through the `Ref` object. This approach promotes separation of concerns, enhances maintainability, and supports scalable extension of functionality.

## ProviderContainer Setup in main.dart
The entry point of the application, `main.dart`, initializes a `ProviderContainer` which serves as the central registry for all providers. This container is created at startup and used to access and initialize core services required by the bot.

```dart
final ref = ProviderContainer();
```

This instance of `ProviderContainer` is passed implicitly through Riverpod’s `ref` mechanism to all downstream providers and consumers. It ensures that dependencies are resolved in a consistent and predictable manner. Services like environment variables, configuration, and the bot client itself are read from this container and initialized in sequence.

The initialization flow in `main()` follows a strict order:
- Read environment configuration via `envProvider`
- Initialize environment and config providers
- Await asynchronous initialization of `botProvider`
- Start message and member event listeners using their respective providers

This setup ensures that all dependencies are ready before the bot begins processing events.

**Section sources**
- [main.dart](file://bin/main.dart#L1-L30)

## Core Providers: botProvider, configProvider, dbProvider
Three primary providers form the backbone of the application’s dependency graph: `botProvider`, `configProvider`, and `dbProvider`. Each encapsulates a critical service and exposes it through Riverpod’s reactive system.

### botProvider
Defined in `bot.dart`, `botProvider` is a `FutureProvider<NyxxGateway>` that asynchronously creates and connects the Discord bot client. It depends on `envProvider` to retrieve the bot token and sets up command plugins and error handling.

```dart
final botProvider = FutureProvider<NyxxGateway>((ref) async {
  final env = ref.read(envProvider);
  // ... setup Nyxx client
});
```

Because it's a `FutureProvider`, consuming code must use `.future` to await its resolution.

### configProvider
Located in `config.dart`, `configProvider` provides a `ConfigController` instance responsible for loading and persisting bot configuration (e.g., command prefix) from `config.json`. It supports runtime updates via `setConfig()` and validates file existence.

```dart
final configProvider = Provider((ref) => ConfigController());
```

It enables dynamic reconfiguration during runtime, such as when a user runs the `config` command.

### dbProvider
In `db.dart`, `dbProvider` offers a `DBController` that manages persistent data including waifu points, user preferences, and nicknames. It reads from and writes to `db.json`, initializing the database on first use.

```dart
final dbProvider = Provider((ref) => DBController()..init());
```

The `..init()` call ensures the database is loaded synchronously upon provider creation.

These providers are globally accessible throughout the app via the shared `ProviderContainer`.

**Section sources**
- [bot.dart](file://src/bot.dart#L1-L54)
- [config.dart](file://src/config.dart#L1-L79)
- [db.dart](file://src/db.dart#L1-L133)

## Dependency Access via Ref in Runnable Constructors
Riverpod’s `Ref` parameter is central to dependency injection in `Runnable` classes. It allows components to access providers without tight coupling, promoting modularity and testability.

### Usage in Runnable Implementations
All `Runnable` subclasses receive a `required ProviderContainer ref` in their `run()` method. This `ref` is used to read any provider value synchronously or asynchronously.

#### Example: config_runnable.dart
In `ConfigRunnable`, the `ref` is used to:
- Access the running bot instance via `botProvider.future`
- Update configuration using `configProvider`

```dart
final bot = await ref.read(botProvider.future);
ref.read(configProvider).setConfig(Config(prefix: "!${prefix!}"));
```

This enables the command to interact with both the Discord API and persistent configuration seamlessly.

#### Example: waifu_points.dart
The `WaifuPointsRunnable` uses `ref` to access the database:

```dart
final db = ref.read(dbProvider);
final points = db.getFromDB((db) => db.getWaifuPoints(userID));
```

Here, `getFromDB()` is a utility that safely executes read operations on the internal `DB` state.

This pattern ensures that business logic remains decoupled from service instantiation.

**Section sources**
- [config_runnable.dart](file://src/runnables/config_runnable.dart#L1-L136)
- [waifu_points.dart](file://src/runnables/waifu_points.dart#L1-L47)
- [runnables.dart](file://src/runnables/runnables.dart#L1-L29)

## Creating and Injecting Custom Services
New services can be integrated by defining providers and injecting them via `Ref`. This section illustrates how to add a logging or analytics service.

### Step 1: Define the Service Class
Create a service class that accepts `Ref` for dependency access:

```dart
class AnalyticsService {
  final Ref ref;
  AnalyticsService(this.ref);

  Future<void> track(String event, Map<String, dynamic> properties) async {
    final db = ref.read(dbProvider);
    // Log event to database or external service
  }
}
```

### Step 2: Create a Provider
Expose the service via a provider:

```dart
final analyticsProvider = Provider((ref) => AnalyticsService(ref));
```

### Step 3: Inject into Runnables
Use the provider in any `Runnable`:

```dart
final analytics = ref.read(analyticsProvider);
await analytics.track('waifu_requested', {'userId': member.id.value});
```

This approach allows new features to be added without modifying existing infrastructure.

**Section sources**
- [runnables.dart](file://src/runnables/runnables.dart#L1-L29)
- [db.dart](file://src/db.dart#L1-L133)

## Provider Scoping and Lifecycle Management
Proper scoping and lifecycle management prevent memory leaks and ensure resource efficiency.

### Singleton vs. Transient Providers
Most providers in this app are singletons (e.g., `configProvider`, `dbProvider`), created once and reused. Riverpod manages their lifecycle automatically.

For transient objects (e.g., per-command state), consider using `Provider.autoDispose`:

```dart
final tempStateProvider = Provider.autoDispose((ref) {
  return TemporaryState();
});
```

This ensures cleanup after inactivity.

### Avoiding Memory Leaks
Long-lived subscriptions (e.g., Discord event listeners) should be canceled on shutdown:

```dart
_streamSubscription?.cancel();
```

Classes like `MessageListener` and `MemberChange` implement `stop()` and `restart()` methods to manage subscription lifetimes explicitly.

Avoid holding references to `ref` longer than necessary, especially in long-lived objects.

**Section sources**
- [listen_to_message.dart](file://src/listen_to_message.dart#L13-L140)
- [member_change.dart](file://src/member_change.dart#L11-L76)
- [store_all_nick_names.dart](file://src/store_all_nick_names.dart#L11-L36)

## Testing with Mocked Providers
Riverpod facilitates unit testing by allowing providers to be overridden with mocks.

### Example: Mocking dbProvider
In tests, replace `dbProvider` with an in-memory version:

```dart
final container = ProviderContainer(overrides: [
  dbProvider.overrideWithValue(MockDBController()),
]);
```

Then inject this container into the `Runnable` under test:

```dart
await runnable.run(
  ref: container,
  arguments: [],
  channel: mockChannel,
  member: mockMember,
  messageCreateEvent: mockEvent,
);
```

This enables isolated testing of logic without relying on file I/O or network calls.

### Best Practice: Use ProviderContainer in Tests
Always instantiate a fresh `ProviderContainer` per test to avoid state leakage between test cases.

**Section sources**
- [waifu_points.dart](file://src/runnables/waifu_points.dart#L1-L47)
- [config_runnable.dart](file://src/runnables/config_runnable.dart#L1-L136)

## Extending Functionality: Adding New Services
To extend the bot with new capabilities (e.g., logging, analytics, caching), follow these steps:

### Example: Adding a Logging Service
1. **Define the service**:
```dart
class Logger {
  final Ref ref;
  Logger(this.ref);

  void info(String message) => print('[INFO] $message');
  void error(String message) => print('[ERROR] $message');
}
```

2. **Create the provider**:
```dart
final loggerProvider = Provider((ref) => Logger(ref));
```

3. **Inject into existing commands**:
```dart
final logger = ref.read(loggerProvider);
logger.info('Waifu command executed by ${member.id.value}');
```

4. **Register in main.dart (if needed)**:
No registration needed—Riverpod lazily instantiates providers when first read.

This pattern enables non-invasive feature additions while preserving clean architecture.

**Section sources**
- [google_ai_service.dart](file://src/google_ai_service.dart#L111-L165)
- [runnables.dart](file://src/runnables/runnables.dart#L1-L29)

## Common Pitfalls and Best Practices
### Pitfall 1: Incorrect Provider Ordering
Providers must be read in correct dependency order. For example, `botProvider` depends on `envProvider`, so `envProvider` must be initialized first.

✅ Correct:
```dart
final env = ref.read(envProvider);
final bot = await ref.read(botProvider.future);
```

❌ Incorrect:
```dart
final bot = await ref.read(botProvider.future); // May fail if env not ready
```

### Pitfall 2: Asynchronous Initialization Issues
`FutureProvider` values must be awaited. Use `.future` when reading:

```dart
final bot = await ref.read(botProvider.future);
```

Avoid blocking calls in synchronous contexts.

### Best Practice: Use autoDispose for Ephemeral State
For temporary or UI-related state, prefer `autoDispose` to prevent memory bloat.

### Best Practice: Minimize Direct Provider Reads
Encapsulate complex logic within service classes rather than scattering `ref.read()` calls across multiple files.

### Best Practice: Centralize Provider Definitions
Keep all providers in a dedicated file (e.g., `providers.dart`) for better discoverability and maintenance.

**Section sources**
- [main.dart](file://bin/main.dart#L1-L30)
- [bot.dart](file://src/bot.dart#L1-L54)
- [env.dart](file://src/env.dart#L1-L99)

## Conclusion
Riverpod provides a robust foundation for dependency injection in the Discord bot, enabling modular, testable, and maintainable code. By leveraging `ProviderContainer`, `Ref`, and well-defined providers like `botProvider`, `configProvider`, and `dbProvider`, the application achieves loose coupling and high cohesion. Developers can extend functionality by creating new services and injecting them into `Runnable` components with minimal friction. Adhering to best practices around provider scoping, lifecycle management, and testing ensures long-term stability and scalability of the codebase.