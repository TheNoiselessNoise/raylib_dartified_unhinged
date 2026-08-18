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
> on Self<E>, ECSBase<T> {
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
                                                            

  List<bool Function(E copy, [C? cloner])> _onBeforeCloneFns = [];

  List<void Function(E copy, [C? cloner])> _onCloneFns = [];

  List<void Function(E copy, [C? cloner])> _onAfterCloneFns = [];

  /// Registers [fn] as a before-clone listener.
  ///
  /// [fn] returning `false` cancels the clone.
  @nonVirtual
  E listenOnBeforeClone(bool Function(E copy, [C? cloner]) fn) {
    _onBeforeCloneFns.add(fn);
    return self;
  }

  /// Registers [fn] as a clone listener.
  ///
  /// Called when the clone operation is about to happen and was not canceled.
  @nonVirtual
  E listenOnClone(void Function(E copy, [C? cloner]) fn) {
    _onCloneFns.add(fn);
    return self;
  }

  /// Registers [fn] as an after-clone listener.
  ///
  /// Called only if the clone was not canceled.
  @nonVirtual
  E listenOnAfterClone(void Function(E copy, [C? cloner]) fn) {
    _onAfterCloneFns.add(fn);
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

  /// ***
  /// **Clone State Orchestrator** (aka: "**The God Function**")
  /// ***
  ///
  /// This function is intentionally *centralized* and *explicit*.
  ///
  /// It acts as the mechanical phase of the clone pipeline: given an `origin`
  /// and a `target`, it walks the capability surface of both objects and copies
  /// over any state or hook lists that are permitted by the active `Cloner`
  /// policy.
  ///
  /// Why is this not virtual / polymorphic / dispatched per mixin?
  ///
  /// Because in this framework, *capabilities are compositional*, not part of
  /// a fixed inheritance chain. There is no single "clone" method to override
  /// - objects are runtime containers of behavior, and this function is the
  /// place where those behaviors are discovered and synchronized.
  ///
  /// Design goals:
  /// - Keep clone behavior mechanical and policy-driven (via `Cloner`)
  /// - Avoid deep virtual call chains or hidden dispatch
  /// - Make all cloneable capabilities visible in one place
  /// - Keep the core small and predictable, even if this function grows
  ///
  /// Adding a new capability:
  /// - Define the mixin
  /// - Add a new guarded block here that copies its internal state
  /// - Gate it behind the appropriate `CloneHookType` / `CloneStateType`
  ///
  /// If this feels like a manual vtable, that's because it is - by design.
  void _doCloneState(E target, C? cloner) {
    bool allowedHook(CloneHookType hook)
      => cloner == null || cloner.allowHook(target, hook);

    bool allowedState(CloneStateType state)
      => cloner == null || cloner.allowState(target, state);

    if (self case App<T> from) {
      if (target case App<T> to) {
        if (allowedHook(.shouldExit)) {
          to._shouldExitFns = .from(from._shouldExitFns);
        }

        if (allowedHook(.onFrame)) {
          to._onFrameFns = .from(from._onFrameFns);
        }

        if (allowedHook(.onFPSChange)) {
          to._onFPSChangeFns = .from(from._onFPSChangeFns);
        }
        
        if (allowedHook(.onInit)) {
          to._onInitFns = .from(from._onInitFns);
        }

        if (allowedHook(.onExit)) {
          to._onExitFns = .from(from._onExitFns);
        }
      }
    }

    if (self case Scene<T> from) {
      if (target case Scene<T> to) {
        if (allowedHook(.onDrawBackground)) {
          to._onDrawBackgroundFns = .from(from._onDrawBackgroundFns);
        }

        if (allowedHook(.onDrawForeground)) {
          to._onDrawForegroundFns = .from(from._onDrawForegroundFns);
        }
      }
    }

    if (self case IsActivatable<T, E> from) {
      if (target case IsActivatable<T, E> to) {
        if (allowedState(.active)) {
          to._active = from._active;
        }

        if (allowedHook(.onActivate)) {
          to._onActivateFns = .from(from._onActivateFns);
        }
      }
    }

    if (self case IsAddable<T, E> from) {
      if (target case IsAddable<T, E> to) {
        if (allowedHook(.onBeforeAdd)) {
          to._onBeforeAddFns = .from(from._onBeforeAddFns);
        }

        if (allowedHook(.onAdd)) {
          to._onAddFns = .from(from._onAddFns);
        }

        if (allowedHook(.onAfterAdd)) {
          to._onAfterAddFns = .from(from._onAfterAddFns);
        }
      }
    }

    if (self case IsAppSystemManagable<T, E> from) {
      if (target case IsAppSystemManagable<T, E> to) {
        if (allowedHook(.onBeforeAppSystemAdd)) {
          to._onBeforeAppSystemAddFns = .from(from._onBeforeAppSystemAddFns);
        }

        if (allowedHook(.onAppSystemAdd)) {
          to._onAppSystemAddFns = .from(from._onAppSystemAddFns);
        }

        if (allowedHook(.onAfterAppSystemAdd)) {
          to._onAfterAppSystemAddFns = .from(from._onAfterAppSystemAddFns);
        }

        if (allowedHook(.onBeforeAppSystemRemove)) {
          to._onBeforeAppSystemRemoveFns = .from(from._onBeforeAppSystemRemoveFns);
        }

        if (allowedHook(.onAppSystemRemove)) {
          to._onAppSystemRemoveFns = .from(from._onAppSystemRemoveFns);
        }

        if (allowedHook(.onAfterAppSystemRemove)) {
          to._onAfterAppSystemRemoveFns = .from(from._onAfterAppSystemRemoveFns);
        }
      }
    }

    if (self case IsBeginEndFrameable<T, E> from) {
      if (target case IsBeginEndFrameable<T, E> to) {
        if (allowedHook(.onBeginFrame)) {
          to._onBeginFrameFns = .from(from._onBeginFrameFns);
        }

        if (allowedHook(.onEndFrame)) {
          to._onEndFrameFns = .from(from._onEndFrameFns);
        }
      }
    }

    if (self case IsCancelable<T, E> from) {
      if (target case IsCancelable<T, E> to) {
        if (allowedHook(.onBeforeCancel)) {
          to._onBeforeCancelFns = .from(from._onBeforeCancelFns);
        }

        if (allowedHook(.onCancel)) {
          to._onCancelFns = .from(from._onCancelFns);
        }

        if (allowedHook(.onAfterCancel)) {
          to._onAfterCancelFns = .from(from._onAfterCancelFns);
        }
      }
    }

    if (self case IsCloneable<T, E, C> from) {
      if (target case IsCloneable<T, E, C> to) {
        if (allowedHook(.onBeforeClone)) {
          to._onBeforeCloneFns = .from(from._onBeforeCloneFns);
        }

        if (allowedHook(.onClone)) {
          to._onCloneFns = .from(from._onCloneFns);
        }

        if (allowedHook(.onAfterClone)) {
          to._onAfterCloneFns = .from(from._onAfterCloneFns);
        }

        if (allowedHook(.whenOnClone)) {
          to._whenOnCloneFn = from._whenOnCloneFn;
        }

        if (allowedHook(.whenOnCloned)) {
          to._whenOnClonedFn = from._whenOnClonedFn;
        }

        if (allowedHook(.whenOnCreateInstance)) {
          to._whenOnCreateInstanceFn = from._whenOnCreateInstanceFn;
        }
      }
    }

    if (self case IsCollidable<T, E, CCollider<T>> from) {
      if (target case IsCollidable<T, E, CCollider<T>> to) {
        if (allowedHook(.onBeforeCollision)) {
          to._onBeforeCollisionFns = .from(from._onBeforeCollisionFns);
        }

        if (allowedHook(.onCollision)) {
          to._onCollisionFns = .from(from._onCollisionFns);
        }

        if (allowedHook(.onAfterCollision)) {
          to._onAfterCollisionFns = .from(from._onAfterCollisionFns);
        }
      }
    }

    if (self case IsCallbackProcessable<T, E> from) {
      if (target case IsCallbackProcessable<T, E> to) {
        if (allowedState(.callbackQueue)) {
          to._callbackQueue = .from(from._callbackQueue);
        }
      }
    }

    if (self case IsComponentManagable<T, E> from) {
      if (target case IsComponentManagable<T, E> to) {
        if (allowedHook(.onBeforeCompAdd)) {
          to._onBeforeCompAddFns = .from(from._onBeforeCompAddFns);
        }
        
        if (allowedHook(.onCompAdd)) {
          to._onCompAddFns = .from(from._onCompAddFns);
        }

        if (allowedHook(.onAfterCompAdd)) {
          to._onAfterCompAddFns = .from(from._onAfterCompAddFns);
        }

        if (allowedHook(.onBeforeCompRemove)) {
          to._onBeforeCompRemoveFns = .from(from._onBeforeCompRemoveFns);
        }

        if (allowedHook(.onCompRemove)) {
          to._onCompRemoveFns = .from(from._onCompRemoveFns);
        }

        if (allowedHook(.onAfterCompRemove)) {
          to._onAfterCompRemoveFns = .from(from._onAfterCompRemoveFns);
        }

        if (allowedHook(.onBeforeCompClone)) {
          to._onBeforeCompCloneFns = .from(from._onBeforeCompCloneFns);
        }

        if (allowedHook(.onCompClone)) {
          to._onCompCloneFns = .from(from._onCompCloneFns);
        }

        if (allowedHook(.onAfterCompClone)) {
          to._onAfterCompCloneFns = .from(from._onAfterCompCloneFns);
        }
      }
    }

    if (self case IsDisposable<T, E> from) {
      if (target case IsDisposable<T, E> to) {
        if (allowedHook(.onDispose)) {
          to._onDisposeFns = .from(from._onDisposeFns);
        }
      }
    }

    if (self case IsDrawable<T, E> from) {
      if (target case IsDrawable<T, E> to) {
        if (allowedHook(.onPreDraw)) {
          to._onDrawFns = .from(from._onDrawFns);
        }
      }
    }

    if (self case IsEnterable<T, E> from) {
      if (target case IsEnterable<T, E> to) {
        if (allowedHook(.onBeforeEnter)) {
          to._onBeforeEnterFns = .from(from._onBeforeEnterFns);
        }

        if (allowedHook(.onEnter)) {
          to._onEnterFns = .from(from._onEnterFns);
        }

        if (allowedHook(.onAfterEnter)) {
          to._onAfterEnterFns = .from(from._onAfterEnterFns);
        }
      }
    }

    if (self case IsEntityManagable<T, E, Entity<T>> from) {
      if (target case IsEntityManagable<T, E, Entity<T>> to) {
        if (allowedHook(.onBeforeEntityAdd)) {
          to._onBeforeEntityAddFns = .from(from._onBeforeEntityAddFns);
        }

        if (allowedHook(.onEntityAdd)) {
          to._onEntityAddFns = .from(from._onEntityAddFns);
        }

        if (allowedHook(.onAfterEntityAdd)) {
          to._onAfterEntityAddFns = .from(from._onAfterEntityAddFns);
        }

        if (allowedHook(.onBeforeEntityRemove)) {
          to._onBeforeEntityRemoveFns = .from(from._onBeforeEntityRemoveFns);
        }

        if (allowedHook(.onEntityRemove)) {
          to._onEntityRemoveFns = .from(from._onEntityRemoveFns);
        }

        if (allowedHook(.onAfterEntityRemove)) {
          to._onAfterEntityRemoveFns = .from(from._onAfterEntityRemoveFns);
        }
      }
    }

    if (self case IsEventEmittable<T, E> from) {
      if (target case IsEventEmittable<T, E> to) {
        if (allowedState(.eventQueue))

        if (allowedHook(.onBeforeEvent)) {
          to._onBeforeEventFns = .from(from._onBeforeEventFns);
        }

        if (allowedHook(.onEvent)) {
          to._onEventFns = .from(from._onEventFns);
        }

        if (allowedHook(.onBeforeEventEmit)) {
          to._onBeforeEventEmitFns = .from(from._onBeforeEventEmitFns);
        }
        
        if (allowedHook(.onBeforeEventDispatch)) {
          to._onBeforeEventDispatchFns = .from(from._onBeforeEventDispatchFns);
        }
      }
    }

    if (self case IsEventHistoryHolder<T, E> from) {
      if (target case IsEventHistoryHolder<T, E> to) {
        if (allowedState(.eventHistory)) {
          to._eventHistory = .from(from._eventHistory);
        }

        if (allowedHook(.onBeforeEventRecorded)) {
          to._onBeforeEventRecordedFns = .from(from._onBeforeEventRecordedFns);
        }

        if (allowedHook(.onEventRecorded)) {
          to._onEventRecordedFns = .from(from._onEventRecordedFns);
        }
      }
    }

    if (self case IsEventQueueHolder<T, E> from) {
      if (target case IsEventQueueHolder<T, E> to) {
        if (allowedState(.eventQueue)) {
          to._eventQueue = .from(from._eventQueue);
        }
      }
    }

    if (self case IsInputHandleable<E> from) {
      if (target case IsInputHandleable<E> to) {
        if (allowedHook(.onHandleInput)) {
          to._onHandleInputFns = .from(from._onHandleInputFns);
        }
      }
    }

    if (self case IsLeavable<T, E> from) {
      if (target case IsLeavable<T, E> to) {
        if (allowedHook(.onBeforeLeave)) {
          to._onBeforeLeaveFns = .from(from._onBeforeLeaveFns);
        }

        if (allowedHook(.onLeave)) {
          to._onLeaveFns = .from(from._onLeaveFns);
        }

        if (allowedHook(.onAfterLeave)) {
          to._onAfterLeaveFns = .from(from._onAfterLeaveFns);
        }
      }
    }

    if (self case IsPersistableBase<T, E> from) {
      if (target case IsPersistableBase<T, E> to) {
        if (allowedHook(.onBeforeStorePersistable)) {
          to._onBeforeStorePersistableFns = .from(from._onBeforeStorePersistableFns);
        }

        if (allowedHook(.onStorePersistable)) {
          to._onStorePersistableFns = .from(from._onStorePersistableFns);
        }
      }
    }

    if (self case IsPrePostDrawable<T, E> from) {
      if (target case IsPrePostDrawable<T, E> to) {
        if (allowedHook(.onPreDraw)) {
          to._onPreDrawFns = .from(from._onPreDrawFns);
        }

        if (allowedHook(.onPostDraw)) {
          to._onPostDrawFns = .from(from._onPostDrawFns);
        }
      }
    }

    if (self case IsPrePostUpdatable<T, E> from) {
      if (target case IsPrePostUpdatable<T, E> to) {
        if (allowedHook(.onPreUpdate)) {
          to._onPreUpdateFns = .from(from._onPreUpdateFns);
        }

        if (allowedHook(.onPostUpdate)) {
          to._onPostUpdateFns = .from(from._onPostUpdateFns);
        }
      }
    }

    if (self case IsRemovable<T, E> from) {
      if (target case IsRemovable<T, E> to) {
        if (allowedHook(.onBeforeRemove)) {
          to._onBeforeRemoveFns = .from(from._onBeforeRemoveFns);
        }

        if (allowedHook(.onRemove)) {
          to._onRemoveFns = .from(from._onRemoveFns);
        }
        
        if (allowedHook(.onAfterRemove)) {
          to._onAfterRemoveFns = .from(from._onAfterRemoveFns);
        }
      }
    }

    if (self case IsSceneManagable<T, E> from) {
      if (target case IsSceneManagable<T, E> to) {
        if (allowedHook(.onBeforeSceneAdd)) {
          to._onBeforeSceneAddFns = .from(from._onBeforeSceneAddFns);
        }

        if (allowedHook(.onSceneAdd)) {
          to._onSceneAddFns = .from(from._onSceneAddFns);
        }

        if (allowedHook(.onAfterSceneAdd)) {
          to._onAfterSceneAddFns = .from(from._onAfterSceneAddFns);
        }

        if (allowedHook(.onBeforeSceneRemove)) {
          to._onBeforeSceneRemoveFns = .from(from._onBeforeSceneRemoveFns);
        }

        if (allowedHook(.onSceneRemove)) {
          to._onSceneRemoveFns = .from(from._onSceneRemoveFns);
        }

        if (allowedHook(.onAfterSceneRemove)) {
          to._onAfterSceneRemoveFns = .from(from._onAfterSceneRemoveFns);
        }
      }
    }

    if (self case IsSceneSystemManagable<T, E> from) {
      if (target case IsSceneSystemManagable<T, E> to) {
        if (allowedHook(.onBeforeSceneSystemAdd)) {
          to._onBeforeSceneSystemAddFns = .from(from._onBeforeSceneSystemAddFns);
        }

        if (allowedHook(.onSceneSystemAdd)) {
          to._onSceneSystemAddFns = .from(from._onSceneSystemAddFns);
        }

        if (allowedHook(.onAfterSceneSystemAdd)) {
          to._onAfterSceneSystemAddFns = .from(from._onAfterSceneSystemAddFns);
        }

        if (allowedHook(.onBeforeSceneSystemRemove)) {
          to._onBeforeSceneSystemRemoveFns = .from(from._onBeforeSceneSystemRemoveFns);
        }

        if (allowedHook(.onSceneSystemRemove)) {
          to._onSceneSystemRemoveFns = .from(from._onSceneSystemRemoveFns);
        }
        
        if (allowedHook(.onAfterSceneSystemRemove)) {
          to._onAfterSceneSystemRemoveFns = .from(from._onAfterSceneSystemRemoveFns);
        }
      }
    }

    if (self case IsSceneTransitionable<T, E> from) {
      if (target case IsSceneTransitionable<T, E> to) {
        if (allowedHook(.onBeforeSceneEnter)) {
          to._onBeforeSceneEnterFns = .from(from._onBeforeSceneEnterFns);
        }

        if (allowedHook(.onSceneEnter)) {
          to._onSceneEnterFns = .from(from._onSceneEnterFns);
        }

        if (allowedHook(.onAfterSceneEnter)) {
          to._onAfterSceneEnterFns = .from(from._onAfterSceneEnterFns);
        }

        if (allowedHook(.onBeforeSceneLeave)) {
          to._onBeforeSceneLeaveFns = .from(from._onBeforeSceneLeaveFns);
        }

        if (allowedHook(.onSceneLeave)) {
          to._onSceneLeaveFns = .from(from._onSceneLeaveFns);
        }

        if (allowedHook(.onAfterSceneLeave)) {
          to._onAfterSceneLeaveFns = .from(from._onAfterSceneLeaveFns);
        }

        if (allowedHook(.onBeforeSceneTransition)) {
          to._onBeforeSceneTransitionFns = .from(from._onBeforeSceneTransitionFns);
        }

        if (allowedHook(.onSceneTransition)) {
          to._onSceneTransitionFns = .from(from._onSceneTransitionFns);
        }

        if (allowedHook(.onAfterSceneTransition)) {
          to._onAfterSceneTransitionFns = .from(from._onAfterSceneTransitionFns);
        }
      }
    }

    if (self case IsStartable<T, E> from) {
      if (target case IsStartable<T, E> to) {
        if (allowedHook(.onStart)) {
          to._onStartFns = .from(from._onStartFns);
        }
      }
    }

    if (self case IsTaskProcessable<T, E> from) {
      if (target case IsTaskProcessable<T, E> to) {
        if (allowedState(.pendingTaskQueue)) {
          to._pendingTaskQueue = .from(from._pendingTaskQueue);
        }

        if (allowedState(.taskQueue)) {
          to._taskQueue = .from(from._taskQueue);
        }

        if (allowedHook(.onTask)) {
          to._onTaskFns = .from(from._onTaskFns);
        }
      }
    }

    if (self case IsUpdatable<T, E> from) {
      if (target case IsUpdatable<T, E> to) {
        if (allowedHook(.onUpdate)) {
          to._onUpdateFns = .from(from._onUpdateFns);
        }
      }
    }

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