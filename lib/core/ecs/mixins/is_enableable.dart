part of '../../raylib_dartified_unhinged.dart';

/// Adds active/disabled state and activation lifecycle hooks to an ECS object.
///
/// The **on** phase only, activation is not cancelable.
mixin IsEnableable<
  T extends App<T>,
  E extends ECSBase<T>
> on
  Self<E>,
  ECSBase<T>
{
  late final hookOnEnableKey = ECSHookKey<void Function(E self)>(
    'IsEnableable', 'onEnable'
  );

  bool _enabled = true;

  /// Whether this object is currently enabled.
  bool get isEnabled => _enabled;

  /// Whether this object is currently disabled.
  bool get isDisabled => !_enabled;

  /// Sets the enabled state to [enabled] and fires the hook.
  @mustCallSuper
  E setEnabled(bool enabled) {
    _enabled = enabled;
    _doOnEnable();
    return self;
  }

  /// Toggles the enabled state and fires the hook.
  @mustCallSuper
  E toggleEnabled() {
    _enabled = !_enabled;
    _doOnEnable();
    return self;
  }

  Iterable<void Function(E self)> get _onEnableFns
    => hooksOf(hookOnEnableKey);

  /// Registers [fn] to be called whenever the active state changes.
  @nonVirtual
  E listenOnEnable(void Function(E self) fn) {
    addHook(hookOnEnableKey, fn);
    return self;
  }

  /// Notifies all listeners and calls [onEnable].
  @nonVirtual
  void _doOnEnable() {
    _onEnableFns.forEach((f) => f(self));
    onEnable();
  }

  /// Override to react when the active state changes.
  ///
  /// Called after all registered [listenOnEnable] listeners.
  /// Check [isEnabled] or [isDisabled] to determine the new state.
  void onEnable() {}
}