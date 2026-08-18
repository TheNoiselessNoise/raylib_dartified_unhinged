part of '../../raylib_dartified_unhinged.dart';

/// Adds cloning capabilities to an ECS object.
///
/// Cloning is opt-in, [clone] throws by default. To enable it, override
/// [createInstance] and either override [clone] or register a [whenClone]
/// callback. Before using, always check [isCloneable] rather than assuming
/// the object supports cloning.
///
/// Cloning follows the standard three-phase contract on the *origin* side:
/// - **before** => cancelable; any listener or override returning `false` aborts the operation
/// - **on** => the operation is about to complete; [isCloning] is set on the copy
/// - **after** => the operation has completed; [isCloned] is set and [onCloned] is called on the copy
///
/// The copy receives [onCloned] with a reference to the original, allowing
/// post-clone fixup without requiring `super` chains.
///
/// State and hook propagation from origin to copy is handled centrally by
/// [_doCloneState], see its doc for the design rationale.
mixin IsCloneable<
  T extends App<T>,
  E extends ECSBase<T>,
  C extends Cloner<T>
> on
  Self<E>,
  ECSBase<T>
{
  /// Whether this object is a clone of another.
  bool isClone = false;

  /// Whether this object has been cloned at least once.
  bool isCloned = false;

  /// Whether this object is currently mid-clone.
  bool isCloning = false;

  /// Check this before calling [clone]: `if (obj.isCloneable) obj.clone();`
  bool get isCloneable => true;

  /// Whether this object is an original (not a clone).
  bool get isOriginal => !isClone;

  final List<E> _clones = [];

  /// Returns all clones produced from this object.
  Iterable<E> getClones() => _clones;

  bool _isCloneAssigned = false;

  /// Registers [clone] as a copy of this object. No-op if already assigned.
  void _assignClone(E clone) {
    if (clone is! IsCloneable<T, E, C>) return;
    if (clone._isCloneAssigned) return;
    clone._isCloneAssigned = true;
    _clones.add(clone);
  }

  X cloneInto<X extends E>(X target, [C? cloner]) {
    if (!_doCloneBefore(target, cloner)) return target;
    _assignClone(target);
    _doOnClone(target, cloner);
    _doCloneState(target, cloner);
    _doCloneAfter(target, cloner);
    return target;
  }

  /// Produces a clone of this object.
  X clone<X extends E>([C? cloner]) {
    final newInstance = _doWhenCreateInstance(self) ?? createInstance();

    if (newInstance is! IsCloneable<T, E, C>) {
      throw StateError('Invalid newInstance returned, expected ${IsCloneable<T, E, C>}!');
    }
    
    _assignClone(newInstance);

    _doCheckIsCloneFresh(newInstance);
    if (newInstance.isCloned) {
      return (_doWhenCloned(self, newInstance) ?? newInstance) as X;
    }

    final readyToClone = _doWhenClone(self, cloner) ?? createClone(newInstance, cloner);

    if (readyToClone is! IsCloneable<T, E, C>) {
      throw StateError('Invalid readyToClone returned, expected ${IsCloneable<T, E, C>}!');
    }

    _doCheckIsCloneFresh(readyToClone);
    if (readyToClone.isCloned) {
      return (_doWhenCloned(self, readyToClone) ?? readyToClone) as X;
    }

    final fullyCloned = cloneInto(readyToClone, cloner);
    return (_doWhenCloned(self, fullyCloned) ?? fullyCloned) as X;
  }

  // TODO: make it a hook as well
  /// Called on the *copy* after cloning completes, with a reference to [original].
  ///
  /// Override to perform post-clone fixup on the new instance.
  void onCloned(E original) {}

  // ░██     ░██   ░██████     ░██████   ░██     ░██   ░██████   
  // ░██     ░██  ░██   ░██   ░██   ░██  ░██    ░██   ░██   ░██  
  // ░██     ░██ ░██     ░██ ░██     ░██ ░██   ░██   ░██         
  // ░██████████ ░██     ░██ ░██     ░██ ░███████     ░████████  
  // ░██     ░██ ░██     ░██ ░██     ░██ ░██   ░██           ░██ 
  // ░██     ░██  ░██   ░██   ░██   ░██  ░██    ░██   ░██   ░██  
  // ░██     ░██   ░██████     ░██████   ░██     ░██   ░██████   

  late final hookOnBeforeCloneKey = ECSHookKey<bool Function(E copy, [C? cloner])>(
    'IsCloneable', 'onBeforeClone'
  );

  late final hookOnCloneKey = ECSHookKey<bool Function(E copy, [C? cloner])>(
    'IsCloneable', 'onClone'
  );

  late final hookOnAfterCloneKey = ECSHookKey<bool Function(E copy, [C? cloner])>(
    'IsCloneable', 'onAfterClone'
  );

  Iterable<bool Function(E copy, [C? cloner])> get _onBeforeCloneFns
    => hooksOf(hookOnBeforeCloneKey);

  Iterable<void Function(E copy, [C? cloner])> get _onCloneFns
    => hooksOf(hookOnCloneKey);

  Iterable<void Function(E copy, [C? cloner])> get _onAfterCloneFns
    => hooksOf(hookOnAfterCloneKey);

  /// Registers [fn] as a before-clone listener.
  ///
  /// [fn] returning `false` cancels the clone.
  @nonVirtual
  E listenOnBeforeClone(bool Function(E copy, [C? cloner]) fn) {
    addHook(hookOnBeforeCloneKey, fn);
    return self;
  }

  /// Registers [fn] as a clone listener.
  ///
  /// Called when the clone operation is about to happen and was not canceled.
  @nonVirtual
  E listenOnClone(void Function(E copy, [C? cloner]) fn) {
    addHook(hookOnCloneKey, fn);
    return self;
  }

  /// Registers [fn] as an after-clone listener.
  ///
  /// Called only if the clone was not canceled.
  @nonVirtual
  E listenOnAfterClone(void Function(E copy, [C? cloner]) fn) {
    addHook(hookOnAfterCloneKey, fn);
    return self;
  }

  /// Runs all before-clone listeners and [onBeforeClone].
  ///
  /// Returns `false` if any listener or the override cancels the clone.
  @nonVirtual
  bool _doOnBeforeClone(E copy, [C? cloner]) {
    if (!_onBeforeCloneFns.every((f) => f(copy, cloner))) return false;
    return onBeforeClone(copy, cloner);
  }

  /// Runs all clone listeners and [onClone].
  void _doOnClone(E copy, [C? cloner]) {
    _onCloneFns.forEach((f) => f(copy, cloner));
    onClone(copy, cloner);
  }

  /// Runs all after-clone listeners and [onAfterClone].
  @nonVirtual
  void _doOnAfterClone(E copy, [C? cloner]) {
    _onAfterCloneFns.forEach((f) => f(copy, cloner));
    onAfterClone(copy, cloner);
  }

  /// Override to cancel cloning from within the class.
  ///
  /// Return `false` to abort. Called after all registered [listenOnBeforeClone] listeners.
  bool onBeforeClone(E copy, [C? cloner]) => true;

  /// Override to react when cloning is about to complete.
  ///
  /// Called by the host after all before-checks have passed.
  void onClone(E copy, [C? cloner]) {}

  /// Override to react after cloning has completed.
  ///
  /// Called after all registered [listenOnAfterClone] listeners.
  void onAfterClone(E copy, [C? cloner]) {}

  /// Overrides the default clone behavior.
  ///
  /// [_whenOnCloneFn] receives `self` and must return a fresh instance. Returning `self`
  /// is a runtime error caught by [_doCheckIsCloneFresh].
  E Function(E self, [C? cloner])? _whenOnCloneFn;

  /// Overrides what happens with the cloned instance after it is produced.
  ///
  /// [_whenOnClonedFn] receives both the origin and the fully cloned copy. If provided,
  /// its return value replaces the copy returned to the caller.
  E Function(E self, E copy)? _whenOnClonedFn;

  /// Overrides instance creation during cloning.
  ///
  /// [_whenOnCreateInstanceFn] receives `self` and must return a fresh uninitialized instance.
  /// Called before [whenClone], so the instance can be pre-wired before
  /// the clone pipeline begins.
  E Function(E self)? _whenOnCreateInstanceFn;

  /// Registers [fn] as the clone factory, replacing the default [clone] behavior.
  E whenClone(E Function(E self, [C? cloner]) fn) {
    _whenOnCloneFn = fn;
    return self;
  }

  @nonVirtual
  E? _doWhenClone(E self, [C? cloner]) {
    if (_whenOnCloneFn == null) return null;
    return _whenOnCloneFn!(self, cloner);
  }

  /// Registers [fn] to run after the clone is produced.
  E whenCloned(E Function(E self, E copy) fn) {
    _whenOnClonedFn = fn;
    return self;
  }

  @nonVirtual
  E? _doWhenCloned(E self, E copy) {
    if (_whenOnClonedFn == null) return null;
    return _whenOnClonedFn!(self, copy);
  }

  /// Registers [fn] as the instance factory used during cloning.
  E whenCreateInstance(E Function(E self) fn) {
    _whenOnCreateInstanceFn = fn;
    return self;
  }

  @nonVirtual
  E? _doWhenCreateInstance(E self) {
    if (_whenOnCreateInstanceFn == null) return null;
    return _whenOnCreateInstanceFn!(self);
  }

  /// Asserts that [x] is not the same instance as `this`.
  ///
  /// Throws if [whenClone] returned `self` instead of a fresh instance.
  @nonVirtual
  void _doCheckIsCloneFresh(E x) {
    if (x != this) return;
    throw Exception('$runtimeType.whenClone() must return a fresh instance, you can call self.createInstance()');
  }

  /// Begins the clone pipeline: runs before-hooks and marks the copy as cloning.
  ///
  /// Returns `false` if any before-hook cancels the clone.
  @nonVirtual
  bool _doCloneBefore(E target, [C? cloner]) {
    if (!_doOnBeforeClone(target, cloner)) return false;
    if (target is IsCloneable<T, E, C>) {
      target.isClone = true;
      target.isCloning = true;
    }
    return true;
  }

  /// Finalizes the clone pipeline: clears [isCloning], sets [isCloned], and
  /// calls [onCloned] on the copy followed by after-hooks on the origin.
  void _doCloneAfter(E target, [C? cloner]) {
    if (target is IsCloneable<T, E, C>) {
      target.isCloning = false;
      target.isCloned = true;
      target.onCloned(self);
    }
    _doOnAfterClone(target, cloner);
  }

  /// Override to provide a fresh uninitialized instance of this type.
  ///
  /// Required for cloning to work. Example:
  /// ```dart
  /// @override
  /// MyEntity createInstance() => MyEntity(app);
  /// ```
  E createInstance() {
    final type = runtimeType.toString();
    throw UnsupportedError(
      'Clone capability requires overriding $type.createInstance().\n'
      'Example: @override $type createInstance() => .new(app);'
    );
  }

  /// Override to customize how state is copied into [newInstance].
  ///
  /// Returns the populated copy. By default returns [newInstance] unchanged.
  E createClone(E newInstance, [C? cloner]) => newInstance;

  void _doCloneState(E target, C? cloner) {
    bool allowedHook(ECSHookKey hook)
      => cloner == null || cloner.allowHook(target, hook);

    bool allowedState(CloneStateType state)
      => cloner == null || cloner.allowState(target, state);

    if (self case HasExternalHooks<T> from) {
      if (target case HasExternalHooks<T> to) {
        from._copyHooksTo(to, allowedHook);
      }
    }

    // TODO: states

    // if (self case IsActivatable<T, E> from) {
    //   if (target case IsActivatable<T, E> to) {
    //     if (allowedState(.active)) {
    //       to._active = from._active;
    //     }
    //   }
    // }

    // if (self case IsCancelable<T, E> from) {
    //   if (target case IsCancelable<T, E> to) {
    //     if (allowedState(.canceled)) {
    //       to._isCanceled = from._isCanceled;
    //     }
    //   }
    // }

    // if (self case IsCallbackProcessable<T, E> from) {
    //   if (target case IsCallbackProcessable<T, E> to) {
    //     if (allowedState(.callbackQueue)) {
    //       to._callbackQueue = .from(from._callbackQueue);
    //     }
    //   }
    // }

    // if (self case IsEventHistoryHolder<T, E> from) {
    //   if (target case IsEventHistoryHolder<T, E> to) {
    //     if (allowedState(.eventHistory)) {
    //       to._eventHistory = .from(from._eventHistory);
    //     }
    //   }
    // }

    // if (self case IsEventQueueHolder<T, E> from) {
    //   if (target case IsEventQueueHolder<T, E> to) {
    //     if (allowedState(.eventQueue)) {
    //       to._eventQueue = .from(from._eventQueue);
    //     }
    //   }
    // }

    // if (self case IsTaskProcessable<T, E> from) {
    //   if (target case IsTaskProcessable<T, E> to) {
    //     if (allowedState(.pendingTaskQueue)) {
    //       to._pendingTaskQueue = .from(from._pendingTaskQueue);
    //     }

    //     if (allowedState(.taskQueue)) {
    //       to._taskQueue = .from(from._taskQueue);
    //     }
    //   }
    // }

    // //////////////// //
    // ADDITIONAL STATE //
    // //////////////// //

    if (self case HasVars<T, E> from) {
      if (target case HasVars<T, E> to) {
        if (allowedState(.vars)) {
          to._vars = .from(from._vars);
        }
      }
    }

    if (cloner?.allowState(target, .identity) ?? false) {
      target._id = self._id;
      target._namedId = self._namedId;
      target.name = self.name;
    }
  }
}