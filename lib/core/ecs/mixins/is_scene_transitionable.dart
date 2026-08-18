part of '../../raylib_dartified_unhinged.dart';

/// Adds scene transition lifecycle hooks to an ECS object.
///
/// Covers three transition events: enter, leave, and the full transition arc (from > to), each with a full three-phase contract:
/// - **before** => cancelable; any listener or override returning `false` aborts the operation
/// - **on** => the operation is about to complete; called by the host (e.g. [App]) after all before-checks pass
/// - **after** => the operation has completed; side-effects and cleanup go here
mixin IsSceneTransitionable<
  T extends App<T>,
  E extends ECSBase<T>
> on
  Self<E>,
  ECSBase<T>
{
  late final hookOnBeforeSceneEnterKey = ECSHookKey<bool Function(E self, Scene<T> scene)>(
    'IsSceneTransitionable', 'onBeforeSceneEnter'
  );

  late final hookOnSceneEnterKey = ECSHookKey<void Function(E self, Scene<T> scene)>(
    'IsSceneTransitionable', 'onSceneEnter'
  );

  late final hookOnAfterSceneEnterKey = ECSHookKey<void Function(E self, Scene<T> scene)>(
    'IsSceneTransitionable', 'onAfterSceneEnter'
  );

  late final hookOnBeforeSceneLeaveKey = ECSHookKey<bool Function(E self, Scene<T> scene)>(
    'IsSceneTransitionable', 'onBeforeSceneLeave'
  );

  late final hookOnSceneLeaveKey = ECSHookKey<void Function(E self, Scene<T> scene)>(
    'IsSceneTransitionable', 'onSceneLeave'
  );

  late final hookOnAfterSceneLeaveKey = ECSHookKey<void Function(E self, Scene<T> scene)>(
    'IsSceneTransitionable', 'onAfterSceneLeave'
  );

  late final hookOnBeforeSceneTransitionKey = ECSHookKey<bool Function(E self, Scene<T> from, Scene<T> to)>(
    'IsSceneTransitionable', 'onBeforeSceneTransition'
  );

  late final hookOnSceneTransitionKey = ECSHookKey<void Function(E self, Scene<T> from, Scene<T> to)>(
    'IsSceneTransitionable', 'onSceneTransition'
  );

  late final hookOnAfterSceneTransitionKey = ECSHookKey<void Function(E self, Scene<T> from, Scene<T> to)>(
    'IsSceneTransitionable', 'onAfterSceneTransition'
  );

  Iterable<bool Function(E self, Scene<T> scene)> get _onBeforeSceneEnterFns
    => hooksOf(hookOnBeforeSceneEnterKey);

  Iterable<void Function(E self, Scene<T> scene)> get _onSceneEnterFns
    => hooksOf(hookOnSceneEnterKey);

  Iterable<void Function(E self, Scene<T> scene)> get _onAfterSceneEnterFns
    => hooksOf(hookOnAfterSceneEnterKey);

  Iterable<bool Function(E self, Scene<T> scene)> get _onBeforeSceneLeaveFns
    => hooksOf(hookOnBeforeSceneLeaveKey);

  Iterable<void Function(E self, Scene<T> scene)> get _onSceneLeaveFns
    => hooksOf(hookOnSceneLeaveKey);

  Iterable<void Function(E self, Scene<T> scene)> get _onAfterSceneLeaveFns
    => hooksOf(hookOnAfterSceneLeaveKey);

  Iterable<bool Function(E self, Scene<T> from, Scene<T> to)> get _onBeforeSceneTransitionFns
    => hooksOf(hookOnBeforeSceneTransitionKey);

  Iterable<void Function(E self, Scene<T> from, Scene<T> to)> get _onSceneTransitionFns
    => hooksOf(hookOnSceneTransitionKey);

  Iterable<void Function(E self, Scene<T> from, Scene<T> to)> get _onAfterSceneTransitionFns
    => hooksOf(hookOnAfterSceneTransitionKey);

  /// Registers [fn] as a before-enter listener.
  ///
  /// [fn] returning `false` cancels the scene enter.
  @nonVirtual
  E listenOnBeforeSceneEnter(bool Function(E self, Scene<T> scene) fn) {
    addHook(hookOnBeforeSceneEnterKey, fn);
    return self;
  }

  /// Registers [fn] as an enter listener.
  ///
  /// Called when the enter operation is about to happen and was not canceled.
  @nonVirtual
  E listenOnSceneEnter(void Function(E self, Scene<T> scene) fn) {
    addHook(hookOnSceneEnterKey, fn);
    return self;
  }

  /// Registers [fn] as an after-enter listener.
  ///
  /// Called only if the scene enter was not canceled.
  @nonVirtual
  E listenOnAfterSceneEnter(void Function(E self, Scene<T> scene) fn) {
    addHook(hookOnAfterSceneEnterKey, fn);
    return self;
  }

  /// Registers [fn] as a before-leave listener.
  ///
  /// [fn] returning `false` cancels the scene leave.
  @nonVirtual
  E listenOnBeforeSceneLeave(bool Function(E self, Scene<T> scene) fn) {
    addHook(hookOnBeforeSceneLeaveKey, fn);
    return self;
  }

  /// Registers [fn] as a leave listener.
  ///
  /// Called when the leave operation is about to happen and was not canceled.
  @nonVirtual
  E listenOnSceneLeave(void Function(E self, Scene<T> scene) fn) {
    addHook(hookOnSceneLeaveKey, fn);
    return self;
  }

  /// Registers [fn] as an after-leave listener.
  ///
  /// Called only if the scene leave was not canceled.
  @nonVirtual
  E listenOnAfterSceneLeave(void Function(E self, Scene<T> scene) fn) {
    addHook(hookOnAfterSceneLeaveKey, fn);
    return self;
  }

  /// Registers [fn] as a before-transition listener.
  ///
  /// [fn] returning `false` cancels the full scene transition.
  @nonVirtual
  E listenOnBeforeSceneTransition(bool Function(E self, Scene<T> from, Scene<T> to) fn) {
    addHook(hookOnBeforeSceneTransitionKey, fn);
    return self;
  }

  /// Registers [fn] as a transition listener.
  ///
  /// Called when the transition operation is about to happen and was not canceled.
  @nonVirtual
  E listenOnSceneTransition(void Function(E self, Scene<T> from, Scene<T> to) fn) {
    addHook(hookOnSceneTransitionKey, fn);
    return self;
  }

  /// Registers [fn] as an after-transition listener.
  ///
  /// Called only if the scene transition was not canceled.
  @nonVirtual
  E listenOnAfterSceneTransition(void Function(E self, Scene<T> from, Scene<T> to) fn) {
    addHook(hookOnAfterSceneTransitionKey, fn);
    return self;
  }

  /// Runs all before-enter listeners and [onBeforeSceneEnter].
  ///
  /// Returns `false` if any listener or the override cancels the enter.
  @mustCallSuper
  bool _doOnBeforeSceneEnter(Scene<T> scene) {
    if (!_onBeforeSceneEnterFns.every((f) => f(self, scene))) return false;
    return onBeforeSceneEnter(scene);
  }

  /// Runs all enter listeners and [onSceneEnter].
  @mustCallSuper
  void _doOnSceneEnter(Scene<T> scene) {
    _onSceneEnterFns.forEach((f) => f(self, scene));
    onSceneEnter(scene);
  }

  /// Runs all after-enter listeners and [onAfterSceneEnter].
  @mustCallSuper
  void _doOnAfterSceneEnter(Scene<T> scene) {
    _onAfterSceneEnterFns.forEach((f) => f(self, scene));
    onAfterSceneEnter(scene);
  }

  /// Runs all before-leave listeners and [onBeforeSceneLeave].
  ///
  /// Returns `false` if any listener or the override cancels the leave.
  @mustCallSuper
  bool _doOnBeforeSceneLeave(Scene<T> scene) {
    if (!_onBeforeSceneLeaveFns.every((f) => f(self, scene))) return false;
    return onBeforeSceneLeave(scene);
  }

  /// Runs all leave listeners and [onSceneLeave].
  @mustCallSuper
  void _doOnSceneLeave(Scene<T> scene) {
    _onSceneLeaveFns.forEach((f) => f(self, scene));
    onSceneLeave(scene);
  }

  /// Runs all after-leave listeners and [onAfterSceneLeave].
  @mustCallSuper
  void _doOnAfterSceneLeave(Scene<T> scene) {
    _onAfterSceneLeaveFns.forEach((f) => f(self, scene));
    onAfterSceneLeave(scene);
  }

  /// Runs all before-transition listeners and [onBeforeSceneTransition].
  ///
  /// Returns `false` if any listener or the override cancels the transition.
  @mustCallSuper
  bool _doOnBeforeSceneTransition(Scene<T> from, Scene<T> to) {
    if (!_onBeforeSceneTransitionFns.every((f) => f(self, from, to))) return false;
    return onBeforeSceneTransition(from, to);
  }

  /// Runs all transition listeners and [onSceneTransition].
  @mustCallSuper
  void _doOnSceneTransition(Scene<T> from, Scene<T> to) {
    _onSceneTransitionFns.forEach((f) => f(self, from, to));
    onSceneTransition(from, to);
  }

  /// Runs all after-transition listeners and [onAfterSceneTransition].
  @mustCallSuper
  void _doOnAfterSceneTransition(Scene<T> from, Scene<T> to) {
    _onAfterSceneTransitionFns.forEach((f) => f(self, from, to));
    onAfterSceneTransition(from, to);
  }

  /// Override to cancel a scene enter from within the class.
  ///
  /// Return `false` to abort. Called after all registered [listenOnBeforeSceneEnter] listeners.
  bool onBeforeSceneEnter(Scene<T> scene) => true;

  /// Override to react when a scene enter is about to complete.
  ///
  /// Called by the host after all before-checks have passed.
  void onSceneEnter(Scene<T> scene) {}

  /// Override to react after a scene enter has completed.
  ///
  /// Called after all registered [listenOnAfterSceneEnter] listeners.
  void onAfterSceneEnter(Scene<T> scene) {}

  /// Override to cancel a scene leave from within the class.
  ///
  /// Return `false` to abort. Called after all registered [listenOnBeforeSceneLeave] listeners.
  bool onBeforeSceneLeave(Scene<T> scene) => true;

  /// Override to react when a scene leave is about to complete.
  ///
  /// Called by the host after all before-checks have passed.
  void onSceneLeave(Scene<T> scene) {}

  /// Override to react after a scene leave has completed.
  ///
  /// Called after all registered [listenOnAfterSceneLeave] listeners.
  void onAfterSceneLeave(Scene<T> scene) {}

  /// Override to cancel a scene transition from within the class.
  ///
  /// Return `false` to abort. Called after all registered [listenOnBeforeSceneTransition] listeners.
  bool onBeforeSceneTransition(Scene<T> from, Scene<T> to) => true;

  /// Override to react when a scene transition is about to complete.
  ///
  /// Called by the host after all before-checks have passed.
  void onSceneTransition(Scene<T> from, Scene<T> to) {}

  /// Override to react after a scene transition has completed.
  ///
  /// Called after all registered [listenOnAfterSceneTransition] listeners.
  void onAfterSceneTransition(Scene<T> from, Scene<T> to) {}
}