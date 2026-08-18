part of '../../raylib_dartified_unhinged.dart';

/// Adds pre-draw and post-draw lifecycle hooks to an ECS object.
///
/// The **on** phase only, draw boundaries are not cancelable.
mixin IsPrePostDrawable<T extends App<T>, E extends ECSBase<T>> on Self<E>, ECSBase<T> {

  List<void Function(E self, double dt)> _onPreDrawFns = [];

  List<void Function(E self, double dt)> _onPostDrawFns = [];

  /// Registers [fn] to be called before the draw phase each frame.
  @nonVirtual
  E listenOnPreDraw(void Function(E self, double dt) fn) {
    _onPreDrawFns.add(fn);
    return self;
  }

  /// Registers [fn] to be called after the draw phase each frame.
  @nonVirtual
  E listenOnPostDraw(void Function(E self, double dt) fn) {
    _onPostDrawFns.add(fn);
    return self;
  }

  /// Notifies all pre-draw listeners and calls [onPreDraw].
  void _doOnPreDraw(double dt) {
    _onPreDrawFns.forEach((f) => f(self, dt));
    onPreDraw(dt);
  }

  /// Notifies all post-draw listeners and calls [onPostDraw].
  void _doOnPostDraw(double dt) {
    _onPostDrawFns.forEach((f) => f(self, dt));
    onPostDraw(dt);
  }

  /// Override to react before the draw phase each frame.
  ///
  /// Called after all registered [listenOnPreDraw] listeners.
  void onPreDraw(double dt) {}

  /// Override to react after the draw phase each frame.
  ///
  /// Called after all registered [listenOnPostDraw] listeners.
  void onPostDraw(double dt) {}
}