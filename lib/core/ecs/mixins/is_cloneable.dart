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
  E extends ECSBase<T>
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
    if (clone is! IsCloneable<T, E>) return;
    if (clone._isCloneAssigned) return;
    clone._isCloneAssigned = true;
    _clones.add(clone);
  }

  X cloneInto<X extends E>(X target, [ClonePolicy<T>? policy]) {
    if (!_doCloneBefore(target, policy)) return target;
    _assignClone(target);
    _doOnClone(target, policy);
    _doCloneState(target, policy);
    _doCloneAfter(target, policy);
    return target;
  }

  /// Produces a clone of this object.
  X clone<X extends E>([ClonePolicy<T>? policy]) {
    final newInstance = _doWhenCreateInstance(self) ?? createInstance();

    if (newInstance is! IsCloneable<T, E>) {
      throw StateError('Invalid (${newInstance.runtimeType}) newInstance returned, expected ${IsCloneable<T, E>}!');
    }
    
    _assignClone(newInstance);

    _doCheckIsCloneFresh(newInstance);
    if (newInstance.isCloned) {
      return (_doWhenCloned(self, newInstance) ?? newInstance) as X;
    }

    final readyToClone = _doWhenClone(self, policy) ?? createClone(newInstance, policy);

    if (readyToClone is! IsCloneable<T, E>) {
      throw StateError('Invalid (${readyToClone.runtimeType}) readyToClone returned, expected ${IsCloneable<T, E>}!');
    }

    _doCheckIsCloneFresh(readyToClone);
    if (readyToClone.isCloned) {
      return (_doWhenCloned(self, readyToClone) ?? readyToClone) as X;
    }

    final fullyCloned = cloneInto(readyToClone, policy);
    return (_doWhenCloned(self, fullyCloned) ?? fullyCloned) as X;
  }

  // ░██     ░██   ░██████     ░██████   ░██     ░██   ░██████   
  // ░██     ░██  ░██   ░██   ░██   ░██  ░██    ░██   ░██   ░██  
  // ░██     ░██ ░██     ░██ ░██     ░██ ░██   ░██   ░██         
  // ░██████████ ░██     ░██ ░██     ░██ ░███████     ░████████  
  // ░██     ░██ ░██     ░██ ░██     ░██ ░██   ░██           ░██ 
  // ░██     ░██  ░██   ░██   ░██   ░██  ░██    ░██   ░██   ░██  
  // ░██     ░██   ░██████     ░██████   ░██     ░██   ░██████   

  late final hookOnBeforeCloneKey = ECSHookKey<bool Function(E self, E copy, [ClonePolicy<T>? policy])>(
    'IsCloneable', 'onBeforeClone'
  );

  late final hookOnCloneKey = ECSHookKey<bool Function(E self, E copy, [ClonePolicy<T>? policy])>(
    'IsCloneable', 'onClone'
  );

  late final hookOnAfterCloneKey = ECSHookKey<bool Function(E self, E copy, [ClonePolicy<T>? policy])>(
    'IsCloneable', 'onAfterClone'
  );

  late final hookOnClonedKey = ECSHookKey<void Function(E self, E original)>(
    'IsCloneable', 'onCloned'
  );

  Iterable<bool Function(E self, E copy, [ClonePolicy<T>? policy])> get _onBeforeCloneFns
    => hooksOf(hookOnBeforeCloneKey);

  Iterable<void Function(E self, E copy, [ClonePolicy<T>? policy])> get _onCloneFns
    => hooksOf(hookOnCloneKey);

  Iterable<void Function(E self, E copy, [ClonePolicy<T>? policy])> get _onAfterCloneFns
    => hooksOf(hookOnAfterCloneKey);

  Iterable<void Function(E self, E original)> get _onClonedFns
    => hooksOf(hookOnClonedKey);

  /// Registers [fn] as a before-clone listener.
  ///
  /// [fn] returning `false` cancels the clone.
  @nonVirtual
  E listenOnBeforeClone(bool Function(E self, E copy, [ClonePolicy<T>? policy]) fn) {
    addHook(hookOnBeforeCloneKey, fn);
    return self;
  }

  /// Registers [fn] as a clone listener.
  ///
  /// Called when the clone operation is about to happen and was not canceled.
  @nonVirtual
  E listenOnClone(void Function(E self, E copy, [ClonePolicy<T>? policy]) fn) {
    addHook(hookOnCloneKey, fn);
    return self;
  }

  /// Registers [fn] as an after-clone listener.
  ///
  /// Called only if the clone was not canceled.
  @nonVirtual
  E listenOnAfterClone(void Function(E self, E copy, [ClonePolicy<T>? policy]) fn) {
    addHook(hookOnAfterCloneKey, fn);
    return self;
  }

  /// Registers [fn] as a cloned listener.
  ///
  /// Called on cloned reference.
  @nonVirtual
  E listenOnCloned(void Function(E self, E original) fn) {
    addHook(hookOnClonedKey, fn);
    return self;
  }

  /// Runs all before-clone listeners and [onBeforeClone].
  ///
  /// Returns `false` if any listener or the override cancels the clone.
  @nonVirtual
  bool _doOnBeforeClone(E copy, [ClonePolicy<T>? policy]) {
    if (!_onBeforeCloneFns.every((f) => f(self, copy, policy))) return false;
    return onBeforeClone(copy, policy);
  }

  /// Runs all clone listeners and [onClone].
  @mustCallSuper
  void _doOnClone(E copy, [ClonePolicy<T>? policy]) {
    _onCloneFns.forEach((f) => f(self, copy, policy));
    onClone(copy, policy);
  }

  /// Runs all after-clone listeners and [onAfterClone].
  @nonVirtual
  void _doOnAfterClone(E copy, [ClonePolicy<T>? policy]) {
    _onAfterCloneFns.forEach((f) => f(self, copy, policy));
    onAfterClone(copy, policy);
  }

  /// Runs all cloned listeners and [onCloned].
  @mustCallSuper
  void _doOnCloned(E original) {
    _onClonedFns.forEach((f) => f(self, original));
    onCloned(original);
  }

  /// Override to cancel cloning from within the class.
  ///
  /// Return `false` to abort. Called after all registered [listenOnBeforeClone] listeners.
  bool onBeforeClone(E copy, [ClonePolicy<T>? policy]) => true;

  /// Override to react when cloning is about to complete.
  ///
  /// Called by the host after all before-checks have passed.
  void onClone(E copy, [ClonePolicy<T>? policy]) {}

  /// Override to react after cloning has completed.
  ///
  /// Called after all registered [listenOnAfterClone] listeners.
  void onAfterClone(E copy, [ClonePolicy<T>? policy]) {}

  /// Called on the *copy* after cloning completes, with a reference to [original].
  ///
  /// Override to perform post-clone fixup on the new instance.
  void onCloned(E original) {}

  /// Overrides the default clone behavior.
  ///
  /// [_whenOnCloneFn] receives `self` and must return a fresh instance. Returning `self`
  /// is a runtime error caught by [_doCheckIsCloneFresh].
  E Function(E self, [ClonePolicy<T>? policy])? _whenOnCloneFn;

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
  E whenClone(E Function(E self, [ClonePolicy<T>? policy]) fn) {
    _whenOnCloneFn = fn;
    return self;
  }

  @nonVirtual
  E? _doWhenClone(E self, [ClonePolicy<T>? policy]) {
    if (_whenOnCloneFn == null) return null;
    return _whenOnCloneFn!(self, policy);
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
  bool _doCloneBefore(E target, [ClonePolicy<T>? policy]) {
    if (!_doOnBeforeClone(target, policy)) return false;
    if (target is IsCloneable<T, E>) {
      target.isClone = true;
      target.isCloning = true;
    }
    return true;
  }

  /// Finalizes the clone pipeline: clears [isCloning], sets [isCloned], and
  /// calls [onCloned] on the copy followed by after-hooks on the origin.
  @mustCallSuper
  void _doCloneAfter(E target, [ClonePolicy<T>? policy]) {
    if (target is IsCloneable<T, E>) {
      target.isCloning = false;
      target.isCloned = true;
      target._doOnCloned(self);
    }
    _doOnAfterClone(target, policy);
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
  E createClone(E newInstance, [ClonePolicy<T>? policy]) => newInstance;

  @mustCallSuper
  void _doCloneState(E target, ClonePolicy<T>? policy) {
    
    // hooks

    bool allowedHook(ECSHookKey hook)
      => policy == null || policy.allowHook(target, hook);

    if (self case HasExternalHooks<T> from) {
      if (target case HasExternalHooks<T> to) {
        from._copyHooksTo(to, allowedHook);
      }
    }

    // state

    bool allowedState(ECSStateKey state)
      => policy == null || policy.allowState(target, state);

    if (self case HasCloneableState<T> from) {
      if (target case HasCloneableState<T> to) {
        from._copyStateTo(to, allowedState);
      }
    }

    // identity

    if (policy?.allowState(target, target.stateIdentityKey) ?? false) {
      target._id = self._id;
      target._namedId = self._namedId;
      target.name = self.name;
    }
  }
}