part of '../../raylib_dartified_unhinged.dart';

/// Adds a callback processing capabilities to an ECS object.
///
/// Callbacks are queued and executed in a controlled pipeline each frame.
mixin IsCallbackProcessable<
  T extends App<T>,
  E extends ECSBase<T>
> on
  Self<E>,
  HasAppAccess<T>,
  IsEventEmittable<T, E>
{
  late final stateCallbackQueueKey = ECSStateKey<List<void Function()>>(
    'IsCallbackProcessable', 'callbackQueue',
    get: () => .from(_callbackQueue),
    set: (value) => _callbackQueue = value,
  );

  @override
  @mustCallSuper
  void _registerBuiltinStateKeys() {
    super._registerBuiltinStateKeys();
    registerStateKey(stateCallbackQueueKey);
  }

  List<void Function()> _callbackQueue = [];

  /// Schedules a [callback].
  @override
  void callback(void Function() callback) => _callbackQueue.add(callback);

  /// Drains and executes all pending callbacks, then clears the queue.
  bool _processCallbacks() {
    bool didSomething = false;
    while (_callbackQueue.isNotEmpty) {
      _callbackQueue.removeAt(0).call();
      didSomething = true;
    }
    return didSomething;
  }

  /// Clears callback queue.
  void clearCallbackQueue() => _callbackQueue.clear();

  /// Synchronously drains the pending callback queue.
  ///
  /// Intended for tests that need deterministic control over when queued
  /// callbacks are processed, decoupled from [Scene._doDrainLoop]'s callback
  /// interleaving. Not meant for production code.
  @visibleForTesting
  bool processCallbackQueueForTest() => _processCallbacks();
}