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
  late final hookOnBeforeSceneEnterKey = ECSHookKey<HookResult Function(E self, Scene<T> scene)>(
    'IsSceneTransitionable', 'onBeforeSceneEnter'
  );

  late final hookOnSceneEnterKey = ECSHookKey<void Function(E self, Scene<T> scene)>(
    'IsSceneTransitionable', 'onSceneEnter'
  );

  late final hookOnAfterSceneEnterKey = ECSHookKey<void Function(E self, Scene<T> scene)>(
    'IsSceneTransitionable', 'onAfterSceneEnter'
  );

  late final hookOnBeforeSceneLeaveKey = ECSHookKey<HookResult Function(E self, Scene<T> scene)>(
    'IsSceneTransitionable', 'onBeforeSceneLeave'
  );

  late final hookOnSceneLeaveKey = ECSHookKey<void Function(E self, Scene<T> scene)>(
    'IsSceneTransitionable', 'onSceneLeave'
  );

  late final hookOnAfterSceneLeaveKey = ECSHookKey<void Function(E self, Scene<T> scene)>(
    'IsSceneTransitionable', 'onAfterSceneLeave'
  );

  late final hookOnBeforeSceneTransitionKey = ECSHookKey<HookResult Function(E self, Scene<T> from, Scene<T> to)>(
    'IsSceneTransitionable', 'onBeforeSceneTransition'
  );

  late final hookOnSceneTransitionKey = ECSHookKey<void Function(E self, Scene<T> from, Scene<T> to)>(
    'IsSceneTransitionable', 'onSceneTransition'
  );

  late final hookOnAfterSceneTransitionKey = ECSHookKey<void Function(E self, Scene<T> from, Scene<T> to)>(
    'IsSceneTransitionable', 'onAfterSceneTransition'
  );

  Iterable<HookResult Function(E self, Scene<T> scene)> get _onBeforeSceneEnterFns
    => hooksOf(hookOnBeforeSceneEnterKey);

  Iterable<void Function(E self, Scene<T> scene)> get _onSceneEnterFns
    => hooksOf(hookOnSceneEnterKey);

  Iterable<void Function(E self, Scene<T> scene)> get _onAfterSceneEnterFns
    => hooksOf(hookOnAfterSceneEnterKey);

  Iterable<HookResult Function(E self, Scene<T> scene)> get _onBeforeSceneLeaveFns
    => hooksOf(hookOnBeforeSceneLeaveKey);

  Iterable<void Function(E self, Scene<T> scene)> get _onSceneLeaveFns
    => hooksOf(hookOnSceneLeaveKey);

  Iterable<void Function(E self, Scene<T> scene)> get _onAfterSceneLeaveFns
    => hooksOf(hookOnAfterSceneLeaveKey);

  Iterable<HookResult Function(E self, Scene<T> from, Scene<T> to)> get _onBeforeSceneTransitionFns
    => hooksOf(hookOnBeforeSceneTransitionKey);

  Iterable<void Function(E self, Scene<T> from, Scene<T> to)> get _onSceneTransitionFns
    => hooksOf(hookOnSceneTransitionKey);

  Iterable<void Function(E self, Scene<T> from, Scene<T> to)> get _onAfterSceneTransitionFns
    => hooksOf(hookOnAfterSceneTransitionKey);

  /// Registers [fn] as a before-scene-enter listener.
  ///
  /// [fn] returns a [HookResult] to control execution flow:
  /// - [HookResult.proceed] continues normally.
  /// - [HookResult.skip] skips the core action but runs the after-phase.
  /// - [HookResult.cancel] aborts the operation entirely.
  @nonVirtual
  E listenOnBeforeSceneEnter(HookResult Function(E self, Scene<T> scene) fn) {
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

  /// Registers [fn] as a before-scene-leave listener.
  ///
  /// [fn] returns a [HookResult] to control execution flow:
  /// - [HookResult.proceed] continues normally.
  /// - [HookResult.skip] skips the core action but runs the after-phase.
  /// - [HookResult.cancel] aborts the operation entirely.
  @nonVirtual
  E listenOnBeforeSceneLeave(HookResult Function(E self, Scene<T> scene) fn) {
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

  /// Registers [fn] as a before-scene-transition listener.
  ///
  /// [fn] returns a [HookResult] to control execution flow:
  /// - [HookResult.proceed] continues normally.
  /// - [HookResult.skip] skips the core action but runs the after-phase.
  /// - [HookResult.cancel] aborts the operation entirely.
  @nonVirtual
  E listenOnBeforeSceneTransition(HookResult Function(E self, Scene<T> from, Scene<T> to) fn) {
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

  /// Runs all before-scene-enter listeners and [onBeforeSceneEnter], combining their [HookResult] decisions.
  ///
  /// Prioritizes [HookResult.cancel], followed by [HookResult.skip], defaulting to [HookResult.proceed].
  @mustCallSuper
  HookResult _doOnBeforeSceneEnter(Scene<T> scene) {
    HookResult result = .proceed;
    for (final f in _onBeforeSceneEnterFns) {
      result = _mergeHookResult(result, f(self, scene));
      if (result == .cancel) return result;
    }
    return _mergeHookResult(result, onBeforeSceneEnter(scene));
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

  /// Runs all before-scene-leave listeners and [onBeforeSceneLeave], combining their [HookResult] decisions.
  ///
  /// Prioritizes [HookResult.cancel], followed by [HookResult.skip], defaulting to [HookResult.proceed].
  @mustCallSuper
  HookResult _doOnBeforeSceneLeave(Scene<T> scene) {
    HookResult result = .proceed;
    for (final f in _onBeforeSceneLeaveFns) {
      result = _mergeHookResult(result, f(self, scene));
      if (result == .cancel) return result;
    }
    return _mergeHookResult(result, onBeforeSceneLeave(scene));
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

  /// Runs all before-scene-transition listeners and [onBeforeSceneTransition], combining their [HookResult] decisions.
  ///
  /// Prioritizes [HookResult.cancel], followed by [HookResult.skip], defaulting to [HookResult.proceed].
  @mustCallSuper
  HookResult _doOnBeforeSceneTransition(Scene<T> from, Scene<T> to) {
    HookResult result = .proceed;
    for (final f in _onBeforeSceneTransitionFns) {
      result = _mergeHookResult(result, f(self, from, to));
      if (result == .cancel) return result;
    }
    return _mergeHookResult(result, onBeforeSceneTransition(from, to));
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

  /// Override to intercept the before-scene-enter phase from within the class.
  ///
  /// Returns a [HookResult] (defaults to [HookResult.proceed]). 
  /// Called after all registered [listenOnBeforeSceneEnter] listeners.
  HookResult onBeforeSceneEnter(Scene<T> scene) => .proceed;

  /// Override to react when a scene enter is about to complete.
  ///
  /// Called by the host after all before-checks have passed.
  void onSceneEnter(Scene<T> scene) {}

  /// Override to react after a scene enter has completed.
  ///
  /// Called after all registered [listenOnAfterSceneEnter] listeners.
  void onAfterSceneEnter(Scene<T> scene) {}

  /// Override to intercept the before-scene-leave phase from within the class.
  ///
  /// Returns a [HookResult] (defaults to [HookResult.proceed]). 
  /// Called after all registered [listenOnBeforeSceneLeave] listeners.
  HookResult onBeforeSceneLeave(Scene<T> scene) => .proceed;

  /// Override to react when a scene leave is about to complete.
  ///
  /// Called by the host after all before-checks have passed.
  void onSceneLeave(Scene<T> scene) {}

  /// Override to react after a scene leave has completed.
  ///
  /// Called after all registered [listenOnAfterSceneLeave] listeners.
  void onAfterSceneLeave(Scene<T> scene) {}

  /// Override to intercept the before-scene-transition phase from within the class.
  ///
  /// Returns a [HookResult] (defaults to [HookResult.proceed]). 
  /// Called after all registered [listenOnBeforeSceneTransition] listeners.
  HookResult onBeforeSceneTransition(Scene<T> from, Scene<T> to) => .proceed;

  /// Override to react when a scene transition is about to complete.
  ///
  /// Called by the host after all before-checks have passed.
  void onSceneTransition(Scene<T> from, Scene<T> to) {}

  /// Override to react after a scene transition has completed.
  ///
  /// Called after all registered [listenOnAfterSceneTransition] listeners.
  void onAfterSceneTransition(Scene<T> from, Scene<T> to) {}
}