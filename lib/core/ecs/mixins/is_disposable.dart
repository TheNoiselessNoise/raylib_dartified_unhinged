part of '../../raylib_dartified_unhinged.dart';

/// Adds dispose lifecycle hooks to an ECS object.
///
/// The **on** phase only, disposal is not cancelable.
mixin IsDisposable<T extends App<T>, E extends ECSBase<T>> on Self<E>, ECSBase<T> {

  List<void Function(E self)> _onDisposeFns = [];

  /// Registers [fn] to be called at the disposal of the owned ECS object.
  @nonVirtual
  E listenOnDispose(void Function(E self) fn) {
    _onDisposeFns.add(fn);
    return self;
  }

  /// Notifies all dispose listeners and calls [onDispose].
  @mustCallSuper
  void _doOnDispose() {
    _onDisposeFns.forEach((f) => f(self));
    onDispose();
  }

  /// Override to react at the disposal.
  ///
  /// Called after all registered [listenOnDispose] listeners.
  void onDispose() {}
}