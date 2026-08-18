part of '../../raylib_dartified_unhinged.dart';

/// Adds active/disabled state and activation lifecycle hooks to an ECS object.
///
/// The **on** phase only, activation is not cancelable.
mixin IsActivatable<T extends App<T>, E extends ECSBase<T>> on Self<E> {
  bool _active = true;

  /// Whether this object is currently active.
  bool get isActive => _active;

  /// Whether this object is currently disabled.
  bool get isDisabled => !_active;

  /// Sets the active state to [active] and fires the activation hook.
  @mustCallSuper
  E setActive(bool active) {
    _active = active;
    _doOnActivate();
    return self;
  }

  /// Toggles the active state and fires the activation hook.
  @mustCallSuper
  E toggleActive() {
    _active = !_active;
    _doOnActivate();
    return self;
  }

  List<void Function(E self)> _onActivateFns = [];

  /// Registers [fn] to be called whenever the active state changes.
  @nonVirtual
  E listenOnActivate(void Function(E self) fn) {
    _onActivateFns.add(fn);
    return self;
  }

  /// Notifies all listeners and calls [onActivate].
  @nonVirtual
  void _doOnActivate() {
    _onActivateFns.forEach((f) => f(self));
    onActivate();
  }

  /// Override to react when the active state changes.
  ///
  /// Called after all registered [listenOnActivate] listeners.
  /// Check [isActive] to determine the new state.
  void onActivate() {}
}