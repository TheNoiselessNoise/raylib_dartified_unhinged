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
}