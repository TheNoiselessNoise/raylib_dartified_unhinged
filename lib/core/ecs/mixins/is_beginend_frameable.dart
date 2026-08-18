part of '../../raylib_dartified_unhinged.dart';

/// Adds begin-frame and end-frame lifecycle hooks to an ECS object.
///
/// The **on** phase only, frame boundaries are not cancelable.
mixin IsBeginEndFrameable<T extends App<T>, E extends ECSBase<T>> on Self<E>, ECSBase<T> {

  List<void Function(E self, double dt)> _onBeginFrameFns = [];

  List<void Function(E self, double dt)> _onEndFrameFns = [];

  /// Registers [fn] to be called at the start of each frame.
  @nonVirtual
  E listenOnBeginFrame(void Function(E self, double dt) fn) {
    _onBeginFrameFns.add(fn);
    return self;
  }

  /// Registers [fn] to be called at the end of each frame.
  @nonVirtual
  E listenOnEndFrame(void Function(E self, double dt) fn) {
    _onEndFrameFns.add(fn);
    return self;
  }

  /// Notifies all begin-frame listeners and calls [onBeginFrame].
  void _doBeginFrame(double dt) {
    _onBeginFrameFns.forEach((f) => f(self, dt));
    onBeginFrame(dt);
  }

  /// Notifies all end-frame listeners and calls [onEndFrame].
  void _doEndFrame(double dt) {
    _onEndFrameFns.forEach((f) => f(self, dt));
    onEndFrame(dt);
  }

  /// Override to react at the start of each frame.
  ///
  /// Called after all registered [listenOnBeginFrame] listeners.
  void onBeginFrame(double dt) {}

  /// Override to react at the end of each frame.
  ///
  /// Called after all registered [listenOnEndFrame] listeners.
  void onEndFrame(double dt) {}
}