part of '../../raylib_dartified_unhinged.dart';

/// Adds should exitable lifecycle hooks to an ECS object.
mixin IsShouldExitable<T extends App<T>, E extends ECSBase<T>> on Self<E> {

  List<bool Function(E self)> _shouldExitFns = [];

  List<void Function(E self)> _onExitFns = [];

  @nonVirtual
  E listenShouldExit(bool Function(E self) fn) {
    _shouldExitFns.add(fn);
    return self;
  }

  @nonVirtual
  E listenOnExit(void Function(E self) fn) {
    _onExitFns.add(fn);
    return self;
  }

  bool _doShouldExit() {
    if (_shouldExitFns.any((f) => f(self))) return true;
    return shouldExit();
  }

  @nonVirtual
  void _doExit() {
    _onExitFns.forEach((f) => f(self));
    onExit();
  }

  bool shouldExit() => false;

  void onExit() {}
}