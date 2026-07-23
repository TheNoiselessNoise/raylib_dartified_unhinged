part of '../raylib_dartified_unhinged.dart';

/// Provides a type-safe [self] reference and a fluent [onSelf] helper.
///
/// Mixed into ECS objects to avoid repeated `this as T` casts throughout the
/// codebase. The cast is safe as long as the concrete class declares `T` as
/// itself:
/// ```
/// class SomeClass<T extends App<T>> extends ECSBase<T> with Self<SomeClass<T>> {}
/// ```
mixin Self<T> {
  /// This object cast to [T].
  T get self => this as T;

  /// Calls [fn] with [self] and returns [self], for fluent chaining.
  T onSelf(void Function(T self) fn) {
    fn(self);
    return self;
  }
}

/// Provides convenient access to top-level [App] subsystems.
///
/// Mixed into any object that holds an [app] reference, exposing commonly
/// used subsystems as direct getters rather than requiring `app.x` everywhere.
mixin HasAppAccess<T extends App<T>> {
  T get app;

  /// Shorthand for [App.backend].
  UnhingedBackend get backend => app.backend;
  
  /// Shorthand for [App.input].
  InputSystem<T> get input => app.input;

  /// Shorthand for [App.renderer].
  Renderer<T> get renderer => app.renderer;

  /// Shorthand for [App.draw].
  Drawers<T> get draw => app.draw;

  /// Shorthand for [App.currentScene].
  Scene<T> get scene => app.currentScene;

  /// Shorthand for [App.time].
  AppTime<T> get time => app.time;

  /// Shorthand for [App.screenSize].
  Vector2D get screenSize => app.screenSize;

  /// Shorthand for [App]'s width.
  double get screenWidth => screenSize.x;

  /// Shorthand for [App]'s height.
  double get screenHeight => screenSize.y;
}

/// Provides access to the [Scene] this object belongs to.
mixin HasSceneAccess<T extends App<T>> on HasAppAccess<T> {
  Bounds get sceneBounds => scene.sceneBounds;

  Vector2D get sceneSize => sceneBounds.size;

  double get sceneWidth => sceneBounds.width;

  double get sceneHeight => sceneBounds.height;

  void callback(void Function() callback) => scene.callback(callback);

  void task(Task<T> task) => scene.task(task);

  void run(Task<T> task) => scene.run(task);
}

/// Provides access to the [Entity] this object belongs to.
mixin HasEntityAccess<T extends App<T>> on ECSBase<T> {
  Entity<T> get entity;
}

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

/// Adds add lifecycle hooks to an ECS object, from the object's own perspective.
///
/// Complements [IsAppSystemManagable], [IsSceneSystemManagable], [IsSceneManagable], [IsEntityManagable], [IsComponentManagable]
/// (which hooks from the *host* side) by giving the object being added its own three-phase contract:
/// - **before** => cancelable; any listener or override returning `false` aborts the operation
/// - **on** => the operation is about to complete; called by the host after all before-checks pass
/// - **after** => the operation has completed; side-effects and cleanup go here
mixin IsAddable<T extends App<T>, E extends ECSBase<T>> on ECSBase<T>, Self<E> {

  /// Whether this object has been added to a host.
  bool _isAdded = false;
  
  bool get isAdded => _isAdded;

  List<bool Function(E self, ECSBase<T> parent)> _onBeforeAddFns = [];

  List<void Function(E self, ECSBase<T> parent)> _onAddFns = [];

  List<void Function(E self, ECSBase<T> parent)> _onAfterAddFns = [];

  /// Registers [fn] as a before-add listener.
  ///
  /// [fn] returning `false` cancels the add.
  @nonVirtual
  E listenOnBeforeAdd(bool Function(E self, ECSBase<T> parent) fn) {
    _onBeforeAddFns.add(fn);
    return self;
  }

  /// Registers [fn] as an add listener.
  ///
  /// Called when the add operation is about to happen and was not canceled.
  @nonVirtual
  E listenOnAdd(void Function(E self, ECSBase<T> parent) fn) {
    _onAddFns.add(fn);
    return self;
  }

  /// Registers [fn] as an after-add listener.
  ///
  /// Called only if the add was not canceled.
  @nonVirtual
  E listenOnAfterAdd(void Function(E self, ECSBase<T> parent) fn) {
    _onAfterAddFns.add(fn);
    return self;
  }

  /// Runs all before-add listeners and [onBeforeAdd].
  ///
  /// Returns `false` if any listener or the override cancels the add.
  bool _doOnBeforeAdd(ECSBase<T> parent) {
    if (!_onBeforeAddFns.every((f) => f(self, parent))) return false;
    return onBeforeAdd(parent);
  }

  /// Runs all add listeners and [onAdd].
  void _doOnAdd(ECSBase<T> parent) {
    _onAddFns.forEach((f) => f(self, parent));
    onAdd(parent);
  }

  /// Runs all after-add listeners and [onAfterAdd].
  void _doOnAfterAdd(ECSBase<T> parent) {
    _onAfterAddFns.forEach((f) => f(self, parent));
    onAfterAdd(parent);
  }

  /// Override to cancel the add from within the class.
  ///
  /// Return `false` to abort. Called after all registered [listenOnBeforeAdd] listeners.
  bool onBeforeAdd(ECSBase<T> parent) => true;

  /// Override to react when the add is about to complete.
  ///
  /// Called after all registered [listenOnAdd] listeners.
  void onAdd(ECSBase<T> parent) {}

  /// Override to react after the add has completed.
  ///
  /// Called after all registered [listenOnAfterAdd] listeners.
  void onAfterAdd(ECSBase<T> parent) {}

  /// Commits the add: sets [isAdded], assigns [parent], and notifies listeners.
  ///
  /// No-op if already added.
  void _doAdd(ECSBase<T> parent) {
    if (isAdded) return;
    this.parent ??= parent;
    _isAdded = true;
    _doOnAdd(parent);
  }
}

/// Adds app system add/remove lifecycle hooks to an [App].
///
/// Covers two events: system add and system remove, each with a full
/// three-phase contract:
/// - **before** => cancelable; any listener or override returning `false` aborts the operation
/// - **on** => the operation is about to complete; called by the host after all before-checks pass
/// - **after** => the operation has completed; side-effects and cleanup go here
mixin IsAppSystemManagable<T extends App<T>, E extends ECSBase<T>> on Self<E>, ECSBase<T>, IsEventEmittable<T, E> {

  // ░██     ░██   ░██████     ░██████   ░██     ░██   ░██████   
  // ░██     ░██  ░██   ░██   ░██   ░██  ░██    ░██   ░██   ░██  
  // ░██     ░██ ░██     ░██ ░██     ░██ ░██   ░██   ░██         
  // ░██████████ ░██     ░██ ░██     ░██ ░███████     ░████████  
  // ░██     ░██ ░██     ░██ ░██     ░██ ░██   ░██           ░██ 
  // ░██     ░██  ░██   ░██   ░██   ░██  ░██    ░██   ░██   ░██  
  // ░██     ░██   ░██████     ░██████   ░██     ░██   ░██████   

  List<bool Function(E self, AppSystem<T> system)> _onBeforeAppSystemAddFns = [];

  List<void Function(E self, AppSystem<T> system)> _onAppSystemAddFns = [];

  List<void Function(E self, AppSystem<T> system)> _onAfterAppSystemAddFns = [];

  List<bool Function(E self, AppSystem<T> system)> _onBeforeAppSystemRemoveFns = [];

  List<void Function(E self, AppSystem<T> system)> _onAppSystemRemoveFns = [];

  List<void Function(E self, AppSystem<T> system)> _onAfterAppSystemRemoveFns = [];

  /// Registers [fn] as a before-add listener.
  ///
  /// [fn] returning `false` cancels the system add.
  @nonVirtual
  E listenOnBeforeAppSystemAdd(bool Function(E self, AppSystem<T> system) fn) {
    _onBeforeAppSystemAddFns.add(fn);
    return self;
  }

  /// Registers [fn] as an add listener.
  ///
  /// Called when the add operation is about to happen and was not canceled.
  @nonVirtual
  E listenOnAppSystemAdd(void Function(E self, AppSystem<T> system) fn) {
    _onAppSystemAddFns.add(fn);
    return self;
  }

  /// Registers [fn] as an after-add listener.
  ///
  /// Called only if the system add was not canceled.
  @nonVirtual
  E listenOnAfterAppSystemAdd(void Function(E self, AppSystem<T> system) fn) {
    _onAfterAppSystemAddFns.add(fn);
    return self;
  }

  /// Registers [fn] as a before-remove listener.
  ///
  /// [fn] returning `false` cancels the system remove.
  @nonVirtual
  E listenOnBeforeAppSystemRemove(bool Function(E self, AppSystem<T> system) fn) {
    _onBeforeAppSystemRemoveFns.add(fn);
    return self;
  }

  /// Registers [fn] as a remove listener.
  ///
  /// Called when the remove operation is about to happen and was not canceled.
  @nonVirtual
  E listenOnAppSystemRemove(void Function(E self, AppSystem<T> system) fn) {
    _onAppSystemRemoveFns.add(fn);
    return self;
  }

  /// Registers [fn] as an after-remove listener.
  ///
  /// Called only if the system remove was not canceled.
  @nonVirtual
  E listenOnAfterAppSystemRemove(void Function(E self, AppSystem<T> system) fn) {
    _onAfterAppSystemRemoveFns.add(fn);
    return self;
  }

  /// Runs all before-add listeners and [onBeforeAppSystemAdd].
  ///
  /// Returns `false` if any listener or the override cancels the add.
  bool _doOnBeforeAppSystemAdd(AppSystem<T> system) {
    if (!_onBeforeAppSystemAddFns.every((f) => f(self, system))) return false;
    return onBeforeAppSystemAdd(system);
  }
  
  /// Runs all add listeners and [onAppSystemAdd].
  void _doOnAppSystemAdd(AppSystem<T> system) {
    _onAppSystemAddFns.forEach((f) => f(self, system));
    onAppSystemAdd(system);
  }

  /// Runs all after-add listeners and [onAfterAppSystemAdd].
  void _doOnAfterAppSystemAdd(AppSystem<T> system) {
    _onAfterAppSystemAddFns.forEach((f) => f(self, system));
    onAfterAppSystemAdd(system);
  }

  /// Runs all before-remove listeners and [onBeforeAppSystemRemove].
  ///
  /// Returns `false` if any listener or the override cancels the remove.
  bool _doOnBeforeAppSystemRemove(AppSystem<T> system) {
    if (!_onBeforeAppSystemRemoveFns.every((f) => f(self, system))) return false;
    return onBeforeAppSystemRemove(system);
  }

  /// Runs all remove listeners and [onAppSystemRemove].
  void _doOnAppSystemRemove(AppSystem<T> system) {
    _onAppSystemRemoveFns.forEach((f) => f(self, system));
    onAppSystemRemove(system);
  }

  /// Runs all after-remove listeners and [onAfterAppSystemRemove].
  void _doOnAfterAppSystemRemove(AppSystem<T> system) {
    _onAfterAppSystemRemoveFns.forEach((f) => f(self, system));
    onAfterAppSystemRemove(system);
  }

  /// Override to cancel a system add from within the class.
  ///
  /// Return `false` to abort. Called after all registered [listenOnBeforeAppSystemAdd] listeners.
  bool onBeforeAppSystemAdd(AppSystem<T> system) => true;

  /// Override to react when a system add is about to complete.
  ///
  /// Called by the host after all before-checks have passed.
  void onAppSystemAdd(AppSystem<T> system) {}

  /// Override to react after a system add has completed.
  ///
  /// Called after all registered [listenOnAfterAppSystemAdd] listeners.
  void onAfterAppSystemAdd(AppSystem<T> system) {}

  /// Override to cancel a system remove from within the class.
  ///
  /// Return `false` to abort. Called after all registered [listenOnBeforeAppSystemRemove] listeners.
  bool onBeforeAppSystemRemove(AppSystem<T> system) => true;

  /// Override to react when a system remove is about to complete.
  ///
  /// Called by the host after all before-checks have passed.
  void onAppSystemRemove(AppSystem<T> system) {}

  /// Override to react after a system remove has completed.
  ///
  /// Called after all registered [listenOnAfterAppSystemRemove] listeners.
  void onAfterAppSystemRemove(AppSystem<T> system) {}

  // ░██████░███     ░███ ░█████████  ░██         
  //   ░██  ░████   ░████ ░██     ░██ ░██         
  //   ░██  ░██░██ ░██░██ ░██     ░██ ░██         
  //   ░██  ░██ ░████ ░██ ░█████████  ░██         
  //   ░██  ░██  ░██  ░██ ░██         ░██         
  //   ░██  ░██       ░██ ░██         ░██         
  // ░██████░██       ░██ ░██         ░██████████ 

  final List<AppSystem<T>> _systems = [];

  Iterable<AppSystem<T>> getSystems() => _systems;

  /// Replaces the first app system whose `runtimeType == system.runtimeType` with [system].
  E replaceSystem(AppSystem<T> system) {
    final old = _systems.where((c) => c.runtimeType == system.runtimeType).firstOrNull;
    if (old != null) _removeAppSystemInstance(old);
    addSystem(system);
    return self;
  }

  /// Moves the first found system of type [S] to the specified [index].
  /// No-op if no system of type [S] is found.
  /// Clamps [index] to the valid range of the list.
  void relocateSystem<S extends SceneSystem<T>>(int index) {
    final currentIndex = _systems.indexWhere((s) => s is S);
    if (currentIndex == -1) return;

    final system = _systems.removeAt(currentIndex);
    final clampedIndex = index.clamp(0, _systems.length);
    _systems.insert(clampedIndex, system);
  }

  /// Exchanges the positions of the first found system of type [A]
  /// with the first found system of type [B].
  /// No-op if either type is not found.
  void exchangeSystems<A extends SceneSystem<T>, B extends SceneSystem<T>>() {
    final indexA = _systems.indexWhere((s) => s is A);
    if (indexA == -1) return;

    final indexB = _systems.indexWhere((s) => s is B);
    if (indexB == -1) return;

    if (indexA == indexB) return;

    final temp = _systems[indexA];
    _systems[indexA] = _systems[indexB];
    _systems[indexB] = temp;
  }

  void swapSystem<A extends AppSystem<T>>(AppSystem<T> newS) {
    if (hasSystem<A>()) removeSystem<A>();
    addSystem(newS);
  }

  void swapSystemByType<B extends AppSystem<T>>(Type type, B newS) {
    if (hasSystemByType(type)) removeSystemByType(type);
    addSystem<B>(newS);
  }

  void addSystem<S extends AppSystem<T>>(S system) {
    emit(EventAppSystemAdding(app, system));

    if (!_doOnBeforeAppSystemAdd(system)) {
      emit(EventAppSystemAddCancelled(app, system));
      return;
    }

    if (!system._doOnBeforeAdd(self)) {
      emit(EventAppSystemAddCancelled(app, system));
      return;
    }

    _doOnAppSystemAdd(system);
    if (!system.isClone) system._doAdd(self);

    _systems.add(system);

    system._doOnAfterAdd(self);
    _doOnAfterAppSystemAdd(system);
    emit(EventAppSystemAdded(app, system));
  }

  S? getSystem<S extends AppSystem<T>>() => _systems.whereType<S>().firstOrNull;

  bool hasSystem<S extends AppSystem<T>>() => _systems.any((s) => s is S);

  bool hasSystemByType(Type type)
    => _systems.any((c) => c.runtimeType == type);

  E removeSystem<S extends AppSystem<T>>() {
    final c = getSystem<S>();
    if (c != null) _removeAppSystemInstance(c);
    return self;
  }

  E removeSystemByType(Type type) {
    final system = _systems.where((c) => c.runtimeType == type).firstOrNull;
    if (system != null) _removeAppSystemInstance(system);
    return self;
  }

  void _removeAppSystemInstance(AppSystem<T> system) {
    if (!_systems.contains(system)) return;
      
    emit(EventAppSystemRemoving(app, system));

    if (!_doOnBeforeAppSystemRemove(system)) {
      emit(EventAppSystemRemoveCancelled(app, system));
      return;
    }

    if (!system._doOnBeforeRemove()) {
      emit(EventAppSystemRemoveCancelled(app, system));
      return;
    }

    _doOnAppSystemRemove(system);
    system._doRemove();
    _systems.remove(system);

    system._doOnAfterRemove();
    _doOnAfterAppSystemRemove(system);
    emit(EventAppSystemRemoved(app, system));
  }
}

/// Adds begin-frame and end-frame lifecycle hooks to an ECS object.
///
/// The **on** phase only, frame boundaries are not cancelable.
mixin IsBeginEndFrameable<T extends App<T>, E extends ECSBase<T>> on Self<E>, ECSBase<T> {

  List<void Function(E self, double dt)> _onBeginFrameFns = [];

  List<void Function(E self, double dt)> _onEndFrameFns = [];

  /// Registers [fn] to be called at the start of each frame.
  @nonVirtual
  E listenOnBeginFrame(void Function(E self, double dt) fn) {
    _onBeginFrameFns.add(fn);
    return self;
  }

  /// Registers [fn] to be called at the end of each frame.
  @nonVirtual
  E listenOnEndFrame(void Function(E self, double dt) fn) {
    _onEndFrameFns.add(fn);
    return self;
  }

  /// Notifies all begin-frame listeners and calls [onBeginFrame].
  void _doBeginFrame(double dt) {
    _onBeginFrameFns.forEach((f) => f(self, dt));
    onBeginFrame(dt);
  }

  /// Notifies all end-frame listeners and calls [onEndFrame].
  void _doEndFrame(double dt) {
    _onEndFrameFns.forEach((f) => f(self, dt));
    onEndFrame(dt);
  }

  /// Override to react at the start of each frame.
  ///
  /// Called after all registered [listenOnBeginFrame] listeners.
  void onBeginFrame(double dt) {}

  /// Override to react at the end of each frame.
  ///
  /// Called after all registered [listenOnEndFrame] listeners.
  void onEndFrame(double dt) {}
}

/// Adds cancelation lifecycle hooks to an ECS object, from the object's own perspective.
///
/// Cancelation is a one-way transition: once canceled, the object stays canceled.
/// The [cancel] method drives the full lifecycle: guards, listeners, and state change.
mixin IsCancelable<T extends App<T>, E extends ECSBase<T>> on ECSBase<T>, Self<E> {

  bool _isCanceled = false;

  /// Whether this object has been canceled.
  bool get isCanceled => _isCanceled;

  List<bool Function(E self)> _onBeforeCancelFns = [];

  List<void Function(E self)> _onCancelFns = [];

  List<void Function(E self)> _onAfterCancelFns = [];

  /// Registers [fn] as a before-cancel listener.
  ///
  /// [fn] returning `false` cancels the cancel.
  @nonVirtual
  E listenOnBeforeCancel(bool Function(E self) fn) {
    _onBeforeCancelFns.add(fn);
    return self;
  }

  /// Registers [fn] as a cancel listener.
  ///
  /// Called when the cancel operation is about to happen and was not canceled.
  @nonVirtual
  E listenOnCancel(void Function(E self) fn) {
    _onCancelFns.add(fn);
    return self;
  }

  /// Registers [fn] as an after-cancel listener.
  ///
  /// Called only if the cancel was not canceled.
  @nonVirtual
  E listenOnAfterCancel(void Function(E self) fn) {
    _onAfterCancelFns.add(fn);
    return self;
  }

  /// Runs all before-cancel listeners and [onBeforeCancel].
  ///
  /// Returns `false` if any listener or the override cancels the cancel.
  bool _doOnBeforeCancel() {
    if (!_onBeforeCancelFns.every((f) => f(self))) return false;
    return onBeforeCancel();
  }

  /// Runs all cancel listeners and [onCancel].
  void _doOnCancel() {
    _onCancelFns.forEach((f) => f(self));
    onCancel();
  }

  /// Runs all after-cancel listeners and [onAfterCancel].
  void _doOnAfterCancel() {
    _onAfterCancelFns.forEach((f) => f(self));
    onAfterCancel();
  }

  /// Override to cancel the cancel from within the class.
  ///
  /// Return `false` to abort. Called after all registered [listenOnBeforeCancel] listeners.
  bool onBeforeCancel() => true;

  /// Override to react when the cancel is about to complete.
  ///
  /// Called after all registered [listenOnCancel] listeners.
  void onCancel() {}

  /// Override to react after the cancel has completed.
  ///
  /// Called after all registered [listenOnAfterCancel] listeners.
  void onAfterCancel() {}

  /// Attempts to cancel this object.
  ///
  /// Returns `true` if cancelation succeeded, `false` if it was already
  /// canceled or any `before` hooks listeners vetoed it.
  bool cancel() {
    if (_isCanceled) return false;
    if (!_doOnBeforeCancel()) return false;
    _doOnCancel();
    _isCanceled = true;
    _doOnAfterCancel();
    return true;
  }
}

/// Adds cloning capabilities to an ECS object.
///
/// Cloning is opt-in, [clone] throws by default. To enable it, override
/// [createInstance] and either override [clone] or register a [whenClone]
/// callback. Before using, always check [isClonable] rather than assuming
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
mixin IsClonable<
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

  /// Check this before calling [clone]: `if (obj.isClonable) obj.clone();`
  bool get isClonable => true;

  /// Whether this object is an original (not a clone).
  bool get isOriginal => !isClone;

  final List<E> _clones = [];

  /// Returns all clones produced from this object.
  Iterable<E> getClones() => _clones;

  bool _isCloneAssigned = false;

  /// Registers [clone] as a copy of this object. No-op if already assigned.
  void _assignClone(E clone) {
    if (clone is! IsClonable<T, E, C>) return;
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

    if (newInstance is! IsClonable<T, E, C>) {
      throw StateError('Invalid newInstance returned, expected ${IsClonable<T, E, C>}!');
    }
    
    _assignClone(newInstance);

    _doCheckIsCloneFresh(newInstance);
    if (newInstance.isCloned) {
      return (_doWhenCloned(self, newInstance) ?? newInstance) as X;
    }

    final readyToClone = _doWhenClone(self, cloner) ?? createClone(newInstance, cloner);

    if (readyToClone is! IsClonable<T, E, C>) {
      throw StateError('Invalid readyToClone returned, expected ${IsClonable<T, E, C>}!');
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
    if (target is IsClonable<T, E, C>) {
      target.isClone = true;
      target.isCloning = true;
    }
    return true;
  }

  /// Finalizes the clone pipeline: clears [isCloning], sets [isCloned], and
  /// calls [onCloned] on the copy followed by after-hooks on the origin.
  void _doCloneAfter(E target, [C? cloner]) {
    if (target is IsClonable<T, E, C>) {
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

    if (self case IsClonable<T, E, C> from) {
      if (target case IsClonable<T, E, C> to) {
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

/// Adds collision lifecycle hooks to an ECS object, from the object's own perspective.
///
/// Complements [CCollider]
/// (which hooks from the *host* side) by giving the object being collided its own three-phase contract:
/// - **before** => cancelable; any listener or override returning `false` aborts the operation
/// - **on** => the operation is about to complete; called by the host after all before-checks pass
/// - **after** => the operation has completed; side-effects and cleanup go here
mixin IsCollidable<T extends App<T>, E extends ECSBase<T>, C extends ECSBase<T>> on ECSBase<T>, Self<E> {

  List<bool Function(E self, C other)> _onBeforeCollisionFns = [];

  List<void Function(E self, C other)> _onCollisionFns = [];

  List<void Function(E self, C other)> _onAfterCollisionFns = [];

  /// Registers [fn] as a before-collision listener.
  ///
  /// [fn] returning `false` cancels the collision.
  @nonVirtual
  E listenOnBeforeCollision(bool Function(E self, C other) fn) {
    _onBeforeCollisionFns.add(fn);
    return self;
  }

  /// Registers [fn] as a collision listener.
  ///
  /// Called when the collision operation is about to happen and was not canceled.
  @nonVirtual
  E listenOnCollision(void Function(E self, C other) fn) {
    _onCollisionFns.add(fn);
    return self;
  }

  /// Registers [fn] as an after-collision listener.
  ///
  /// Called only if the collision was not canceled.
  @nonVirtual
  E listenOnAfterCollision(void Function(E self, C other) fn) {
    _onAfterCollisionFns.add(fn);
    return self;
  }

  /// Runs all before-collision listeners and [onBeforeCollision].
  ///
  /// Returns `false` if any listener or the override cancels the collision.
  bool _doOnBeforeCollision(C other) {
    if (!_onBeforeCollisionFns.every((f) => f(self, other))) return false;
    return onBeforeCollision(other);
  }

  /// Runs all collision listeners and [onCollision].
  void _doOnCollision(C other) {
    _onCollisionFns.forEach((f) => f(self, other));
    onCollision(other);
  }

  /// Runs all after-collision listeners and [onAfterCollision].
  void _doOnAfterCollision(C other) {
    _onAfterCollisionFns.forEach((f) => f(self, other));
    onAfterCollision(other);
  }

  /// Override to cancel the collision from within the class.
  ///
  /// Return `false` to abort. Called after all registered [listenOnBeforeCollision] listeners.
  bool onBeforeCollision(C other) => true;

  /// Override to react when the collision is about to complete.
  ///
  /// Called after all registered [listenOnCollision] listeners.
  void onCollision(C other) {}

  /// Override to react after the collision has completed.
  ///
  /// Called after all registered [listenOnAfterCollision] listeners.
  void onAfterCollision(C other) {}
}

/// Adds a callback processing capabilities to an ECS object.
///
/// Callbacks are queued and executed in a controlled pipeline each frame.
mixin IsCallbackProcessable<T extends App<T>, E extends ECSBase<T>> on Self<E>, HasAppAccess<T>, IsEventEmittable<T, E> {
  List<void Function()> _callbackQueue = [];

  /// Schedules a [callback].
  @override
  void callback(void Function() callback) => _callbackQueue.add(callback);

  /// Drains and executes all pending callbacks, then clears the queue.
  bool _processCallbacks() {
    bool didSomething = false;
    while (_callbackQueue.isNotEmpty) {
      _callbackQueue.removeAt(0).call();
      didSomething = true;
    }
    return didSomething;
  }

  /// Clears callback queue.
  void clearCallbackQueue() => _callbackQueue.clear();
}

typedef IsAnyComponentManagable<T extends App<T>> = IsComponentManagable<T, ECSBase<T>>;

mixin IsComponentManagable<T extends App<T>, E extends ECSBase<T>> on
  HasEntityAccess<T>,
  IsEventEmittable<T, E>,
  IsDisposable<T, E>
{
  void _doOnComponentParentSet(Comp<T> component);

  // ░██     ░██   ░██████     ░██████   ░██     ░██   ░██████   
  // ░██     ░██  ░██   ░██   ░██   ░██  ░██    ░██   ░██   ░██  
  // ░██     ░██ ░██     ░██ ░██     ░██ ░██   ░██   ░██         
  // ░██████████ ░██     ░██ ░██     ░██ ░███████     ░████████  
  // ░██     ░██ ░██     ░██ ░██     ░██ ░██   ░██           ░██ 
  // ░██     ░██  ░██   ░██   ░██   ░██  ░██    ░██   ░██   ░██  
  // ░██     ░██   ░██████     ░██████   ░██     ░██   ░██████   

  List<bool Function(E self, Comp<T> component)> _onBeforeCompAddFns = [];

  List<void Function(E self, Comp<T> component)> _onCompAddFns = [];

  List<void Function(E self, Comp<T> component)> _onAfterCompAddFns = [];

  List<bool Function(E self, Comp<T> component)> _onBeforeCompRemoveFns = [];

  List<void Function(E self, Comp<T> component)> _onCompRemoveFns = [];

  List<void Function(E self, Comp<T> component)> _onAfterCompRemoveFns = [];

  List<bool Function(E self, Comp<T> component)> _onBeforeCompCloneFns = [];

  List<void Function(E self, Comp<T> component)> _onCompCloneFns = [];

  List<void Function(E self, Comp<T> component)> _onAfterCompCloneFns = [];

  @nonVirtual
  E listenOnBeforeCompAdd(bool Function(E self, Comp<T> component) fn) {
    _onBeforeCompAddFns.add(fn);
    return self;
  }

  @nonVirtual
  E listenOnCompAdd(void Function(E self, Comp<T> component) fn) {
    _onCompAddFns.add(fn);
    return self;
  }

  @nonVirtual
  E listenOnAfterCompAdd(void Function(E self, Comp<T> component) fn) {
    _onAfterCompAddFns.add(fn);
    return self;
  }

  @nonVirtual
  E listenOnBeforeCompRemove(bool Function(E self, Comp<T> component) fn) {
    _onBeforeCompRemoveFns.add(fn);
    return self;
  }

  @nonVirtual
  E listenOnCompRemove(void Function(E self, Comp<T> component) fn) {
    _onCompRemoveFns.add(fn);
    return self;
  }

  @nonVirtual
  E listenOnAfterCompRemove(void Function(E self, Comp<T> component) fn) {
    _onAfterCompRemoveFns.add(fn);
    return self;
  }

  @nonVirtual
  E listenOnBeforeCompClone(bool Function(E self, Comp<T> component) fn) {
    _onBeforeCompCloneFns.add(fn);
    return self;
  }

  @nonVirtual
  E listenOnCompClone(void Function(E self, Comp<T> component) fn) {
    _onCompCloneFns.add(fn);
    return self;
  }

  @nonVirtual
  E listenOnAfterCompClone(void Function(E self, Comp<T> component) fn) {
    _onAfterCompCloneFns.add(fn);
    return self;
  }

  bool _doOnBeforeCompAdd(Comp<T> component) {
    if (!_onBeforeCompAddFns.every((f) => f(self, component))) return false;
    return onBeforeCompAdd(component);
  }
  
  void _doOnCompAdd(Comp<T> component) {
    _onCompAddFns.forEach((f) => f(self, component));
    onCompAdd(component);
  }

  void _doOnAfterCompAdd(Comp<T> component) {
    _onAfterCompAddFns.forEach((f) => f(self, component));
    onAfterCompAdd(component);
  }

  bool _doOnBeforeCompRemove(Comp<T> component) {
    if (!_onBeforeCompRemoveFns.every((f) => f(self, component))) return false;
    return onBeforeCompRemove(component);
  }

  void _doOnCompRemove(Comp<T> component) {
    _onCompRemoveFns.forEach((f) => f(self, component));
    onCompRemove(component);
  }

  void _doOnAfterCompRemove(Comp<T> component) {
    _onAfterCompRemoveFns.forEach((f) => f(self, component));
    onAfterCompRemove(component);
  }

  bool _doOnBeforeCompClone(Comp<T> component) {
    if (!_onBeforeCompCloneFns.every((f) => f(self, component))) return false;
    return onBeforeCompClone(component);
  }

  void _doOnCompClone(Comp<T> component) {
    _onCompCloneFns.forEach((f) => f(self, component));
    onCompClone(component);
  }

  void _doOnAfterCompClone(Comp<T> component) {
    _onAfterCompCloneFns.forEach((f) => f(self, component));
    onAfterCompClone(component);
  }

  bool onBeforeCompAdd(Comp<T> component) => true;

  void onCompAdd(Comp<T> component) {}

  void onAfterCompAdd(Comp<T> component) {}

  bool onBeforeCompRemove(Comp<T> component) => true;

  void onCompRemove(Comp<T> component) {}

  void onAfterCompRemove(Comp<T> component) {}

  bool onBeforeCompClone(Comp<T> copy) => true;

  void onCompClone(Comp<T> copy) {}

  void onAfterCompClone(Comp<T> copy) {}

  // ░██████████ ░██    ░██ ░██████████ ░███    ░██ ░██████████  ░██████   
  // ░██         ░██    ░██ ░██         ░████   ░██     ░██     ░██   ░██  
  // ░██         ░██    ░██ ░██         ░██░██  ░██     ░██    ░██         
  // ░█████████  ░██    ░██ ░█████████  ░██ ░██ ░██     ░██     ░████████  
  // ░██          ░██  ░██  ░██         ░██  ░██░██     ░██            ░██ 
  // ░██           ░██░██   ░██         ░██   ░████     ░██     ░██   ░██  
  // ░██████████    ░███    ░██████████ ░██    ░███     ░██      ░██████   

  @override
  bool _doEventLocal(Event<T> event) {
    if (_doEventVisitedCheck(event)) return true;
    if (event.isStopped) return true;

    if (event.scope == .sceneOnly) return false;

    if (_doEventSelfCheck(event)) return true;
    if (event.isStopped) return true;

    if (event.scope == .local) {
      _doOnEvent(event);

      if (event.origin == self) {
        
        for (final c in _components) {
          if (event.isStopped) return true;
          c._propagate(event);
        }
        return true;
      }
    } else if (event.scope != .globalNoEntities) {
      _doOnEvent(event);
    }

    for (final c in _components) {
      if (event.isStopped) return true;
      c._propagate(event);
    }

    if (event.isStopped) return true;

    return event.origin != self;
  }

  // ░██████░███     ░███ ░█████████  ░██         
  //   ░██  ░████   ░████ ░██     ░██ ░██         
  //   ░██  ░██░██ ░██░██ ░██     ░██ ░██         
  //   ░██  ░██ ░████ ░██ ░█████████  ░██         
  //   ░██  ░██  ░██  ░██ ░██         ░██         
  //   ░██  ░██       ░██ ░██         ░██         
  // ░██████░██       ░██ ░██         ░██████████ 

  final List<Comp<T>> _components = [];

  /// Returns the top-level components attached directly to this entity/component
  /// (does not recurse into nested components).
  Iterable<Comp<T>> getComponents() => _components;

  // ──────────
  // ACTIVATION
  // ──────────

  /// Activates every top-level component of type [C].
  E enableComp<C extends Comp<T>>() {
    getAll<C>().forEach((c) => c.setActive(true));
    return self;
  }

  /// Activates all top-level components.
  E enableComps() {
    _components.forEach((c) => c.setActive(true));
    return self;
  }

  /// Recursively activates every component, including nested ones.
  E enableEverything() {
    _components.forEach((c) {
      c.setActive(true);
      c.enableEverything();
    });
    return self;
  }

  /// Deactivates every top-level component of type [C].
  E disableComp<C extends Comp<T>>() {
    getAll<C>().forEach((c) => c.setActive(false));
    return self;
  }

  /// Deactivates all top-level components (not nested).
  E disableComps() {
    _components.forEach((c) => c.setActive(false));
    return self;
  }

  /// Recursively deactivates every component, including nested ones.
  E disableEverything() {
    _components.forEach((c) {
      c.setActive(false);
      c.disableEverything();
    });
    return self;
  }

  // ────────
  // MUTATION
  // ────────

  /// Replaces the first top-level component of type [A] with [newC].
  /// No-op if no component of type [A] exists.
  E swapComp<A extends Comp<T>>(Comp<T> newC) {
    final old = get<A>();
    if (old == null) return self;
    _removeComponentInstance(old);
    addComp(newC);
    return self;
  }

  /// Removes all the top-level components of type [A] and adds [newC].
  /// No-op if no component of type [A] exists.
  E swapComps<A extends Comp<T>>(Comp<T> newC) {
    final oldComps = getAll<A>();
    if (oldComps.isEmpty) return self;
    oldComps.forEach(_removeComponentInstance);
    addComp(newC);
    return self;
  }

  /// Replaces the first top-level component whose `runtimeType == component.runtimeType` with [component].
  E replaceComp(Comp<T> component) {
    final old = _components.where((c) => c.runtimeType == component.runtimeType).firstOrNull;
    if (old != null) _removeComponentInstance(old);
    addComp(component);
    return self;
  }

  /// Adds [component] as a new top-level component.
  E addComp<C extends Comp<T>>(C component) {
    emit(EventCompAdding(app, entity, component));

    if (!_doOnBeforeCompAdd(component)) {
      emit(EventCompAddCancelled(app, entity, component));
      return self;
    }

    if (!component._doOnBeforeAdd(self)) {
      emit(EventCompAddCancelled(app, entity, component));
      return self;
    }

    component.parent = self;
    _doOnComponentParentSet(component);

    _doOnCompAdd(component);
    if (!component.isClone) component._doAdd(self);

    _components.add(component);

    component._doOnAfterAdd(self);
    _doOnAfterCompAdd(component);
    emit(EventCompAdded(app, entity, component));
    return self;
  }

  /// Adds [component] only if no top-level component of type [C] already exists.
  E addCompIfNotExists<C extends Comp<T>>(C component) {
    if (!has<C>()) addComp(component);
    return self;
  }

  /// Removes the first top-level component matching type [C].
  E removeComp<C extends Comp<T>>() {
    final c = get<C>();
    if (c != null) _removeComponentInstance(c);
    return self;
  }

  /// Removes the exact component.
  E removeCompExact(Comp<T> component) {
    if (!_components.any((c) => identical(c, component))) return self;
    _removeComponentInstance(component);
    return self;
  }

  /// Removes the first top-level component whose `runtimeType == type`.
  E removeCompByType(Type type) {
    final component = _components.where((c) => c.runtimeType == type).firstOrNull;
    if (component != null) _removeComponentInstance(component);
    return self;
  }

  /// Removes all top-level components matching type [C].
  E removeComps<C extends Comp<T>>() {
    getAll<C>().toList().forEach(_removeComponentInstance);
    return self;
  }

  /// Removes every top-level component.
  E removeEverything() {
    _components.toList().forEach(_removeComponentInstance);
    return self;
  }

  // the actual removal logic, now keyed by identity instead of type
  E _removeComponentInstance(Comp<T> component) {
    if (!_components.contains(component)) return self;

    emit(EventCompRemoving(app, entity, component));

    if (!_doOnBeforeCompRemove(component)) {
      emit(EventCompRemoveCancelled(app, entity, component));
      return self;
    }

    if (!component._doOnBeforeRemove()) {
      emit(EventCompRemoveCancelled(app, entity, component));
      return self;
    }

    _doOnCompRemove(component);

    component._doRemove();

    // remove nested components
    // NOTE: toList() is important
    component._components.toList().forEach(
      (c) => component._removeComponentInstance(c)
    );
    
    _components.remove(component);

    component._doOnAfterRemove();
    _doOnAfterCompRemove(component);
    emit(EventCompRemoved(app, entity, component));
    return self;
  }

  // ──────
  // LOOKUP
  // ──────

  /// Returns the first top-level component matching type [C], or `null`.
  C? get<C extends Comp<T>>() => _components.whereType<C>().firstOrNull;

  /// Returns all top-level components matching type [C].
  List<C> getAll<C extends Comp<T>>() => _components.whereType<C>().toList();
  
  /// Invokes [callback] with the first top-level component matching type [C],
  /// if one exists.
  E on<
    C extends Comp<T>
  >(void Function(C) callback) {
    final a = get<C>();
    if (a == null) return self;
    callback(a);
    return self;
  }
  
  /// Invokes [callback] with the first top-level components matching types
  /// [A] and [B], if both exist.
  E on2<
    A extends Comp<T>,
    B extends Comp<T>
  >(
    void Function(A, B) callback
  ) {
    final a = get<A>(), b = get<B>();
    if (a == null || b == null) return self;
    callback(a, b);
    return self;
  }
  
  /// Invokes [callback] with the first top-level components matching types
  /// [A], [B], and [C], if all three exist.
  E on3<
    A extends Comp<T>,
    B extends Comp<T>,
    C extends Comp<T>
  >(
    void Function(A, B, C) callback
  ) {
    final a = get<A>(), b = get<B>(), c = get<C>();
    if (a == null || b == null || c == null) return self;
    callback(a, b, c);
    return self;
  }
  
  /// Invokes [callback] with every top-level component matching type [C].
  E onAll<C extends Comp<T>>(void Function(List<C> components) callback) {
    final found = getAll<C>();
    if (found.isNotEmpty) callback(found);
    return self;
  }

  // ────────────────
  // EXISTENCE CHECKS
  // ────────────────

  /// Whether a top-level component of type [C] exists.
  bool has<C extends Comp<T>>() => _components.any((s) => s is C);
  
  /// Whether a top-level component whose `runtimeType == type` exists.
  bool hasByType(Type type) => _components.any((c) => c.runtimeType == type);

  /// Whether a top-level component of type [A] OR type [B] exists.
  bool hasAny<
    A extends Comp<T>,
    B extends Comp<T>
  >() => has<A>() || has<B>();

  /// Whether top-level components of BOTH type [A] and type [B] exist.
  bool has2<
    A extends Comp<T>,
    B extends Comp<T>
  >() => has<A>() && has<B>();

  /// Whether top-level components whose `runtimeType` matches both [a] and [b]
  /// exist.
  bool has2ByType(Type a, Type b) => hasByType(a) && hasByType(b);

  /// Whether top-level components of types [A], [B], and [C] all exist.
  bool has3<
    A extends Comp<T>,
    B extends Comp<T>,
    C extends Comp<T>
  >() => has<A>() && has<B>() && has<C>();

  /// Whether top-level components whose `runtimeType` matches [a], [b], and [c]
  /// all exist.
  bool has3ByType(Type a, Type b, Type c) => hasByType(a) && hasByType(b) && hasByType(c);

  // ───────
  // SPECIAL
  // ───────

  void mergeCompsInto<X extends IsAnyComponentManagable<T>>(X into, {
    Cloner<T>? cloner,
    bool replaceComponents = true,
  }) {
    _components.forEach((childComp) {
      if (!(cloner?.allowComp(into, childComp) ?? true)) return;

      _doCloneComp(
        to: into,
        what: childComp,
        cloner: cloner,
        replaceComponent: replaceComponents,
      );
    });
  }

  // ░███    ░██ ░██████████   ░██████   ░██████████░██████████ ░███████   
  // ░████   ░██ ░██          ░██   ░██      ░██    ░██         ░██   ░██  
  // ░██░██  ░██ ░██         ░██             ░██    ░██         ░██    ░██ 
  // ░██ ░██ ░██ ░█████████   ░████████      ░██    ░█████████  ░██    ░██ 
  // ░██  ░██░██ ░██                 ░██     ░██    ░██         ░██    ░██ 
  // ░██   ░████ ░██          ░██   ░██      ░██    ░██         ░██   ░██  
  // ░██    ░███ ░██████████   ░██████       ░██    ░██████████ ░███████   

  /// Recursively collects every component in this subtree, including nested ones.
  List<Comp<T>> getEverything() {
    final result = <Comp<T>>[];
    for (final comp in _components) {
      result.add(comp);
      result.addAll(comp.getEverything());
    }
    return result;
  }

  /// Recursively finds the first component of type [C] in this subtree.
  C? findComp<C extends Comp<T>>() {
    final topLevel = get<C>();
    if (topLevel != null) return topLevel;

    for (final comp in _components) {
      final subComp = comp.findComp<C>();
      if (subComp != null) return subComp;
    }

    return null;
  }

  /// Whether a component of type [C] exists anywhere in this subtree.
  bool containsComp<C extends Comp<T>>() => findComp<C>() != null;

  /// Recursively finds every component of type [C] in this subtree.
  Iterable<C> findAllComps<C extends Comp<T>>() {
    List<C> found = [];

    found.addAll(getAll<C>());

    for (final comp in _components) {
      found.addAll(comp.findAllComps<C>());
    }

    return found;
  }

  /// Recursively finds every component that itself *contains* a nested
  /// component of type [C] (i.e. returns the containing components, not
  /// the matches themselves).
  Iterable<Comp<T>> findAllCompsWith<C extends Comp<T>>() {
    List<Comp<T>> found = [];

    for (final comp in _components) {
      if (comp.containsComp<C>()) {
        found.add(comp);
      }

      found.addAll(comp.findAllCompsWith<C>());
    }
    
    return found;
  }

  /// Walks up the hierarchy and returns the nearest ancestor component of
  /// type [C], if any.
  C? findCompInParent<C extends Comp<T>>() {
    var current = parent;
    while (current != null && current is IsAnyComponentManagable<T>) {
      final comp = current.get<C>();
      if (comp != null) return comp;
      current = current.parent;
    }
    return null;
  }

  /// Returns sibling components at the same level as this one.
  Iterable<C> findCompSiblings<C extends Comp<T>>() {
    if (parent == null) return [];
    if (parent case IsAnyComponentManagable<T> parent) {
      return parent.getAll<C>().where((c) => c != self);
    }
    return [];
  }

  /// Finds the first direct child component of type [C] (non-recursive).
  C? findCompInChildren<C extends Comp<T>>() {
    for (final comp in _components) {
      final found = comp.get<C>();
      if (found != null) return found;
    }
    return null;
  }

  /// Finds the closest component of type [C] via breadth-first search.
  C? findCompNearest<C extends Comp<T>>() {
    // check self first
    final self = get<C>();
    if (self != null) return self;

    // check parent chain
    final inParent = findCompInParent<C>();
    if (inParent != null) return inParent;

    // check children
    return findComp<C>();
  }

  /// Recursively removes every component of type [C] from this subtree.
  void removeCompNested<C extends Comp<T>>() {
    removeComp<C>();
    for (final comp in _components) {
      comp.removeCompNested<C>();
    }
  }

  /// Recursively counts every component of type [C] in this subtree.
  int countAllComps<C extends Comp<T>>() {
    int count = getAll<C>().length;
    for (final comp in _components) {
      count += comp.countAllComps<C>();
    }
    return count;
  }

  /// Recursively invokes [callback] on every component of type [C] in this subtree.
  void forEachCompRecursive<C extends Comp<T>>(void Function(C) callback) {
    for (final comp in getAll<C>()) {
      callback(comp);
    }
    for (final comp in _components) {
      comp.forEachCompRecursive<C>(callback);
    }
  }

  /// Recursively finds the first component of type [C] satisfying [predicate].
  C? findCompWhere<C extends Comp<T>>(bool Function(C) predicate) {
    for (final comp in getAll<C>()) {
      if (predicate(comp)) return comp;
    }
    for (final comp in _components) {
      final found = comp.findCompWhere<C>(predicate);
      if (found != null) return found;
    }
    return null;
  }

  /// Returns every leaf component in this subtree (components with no children).
  Iterable<Comp<T>> getCompLeaves() {
    List<Comp<T>> leaves = [];
    for (final comp in _components) {
      if (comp._components.isEmpty) {
        leaves.add(comp);
      } else {
        leaves.addAll(comp.getCompLeaves());
      }
    }
    return leaves;
  }

  // ░██████░███     ░███ ░█████████  ░██         
  //   ░██  ░████   ░████ ░██     ░██ ░██         
  //   ░██  ░██░██ ░██░██ ░██     ░██ ░██         
  //   ░██  ░██ ░████ ░██ ░█████████  ░██         
  //   ░██  ░██  ░██  ░██ ░██         ░██         
  //   ░██  ░██       ░██ ░██         ░██         
  // ░██████░██       ░██ ░██         ░██████████ 

  @nonVirtual
  @pragma('vm:prefer-inline')
  void _doCloneComp({
    required IsAnyComponentManagable<T> to,
    required Comp<T> what,
    Cloner<T>? cloner,
    bool replaceComponent = false,
  }) {
    if (!what.isClonable) return;
    if (!_doOnBeforeCompClone(what)) return;
    
    _doOnCompClone(what);
    // This clone() call ALREADY does everything.
    // Returns the fully cloned component
    final fullyClonedComp = what.clone(cloner);
    
    if (replaceComponent) {
      to.replaceComp(fullyClonedComp);
    } else {
      to.addComp(fullyClonedComp);
    }
    
    // Post-clone hook for the parent
    _doOnAfterCompClone(what);
  }

  @override
  void _doOnDispose() {
    _components.forEach((s) => s._doOnDispose());
    super._doOnDispose();
  }
}

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

/// Adds a draw lifecycle hook to an ECS object.
///
/// The **on** phase only, drawing is not cancelable.
mixin IsDrawable<T extends App<T>, E extends ECSBase<T>> on Self<E>, ECSBase<T> {
  List<void Function(E self, double dt)> _onDrawFns = [];

  /// Registers [fn] to be called during the draw phase each frame.
  @nonVirtual
  E listenOnDraw(void Function(E self, double dt) fn) {
    _onDrawFns.add(fn);
    return self;
  }

  /// Propagates the draw phase through listeners and the [onDraw] hook.
  void _doDraw(double dt) {
    _onDrawFns.forEach((f) => f(self, dt));
    onDraw(dt);
  }

  /// Override to react during the draw phase each frame.
  ///
  /// Called after all registered [listenOnDraw] listeners.
  void onDraw(double dt) {}
}

/// Adds an enter lifecycle hook to an ECS object.
/// 
/// - **before** => cancelable; any listener or override returning `false` aborts the operation
/// - **on** => the operation is about to complete; called by the host after all before-checks pass
/// - **after** => the operation has completed; side-effects and cleanup go here
mixin IsEnterable<T extends App<T>, E extends ECSBase<T>> on Self<E> {

  List<bool Function(E self)> _onBeforeEnterFns = [];

  List<void Function(E self)> _onEnterFns = [];

  List<void Function(E self)> _onAfterEnterFns = [];

  /// Registers [fn] as a before-enter listener.
  ///
  /// [fn] returning `false` cancels the enter.
  @nonVirtual
  E listenOnBeforeEnter(bool Function(E self) fn) {
    _onBeforeEnterFns.add(fn);
    return self;
  }

  /// Registers [fn] to be called when this object is entered.
  /// 
  /// Called when the enter operation is about to happen and was not canceled.
  @nonVirtual
  E listenOnEnter(void Function(E self) fn) {
    _onEnterFns.add(fn);
    return self;
  }

  /// Registers [fn] as an after-enter listener.
  ///
  /// Called only if the enter was not canceled.
  @nonVirtual
  E listenOnAfterEnter(void Function(E self) fn) {
    _onAfterEnterFns.add(fn);
    return self;
  }

  /// Runs all before-enter listeners and [onBeforeEnter].
  ///
  /// Returns `false` if any listener or the override cancels the enter.
  bool _doOnBeforeEnter() {
    if (!_onBeforeEnterFns.every((f) => f(self))) return false;
    return onBeforeEnter();
  }

  /// Runs all enter listeners and [onEnter].
  void _doOnEnter() {
    _onEnterFns.forEach((f) => f(self));
    onEnter();
  }

  /// Runs all after-enter listeners and [onAfterEnter].
  void _doOnAfterEnter() {
    _onAfterEnterFns.forEach((f) => f(self));
    onAfterEnter();
  }

  /// Override to cancel an enter from within the class.
  ///
  /// Return `false` to abort. Called after all registered [listenOnBeforeEnter] listeners.
  bool onBeforeEnter() => true;

  /// Override to react when an enter is about to complete.
  ///
  /// Called by the host after all before-checks have passed.
  /// 
  /// Called after all registered [listenOnEnter] listeners.
  void onEnter() {}

  /// Override to react after an enter has completed.
  ///
  /// Called after all registered [listenOnAfterEnter] listeners.
  void onAfterEnter() {}
}

/// Adds entity add/remove lifecycle hooks to a [Scene] or [EntityGroup].
///
/// Covers two events: entity add and entity remove, each with a full three-phase contract:
/// - **before** => cancelable; any listener or override returning `false` aborts the operation
/// - **on** => the operation is about to complete; called by the host after all before-checks pass
/// - **after** => the operation has completed; side-effects and cleanup go here
///
/// Note: this mixin bypasses the standard [Self] pattern due to [Entity] baking
/// in `Self<Entity<T>>` unconditionally. See [self] for details.
mixin IsEntityManagable<T extends App<T>, E extends ECSBase<T>, I extends Entity<T>> on ECSBase<T> {
  // [Entity<T>] bakes in [Self<Entity<T>>] unconditionally, so its `self`
  // getter is always typed as [Entity<T>], not [E]. We can't override it with
  // a more specific type due to contravariance, so we bypass it entirely with
  // a direct cast. Safe as long as any concrete class mixing this in is [E].
  E get self => this as E;

  // [Entity<T>] bakes in [IsEventEmittable<T, Entity<T>>], which means `emit` is
  // already satisfied by the time the mixin linearizer reaches us. Re-declaring
  // it here as abstract forces the compiler to verify the method exists on the
  // concrete class without us having to inherit the specific host type.
  void emit(Event<T> event, {EventScope scope = .local});

  // [Entity<T>] bakes in [IsEventEmittable<T, Entity<T>>], which means `dispatch` is
  // already satisfied by the time the mixin linearizer reaches us. Re-declaring
  // it here as abstract forces the compiler to verify the method exists on the
  // concrete class without us having to inherit the specific host type.
  void dispatch(Event<T> event, {EventScope scope = .local});

  // ░██     ░██   ░██████     ░██████   ░██     ░██   ░██████   
  // ░██     ░██  ░██   ░██   ░██   ░██  ░██    ░██   ░██   ░██  
  // ░██     ░██ ░██     ░██ ░██     ░██ ░██   ░██   ░██         
  // ░██████████ ░██     ░██ ░██     ░██ ░███████     ░████████  
  // ░██     ░██ ░██     ░██ ░██     ░██ ░██   ░██           ░██ 
  // ░██     ░██  ░██   ░██   ░██   ░██  ░██    ░██   ░██   ░██  
  // ░██     ░██   ░██████     ░██████   ░██     ░██   ░██████   

  List<bool Function(E self, I entity)> _onBeforeEntityAddFns = [];

  List<void Function(E self, I entity)> _onEntityAddFns = [];

  List<void Function(E self, I entity)> _onAfterEntityAddFns = [];

  List<bool Function(E self, I entity)> _onBeforeEntityRemoveFns = [];

  List<void Function(E self, I entity)> _onEntityRemoveFns = [];

  List<void Function(E self, I entity)> _onAfterEntityRemoveFns = [];

  /// Registers [fn] as a before-add listener.
  ///
  /// [fn] returning `false` cancels the entity add.
  @nonVirtual
  E listenOnBeforeEntityAdd(bool Function(E self, I entity) fn) {
    _onBeforeEntityAddFns.add(fn);
    return self;
  }

  /// Registers [fn] as an add listener.
  ///
  /// Called when the add operation is about to happen and was not canceled.
  @nonVirtual
  E listenOnEntityAdd(void Function(E self, I entity) fn) {
    _onEntityAddFns.add(fn);
    return self;
  }

  /// Registers [fn] as an after-add listener.
  ///
  /// Called only if the entity add was not canceled.
  @nonVirtual
  E listenOnAfterEntityAdd(void Function(E self, I entity) fn) {
    _onAfterEntityAddFns.add(fn);
    return self;
  }

  /// Registers [fn] as a before-remove listener.
  ///
  /// [fn] returning `false` cancels the entity remove.
  @nonVirtual
  E listenOnBeforeEntityRemove(bool Function(E self, I entity) fn) {
    _onBeforeEntityRemoveFns.add(fn);
    return self;
  }

  /// Registers [fn] as a remove listener.
  ///
  /// Called when the remove operation is about to happen and was not canceled.
  @nonVirtual
  E listenOnEntityRemove(void Function(E self, I entity) fn) {
    _onEntityRemoveFns.add(fn);
    return self;
  }

  /// Registers [fn] as an after-remove listener.
  ///
  /// Called only if the entity remove was not canceled.
  @nonVirtual
  E listenOnAfterEntityRemove(void Function(E self, I entity) fn) {
    _onAfterEntityRemoveFns.add(fn);
    return self;
  }

  /// Runs all before-add listeners and [onBeforeEntityAdd].
  ///
  /// Returns `false` if any listener or the override cancels the add.
  bool _doOnBeforeEntityAdd(I entity) {
    if (!_onBeforeEntityAddFns.every((f) => f(self, entity))) return false;
    return onBeforeEntityAdd(entity);
  }

  /// Runs all add listeners and [onEntityAdd].
  void _doOnEntityAdd(I entity) {
    _onEntityAddFns.forEach((f) => f(self, entity));
    onEntityAdd(entity);
  }

  /// Runs all after-add listeners and [onAfterEntityAdd].
  void _doOnAfterEntityAdd(I entity) {
    _onAfterEntityAddFns.forEach((f) => f(self, entity));
    onAfterEntityAdd(entity);
  }

  /// Runs all before-remove listeners and [onBeforeEntityRemove].
  ///
  /// Returns `false` if any listener or the override cancels the remove.
  bool _doOnBeforeEntityRemove(I entity) {
    if (!_onBeforeEntityRemoveFns.every((f) => f(self, entity))) return false;
    return onBeforeEntityRemove(entity);
  }

  /// Runs all remove listeners and [onEntityRemove].
  void _doOnEntityRemove(I entity) {
    _onEntityRemoveFns.forEach((f) => f(self, entity));
    onEntityRemove(entity);
  }

  /// Runs all after-remove listeners and [onAfterEntityRemove].
  void _doOnAfterEntityRemove(I entity) {
    _onAfterEntityRemoveFns.forEach((f) => f(self, entity));
    onAfterEntityRemove(entity);
  }

  /// Override to cancel an entity add from within the class.
  ///
  /// Return `false` to abort. Called after all registered [listenOnBeforeEntityAdd] listeners.
  bool onBeforeEntityAdd(I entity) => true;

  /// Override to react when an entity add is about to complete.
  ///
  /// Called by the host after all before-checks have passed.
  void onEntityAdd(I entity) {}

  /// Override to react after an entity add has completed.
  ///
  /// Called after all registered [listenOnAfterEntityAdd] listeners.
  void onAfterEntityAdd(I entity) {}

  /// Override to cancel an entity remove from within the class.
  ///
  /// Return `false` to abort. Called after all registered [listenOnBeforeEntityRemove] listeners.
  bool onBeforeEntityRemove(I entity) => true;

  /// Override to react when an entity remove is about to complete.
  ///
  /// Called by the host after all before-checks have passed.
  void onEntityRemove(I entity) {}

  /// Override to react after an entity remove has completed.
  ///
  /// Called after all registered [listenOnAfterEntityRemove] listeners.
  void onAfterEntityRemove(I entity) {}

  // ░██████░███     ░███ ░█████████  ░██         
  //   ░██  ░████   ░████ ░██     ░██ ░██         
  //   ░██  ░██░██ ░██░██ ░██     ░██ ░██         
  //   ░██  ░██ ░████ ░██ ░█████████  ░██         
  //   ░██  ░██  ░██  ░██ ░██         ░██         
  //   ░██  ░██       ░██ ░██         ░██         
  // ░██████░██       ░██ ░██         ░██████████ 

  final Set<I> _entities = {};

  /// Returns all entities currently registered.
  Set<I> getEntities() => _entities;

  /// Registers [entity] and runs the full add lifecycle.
  ///
  /// Emits [EventEntityAdding] first. If any [onBeforeEntityAdd] hook or the
  /// entity's own [Entity.onBeforeAdd] returns `false`, the add is cancelled and
  /// [EventEntityAddCancelled] is emitted. On success, emits
  /// [EventEntityAdded]. Already-registered entities are silently ignored.
  @mustCallSuper
  bool addEntity(I entity) {
    if (entity.isAdded) return false;

    emit(EventEntityAdding(app, this, entity));

    if (!_doOnBeforeEntityAdd(entity)) {
      emit(EventEntityAddCancelled(app, this, entity));
      return false;
    }

    if (!entity._doOnBeforeAdd(self)) {
      emit(EventEntityAddCancelled(app, this, entity));
      return false;
    }

    _doOnEntityAdd(entity);
    if (!entity.isClone) entity._doAdd(self);
    _entities.add(entity);

    entity._doOnAfterAdd(self);
    _doOnAfterEntityAdd(entity);

    emit(EventEntityAdded(app, this, entity));
    return true;
  }

  /// Unregisters [entity] and runs the full remove lifecycle.
  ///
  /// Emits [EventEntityRemoving] first. Either hook returning `false` cancels
  /// the removal and emits [EventEntityRemoveCancelled]. On success, all
  /// components are removed before the entity is detached, and
  /// [EventEntityRemoved] is emitted. Unregistered entities are ignored.
  bool removeEntity(I entity) {
    if (!entity.isAdded) return false;

    emit(EventEntityRemoving(app, this, entity));

    if (!_doOnBeforeEntityRemove(entity)) {
      emit(EventEntityRemoveCancelled(app, this, entity));
      return false;
    }

    if (!entity._doOnBeforeRemove()) {
      emit(EventEntityRemoveCancelled(app, this, entity));
      return false;
    }

    _doOnEntityRemove(entity);

    entity._doRemove();

    // remove entity components
    // NOTE: toList() is important
    entity._components.toList().forEach(
      (c) => entity._removeComponentInstance(c)
    );

    _entities.remove(entity);

    entity._doOnAfterRemove();
    _doOnAfterEntityRemove(entity);
    emit(EventEntityRemoved(app, this, entity));
    return true;
  }

  /// Calls `_doUpdate` on every entity in the scene.
  void _updateEntities(double dt)
    => _entities.forEach((e) => e._doUpdate(dt));

  /// Calls `_doDraw` on entities whose scene-level draw is enabled and whose
  /// render layer matches the renderer's currently active layer.
  void _drawEntities(double dt) {
    for (final e in _entities) {
      if (!e._drawEnabled) continue;
      if (!e._sceneLevelDrawEnabled) continue;
      final renderLayer = e.get<CRenderLayer<T>>();
      final entityLayer = renderLayer?.layer ?? RenderLayers.world.name;
      if (!renderer.inLayer(entityLayer)) continue;
      e._doDraw(dt);
    }
  }
}

typedef IsAnyEventEmittable<T extends App<T>> = IsEventEmittable<T, ECSBase<T>>;

/// Adds event emitting and handling capabilities to an ECS object.
///
/// Provides two emission modes:
/// - [emit] => queued; added to the root's (App) event queue and processed in order
/// - [dispatch] => immediate; bypasses the queue and fires synchronously
///
/// Incoming events are propagated via [_doOnEvent], which notifies all registered
/// listeners before invoking the [onEvent] override. Any listener or the event
/// itself may stop propagation early via [Event.stopPropagation].
mixin IsEventEmittable<T extends App<T>, E extends ECSBase<T>> on Self<E>, ECSBase<T> {

  // ░██     ░██   ░██████     ░██████   ░██     ░██   ░██████   
  // ░██     ░██  ░██   ░██   ░██   ░██  ░██    ░██   ░██   ░██  
  // ░██     ░██ ░██     ░██ ░██     ░██ ░██   ░██   ░██         
  // ░██████████ ░██     ░██ ░██     ░██ ░███████     ░████████  
  // ░██     ░██ ░██     ░██ ░██     ░██ ░██   ░██           ░██ 
  // ░██     ░██  ░██   ░██   ░██   ░██  ░██    ░██   ░██   ░██  
  // ░██     ░██   ░██████     ░██████   ░██     ░██   ░██████   

  List<bool Function(E self, Event<T> event)> _onBeforeEventFns = [];

  List<void Function(E self, Event<T> event)> _onEventFns = [];

  /// Registers [fn] as a before-event listener.
  ///
  /// [fn] returning `false` cancels the event handling.
  @nonVirtual
  E listenOnBeforeEvent(bool Function(E self, Event<T> event) fn) {
    _onBeforeEventFns.add(fn);
    return self;
  }

  /// Registers [fn] to be called for every incoming event.
  ///
  /// Listeners are called in registration order and may stop propagation
  /// via [Event.isStopped], preventing subsequent listeners and [onEvent]
  /// from being reached.
  @nonVirtual
  E listenOnEvent(void Function(E self, Event<T> event) fn) {
    _onEventFns.add(fn);
    return self;
  }

  /// Runs all before-event listeners and [onBeforeEvent].
  ///
  /// Returns `false` if any listener or the override cancels the event handling.
  bool _doOnBeforeEvent(Event<T> event) {
    if (!_onBeforeEventFns.every((f) => f(self, event))) return false;
    return onBeforeEvent(event);
  }

  /// Propagates [event] through listeners and the [onEvent] hook.
  ///
  /// No-op if the event is already stopped. Sets [Event.parent] to `self`
  /// if not already assigned.
  void _doOnEvent(Event<T> event) {
    event.origin ??= self;

    if (event.isStopped) return;

    if (!_doOnBeforeEvent(event)) return;

    for (final f in _onEventFns) {
      if (event.isStopped) return;
      f(self, event);
    }
    
    if (event.isStopped) return;
    onEvent(event);
  }

  /// Override to cancel an event handling from within the class.
  ///
  /// Return `false` to abort. Called after all registered [listenOnBeforeEvent] listeners.
  bool onBeforeEvent(Event<T> event) => true;

  /// Override to handle incoming events within the class.
  ///
  /// Called after all registered [listenOnEvent] listeners, and only if
  /// propagation has not been stopped.
  void onEvent(Event<T> event) {}

  // ░██████░███     ░███ ░█████████  ░██         
  //   ░██  ░████   ░████ ░██     ░██ ░██         
  //   ░██  ░██░██ ░██░██ ░██     ░██ ░██         
  //   ░██  ░██ ░████ ░██ ░█████████  ░██         
  //   ░██  ░██  ░██  ░██ ░██         ░██         
  //   ░██  ░██       ░██ ░██         ░██         
  // ░██████░██       ░██ ░██         ░██████████ 

  /// Queues an [event] into the central application event queue for asynchronous processing.
  ///
  /// Stitches the [Event.origin] to `this` if it wasn't already set.
  void emit(Event<T> event, {EventScope scope = .local}) {
    event._reset();
    event.origin ??= self;
    event.scope ??= scope;
    event._wasEmitted = true;
    event._emitOrDispatchScope = event.scope!;
    _enqueueEvent(event);
  }

  /// Dispatches an [event] immediately and synchronously, bypassing the central event queue.
  ///
  /// Stitches the [Event.origin] to `this` if it wasn't already set.
  void dispatch(Event<T> event, {EventScope scope = .local}) {
    event._reset();
    event.origin ??= self;
    event.scope ??= scope;
    event._wasDispatched = true;
    event._emitOrDispatchScope = event.scope!;
    _propagate(event);
  }

  void _propagate(Event<T> event) {
    assert(event.scope != null);

    // First hop of a .local/.self event that didn't start here: jump
    // straight to the true origin instead of walking down from `self`.
    // Gated on `_visited.isEmpty` so this only fires once, later hops
    // (origin walking back down its own subtree) must not re-redirect,
    // or they'd bounce back to origin and get eaten by the visited-check.
    if (
      event._visited.isEmpty &&
      (event.scope == .local || event.scope == .self) &&
      event.origin != self
    ) {
      if (event.origin case IsAnyEventEmittable<T> origin) {
        origin._propagate(event);
        return;
      }
    }

    if (_doEventLocal(event)) return; // intercepted or bound locally
    _dispatchEvent(event);
  }

  /// Evaluates and processes the [event] at this specific layer's scope.
  ///
  /// Returns `true` if the event was fully handled, intercepted, or restricted by its 
  /// scope rules (e.g., [EventScope.self] or [EventScope.local]), signaling that propagation should stop.
  /// Returns `false` if the event is free to continue to the queue or a broader cascade.
  bool _doEventLocal(Event<T> event);

  // already processed by `self`
  bool _doEventVisitedCheck(Event<T> event) => !event._visited.add(self);

  bool _doEventSelfCheck(Event<T> event) {
    if (event.scope == .self) {
      if (event.origin == self) {
        _doOnEvent(event);
  
        return true; // 'self'
      }
    }

    return false;
  }

  /// Forwards the event to the top-level application engine queue.
  void _enqueueEvent(Event<T> event) => app._enqueueEvent(event);

  /// Forwards the event directly to the top-level application router for synchronous cascading.
  void _dispatchEvent(Event<T> event) => app._propagate(event);
}

typedef IsAnyEventHistoryHolder<T extends App<T>> = IsEventHistoryHolder<T, ECSBase<T>>;

/// Records dispatched events for time-windowed queries and replay.
/// Mixed in alongside IsEventQueueHolder on root App.
mixin IsEventHistoryHolder<T extends App<T>, E extends ECSBase<T>> on IsEventEmittable<T, E> {

  // ░██     ░██   ░██████     ░██████   ░██     ░██   ░██████   
  // ░██     ░██  ░██   ░██   ░██   ░██  ░██    ░██   ░██   ░██  
  // ░██     ░██ ░██     ░██ ░██     ░██ ░██   ░██   ░██         
  // ░██████████ ░██     ░██ ░██     ░██ ░███████     ░████████  
  // ░██     ░██ ░██     ░██ ░██     ░██ ░██   ░██           ░██ 
  // ░██     ░██  ░██   ░██   ░██   ░██  ░██    ░██   ░██   ░██  
  // ░██     ░██   ░██████     ░██████   ░██     ░██   ░██████   

  List<bool Function(E self, Event<T> event)> _onBeforeEventRecordedFns = [];

  List<void Function(E self, Event<T> event)> _onEventRecordedFns = [];

  /// Registers [fn] as a before-event-record listener.
  ///
  /// [fn] returning `false` cancels the event recording.
  @nonVirtual
  E listenOnBeforeEventRecorded(bool Function(E self, Event<T> event) fn) {
    _onBeforeEventRecordedFns.add(fn);
    return self;
  }

  /// Registers [fn] to be called for every event recorded.
  ///
  /// Listeners are called in registration order.
  @nonVirtual
  E listenOnEventRecorded(void Function(E self, Event<T> event) fn) {
    _onEventRecordedFns.add(fn);
    return self;
  }

  /// Runs all before-event-record listeners and [onBeforeEventRecorded].
  ///
  /// Returns `false` if any listener or the override cancels the event recording.
  bool _doOnBeforeEventRecorded(Event<T> event) {
    if (!_onBeforeEventRecordedFns.every((f) => f(self, event))) return false;
    return onBeforeEventRecorded(event);
  }

  /// Propagates [event] through listeners and the [onEventRecorded] hook.
  void _doOnEventRecorded(Event<T> event) {
    _onEventRecordedFns.forEach((f) => f(self, event));
    onEventRecorded(event);
  }

  /// Override to cancel an event handling from within the class.
  ///
  /// Return `false` to abort. Called after all registered [listenOnBeforeEventRecorded] listeners.
  bool onBeforeEventRecorded(Event<T> event) => true;

  /// Override to handle incoming events within the class.
  ///
  /// Called after all registered [listenOnEventRecorded] listeners, and only if
  /// propagation has not been stopped.
  void onEventRecorded(Event<T> event) {}

  // ░██████░███     ░███ ░█████████  ░██         
  //   ░██  ░████   ░████ ░██     ░██ ░██         
  //   ░██  ░██░██ ░██░██ ░██     ░██ ░██         
  //   ░██  ░██ ░████ ░██ ░█████████  ░██         
  //   ░██  ░██  ░██  ░██ ░██         ░██         
  //   ░██  ░██       ░██ ░██         ░██         
  // ░██████░██       ░██ ░██         ░██████████ 

  List<Event<T>> _eventHistory = [];

  List<Event<T>> get eventHistory => _eventHistory;

  /// How long (in sim-scaled seconds) to retain events before pruning.
  /// Null = keep forever.
  double? get eventHistoryRetention => 10.0;

  IsAnyEventHistoryHolder<T> get _eventHolderRoot => app;

  @override
  void _doOnEvent(Event<T> event) {
    _tryToRecordEvent(event);
    super._doOnEvent(event);
  }

  void _recordEvent(Event<T> event) {
    if (!_doOnBeforeEventRecorded(event)) return;
    _eventHistory.add(event..simTime = app.time.timeScaled);
    _pruneEventHistory();
    _doOnEventRecorded(event);
  }

  void _tryToRecordEvent(Event<T> event) {
    if (identical(self, _eventHolderRoot)) { // i am root
      if (event._rootRecorded) return;
      event._rootRecorded = true;
      _recordEvent(event);
      return;
    }

    if (!identical(self, event.origin)) return;
    
    // i am origin
    if (event._originRecorded) return;
    event._originRecorded = true;

    // record to ourselves (origin)
    _recordEvent(event);
    // try to record to root
    // due to event's scope, it will probably never reach the root
    // so that's why we do it here explicitly
    _eventHolderRoot._tryToRecordEvent(event);
  }

  void _pruneEventHistory() {
    final retention = eventHistoryRetention;
    if (retention == null) return;
    final cutoff = app.time.timeScaled - retention;
    _eventHistory.removeWhere((e) => e.simTime < cutoff);
  }

  /// Clears history of recorded events.
  void clearEventHistory() => _eventHistory.clear();

  /// Events dispatched within the last [duration] sim-scaled seconds,
  /// optionally filtered to a specific origin.
  List<Event<T>> getRecordedEvents({
    double? duration,
    ECSBase<T>? origin,
    bool Function(Event<T> event)? filter,
  }) {
    var events = _eventHistory.where((e) => origin == null || e.origin == origin);

    if (duration != null) {
      final cutoff = app.time.timeScaled - duration;
      events = events.where((e) => e.simTime >= cutoff);
    }

    if (filter != null) {
      events = events.where(filter);
    }

    return events.toList();
  }

  /// Re-dispatches events from [fromTime] sim-scaled seconds ago to now.
  void replayRecordedEvents({
    double? fromTime,
    ECSBase<T>? origin,
    bool Function(Event<T> event)? filter,
  }) {
    final events = getRecordedEvents(
      duration: fromTime != null ? -fromTime : null,
      origin: origin,
      filter: filter,
    );

    for (final e in events) {
      assert(!(e._wasEmitted && e._wasDispatched), "Event was emitted and dispatched, this should not happen.");

      final eventOrigin = e.origin;
      e.scope = e._emitOrDispatchScope;

      if (e._wasEmitted) {

        if (eventOrigin case IsAnyEventEmittable<T> emittable) {
          emittable.emit(e);
          continue;
        }

        if (e.scope != .self && e.scope != .local) {
          // Scene-or-broader scope with a non-emittable origin: Root is the
          // correct re-entry point, propagation still happens normally from here.
          _eventHolderRoot.emit(e);
          continue;
        }

        // .self/.local scope with a non-emittable origin: there is no valid
        // replay target. The original emitter could propagate from itself
        // because it WAS the emittable origin; without that, Root can't safely
        // stand in, since Root emitting with .self/.local scope means the event
        // goes no further than Root, which is not what the original emit meant.
        throw StateError(
          'Cannot replay event ${e.runtimeType} (scope: ${e.scope}): origin '
          '$eventOrigin does not implement IsAnyEventEmittable, and scope '
          '${e.scope} cannot be safely re-emitted from Root ($_eventHolderRoot).',
        );
      
      } else if (e._wasDispatched) {

        if (eventOrigin case IsAnyEventEmittable<T> emittable) {
          emittable.dispatch(e);
          continue;
        }

        if (e.scope != .self && e.scope != .local) {
          // Scene-or-broader scope with a non-emittable origin: Root is the
          // correct re-entry point, propagation still happens normally from here.
          _eventHolderRoot.dispatch(e);
          continue;
        }

        // .self/.local scope with a non-emittable origin: there is no valid
        // replay target. The original emitter could propagate from itself
        // because it WAS the emittable origin; without that, Root can't safely
        // stand in, since Root dispatching with .self/.local scope means the event
        // goes no further than Root, which is not what the original dispatch meant.
        throw StateError(
          'Cannot replay event ${e.runtimeType} (scope: ${e.scope}): origin '
          '$eventOrigin does not implement IsAnyEventEmittable, and scope '
          '${e.scope} cannot be safely re-dispatched from Root ($_eventHolderRoot).',
        );
      
      } else {
        throw StateError('Unhandled event state. Nor emitted or dispatched!');
      }
    }
  }
}

typedef IsAnyEventQueueHolder<T extends App<T>> = IsEventQueueHolder<T, ECSBase<T>>;

mixin IsEventQueueHolder<T extends App<T>, E extends ECSBase<T>> on IsEventEmittable<T, E> {
  /// Pending events sorted by priority, drained at the start of each update.
  List<Event<T>> _eventQueue = [];

  @override
  void _enqueueEvent(Event<T> event) {
    assert(event.origin != null);
    _eventQueue.add(event);
    _eventQueue = _eventQueue.sortedBy((e) => e.priority);
  }

  /// Drains event queue in priority order, dispatching each event.
  bool _processEvents() {
    bool didSomething = false;
    while (_eventQueue.isNotEmpty) {
      _propagate(_eventQueue.removeAt(0));
      didSomething = true;
    }
    return didSomething;
  }

  /// Clears event queue.
  void clearEventQueue() => _eventQueue.clear();

  /// Synchronously drains the pending event queue.
  ///
  /// Intended for tests that need deterministic control over when queued
  /// events are processed, decoupled from [Scene._doDrainLoop]'s callback
  /// interleaving. Not meant for production code.
  @visibleForTesting
  bool processQueuedEventsForTest() => _processEvents();
}

/// Adds an input handling hook to an ECS object.
///
/// The **on** phase only, input handling is not cancelable.
///
/// Note: this mixin does not read or process input itself; it merely provides
/// a conventional hook point where input handling *should* occur. Actual input
/// polling is left entirely to the override or registered listeners.
mixin IsInputHandleable<T> on Self<T> {
  List<void Function(T self)> _onHandleInputFns = [];

  /// Registers [fn] to be called during the input handling phase.
  @nonVirtual
  T listenHandleInput(void Function(T self) fn) {
    _onHandleInputFns.add(fn);
    return self;
  }

  /// Propagates the input phase through listeners and the [onInput] hook.
  void _doHandleInput() {
    _onHandleInputFns.forEach((f) => f(self));
    onInput();
  }

  /// Override to handle input within the class.
  ///
  /// Called after all registered [listenHandleInput] listeners.
  /// 
  /// This method does not read or process input itself; it merely provides
  /// a conventional hook point where input handling *should* occur.
  void onInput() {}
}

/// Adds a leave lifecycle hook to an ECS object.
///
/// - **before** => cancelable; any listener or override returning `false` aborts the operation
/// - **on** => the operation is about to complete; called by the host after all before-checks pass
/// - **after** => the operation has completed; side-effects and cleanup go here
mixin IsLeavable<T extends App<T>, E extends ECSBase<T>> on Self<E> {

  List<bool Function(E self)> _onBeforeLeaveFns = [];

  List<void Function(E self)> _onLeaveFns = [];

  List<void Function(E self)> _onAfterLeaveFns = [];

  /// Registers [fn] as a before-leave listener.
  ///
  /// [fn] returning `false` cancels the enter.
  @nonVirtual
  E listenOnBeforeLeave(bool Function(E self) fn) {
    _onBeforeLeaveFns.add(fn);
    return self;
  }

  /// Registers [fn] to be called when this object is left.
  /// 
  /// Called when the leave operation is about to happen and was not canceled.
  @nonVirtual
  E listenOnLeave(void Function(E self) fn) {
    _onLeaveFns.add(fn);
    return self;
  }

  /// Registers [fn] as an after-leave listener.
  ///
  /// Called only if the leave was not canceled.
  @nonVirtual
  E listenOnAfterLeave(void Function(E self) fn) {
    _onAfterLeaveFns.add(fn);
    return self;
  }

  /// Runs all before-leave listeners and [onBeforeLeave].
  ///
  /// Returns `false` if any listener or the override cancels the leave.
  bool _doOnBeforeLeave() {
    if (!_onBeforeLeaveFns.every((f) => f(self))) return false;
    return onBeforeLeave();
  }

  /// Runs all leave listeners and [onLeave].
  void _doOnLeave() {
    _onLeaveFns.forEach((f) => f(self));
    onLeave();
  }

  /// Runs all after-leave listeners and [onAfterLeave].
  void _doOnAfterLeave() {
    _onAfterLeaveFns.forEach((f) => f(self));
    onAfterLeave();
  }

  /// Override to cancel an leave from within the class.
  ///
  /// Return `false` to abort. Called after all registered [listenOnBeforeLeave] listeners.
  bool onBeforeLeave() => true;

  /// Override to react when an leave is about to complete.
  ///
  /// Called by the host after all before-checks have passed.
  /// 
  /// Called after all registered [listenOnLeave] listeners.
  void onLeave() {}

  /// Override to react after an leave has completed.
  ///
  /// Called after all registered [listenOnAfterLeave] listeners.
  void onAfterLeave() {}
}

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

/// Adds pre-update and post-update lifecycle hooks to an ECS object.
///
/// The **on** phase only, update boundaries are not cancelable.
mixin IsPrePostUpdatable<T extends App<T>, E extends ECSBase<T>> on Self<E>, ECSBase<T> {
  List<void Function(E self, double dt)> _onPreUpdateFns = [];

  List<void Function(E self, double dt)> _onPostUpdateFns = [];

  /// Registers [fn] to be called before the update phase each frame.
  @nonVirtual
  E listenOnPreUpdate(void Function(E self, double dt) fn) {
    _onPreUpdateFns.add(fn);
    return self;
  }

  /// Registers [fn] to be called after the update phase each frame.
  @nonVirtual
  E listenOnPostUpdate(void Function(E self, double dt) fn) {
    _onPostUpdateFns.add(fn);
    return self;
  }

  /// Notifies all pre-update listeners and calls [onPreUpdate].
  void _doPreUpdate(double dt) {
    _onPreUpdateFns.forEach((f) => f(self, dt));
    onPreUpdate(dt);
  }

  /// Notifies all post-update listeners and calls [onPostUpdate].
  void _doPostUpdate(double dt) {
    _onPostUpdateFns.forEach((f) => f(self, dt));
    onPostUpdate(dt);
  }

  /// Override to react before the update phase each frame.
  ///
  /// Called after all registered [listenOnPreUpdate] listeners.
  void onPreUpdate(double dt) {}

  /// Override to react after the update phase each frame.
  ///
  /// Called after all registered [listenOnPostUpdate] listeners.
  void onPostUpdate(double dt) {}
}

/// Adds removal lifecycle hooks to an ECS object.
///
/// Provides a three-phase removal contract:
/// - **before** => cancelable; any listener or override returning `false` aborts removal
/// - **on** => the operation is about to complete; listeners are notified before the act completes
/// - **after** => the operation has completed; side-effects and cleanup go here
mixin IsRemovable<T extends App<T>, E extends ECSBase<T>> on Self<E> {

  /// Whether this object has been removed.
  bool isRemoved = false;

  List<bool Function(E self)> _onBeforeRemoveFns = [];

  List<void Function(E self)> _onRemoveFns = [];

  List<void Function(E self)> _onAfterRemoveFns = [];

  /// Registers [fn] as a before-remove listener.
  ///
  /// [fn] returning `false` cancels the removal.
  @nonVirtual
  E listenOnBeforeRemove(bool Function(E self) fn) {
    _onBeforeRemoveFns.add(fn);
    return self;
  }

  /// Registers [fn] as a remove listener.
  ///
  /// Called when the remove operation is about to happen and was not canceled.
  @nonVirtual
  E listenOnRemove(void Function(E self) fn) {
    _onRemoveFns.add(fn);
    return self;
  }

  /// Registers [fn] as an after-remove listener.
  ///
  /// Called only if removal was not canceled.
  @nonVirtual
  E listenOnAfterRemove(void Function(E self) fn) {
    _onAfterRemoveFns.add(fn);
    return self;
  }

  /// Runs all before-remove listeners and [onBeforeRemove].
  ///
  /// Returns `false` if any listener or the override cancels removal.
  bool _doOnBeforeRemove() {
    if (!_onBeforeRemoveFns.every((f) => f(self))) return false;
    return onBeforeRemove();
  }

  /// Runs all remove listeners and [onRemove].
  void _doOnRemove() {
    _onRemoveFns.forEach((f) => f(self));
    onRemove();
  }

  /// Runs all after-remove listeners and [onAfterRemove].
  void _doOnAfterRemove() {
    _onAfterRemoveFns.forEach((f) => f(self));
    onAfterRemove();
  }

  /// Notifies listeners and calls [onRemove] immediately before removal completes.
  ///
  /// Sets [isRemoved] and is a no-op if already removed.
  void _doRemove() {
    if (isRemoved) return;
    isRemoved = true;
    _doOnRemove();
  }

  /// Override to cancel removal from within the class.
  ///
  /// Return `false` to abort. Called after all registered [listenOnBeforeRemove] listeners.
  bool onBeforeRemove() => true;

  /// Override to react after removal has completed.
  ///
  /// Called after all registered [listenOnAfterRemove] listeners.
  void onAfterRemove() {}

  /// Override to react when removal is about to complete.
  ///
  /// Called after all registered [listenOnRemove] listeners.
  void onRemove() {}
}

/// Adds scene add/remove lifecycle hooks to an ECS object.
///
/// Covers two events: scene add and scene remove, each with a full three-phase contract:
/// - **before** => cancelable; any listener or override returning `false` aborts the operation
/// - **on** => the operation is about to complete; called by the host after all before-checks pass
/// - **after** => the operation has completed; side-effects and cleanup go here
mixin IsSceneManagable<T extends App<T>, E extends ECSBase<T>> on Self<E>, ECSBase<T>, IsEventEmittable<T, E>, IsSceneTransitionable<T, E> {

  List<bool Function(E self, Scene<T> scene)> _onBeforeSceneAddFns = [];
  
  List<void Function(E self, Scene<T> scene)> _onSceneAddFns = [];

  List<void Function(E self, Scene<T> scene)> _onAfterSceneAddFns = [];

  List<bool Function(E self, Scene<T> scene)> _onBeforeSceneRemoveFns = [];

  List<void Function(E self, Scene<T> scene)> _onSceneRemoveFns = [];

  List<void Function(E self, Scene<T> scene)> _onAfterSceneRemoveFns = [];

  /// Registers [fn] as a before-add listener.
  ///
  /// [fn] returning `false` cancels the scene add.
  @nonVirtual
  E listenOnBeforeSceneAdd(bool Function(E self, Scene<T> scene) fn) {
    _onBeforeSceneAddFns.add(fn);
    return self;
  }

  /// Registers [fn] as an add listener.
  ///
  /// Called when the add operation is about to happen and was not canceled.
  @nonVirtual
  E listenOnSceneAdd(void Function(E self, Scene<T> scene) fn) {
    _onSceneAddFns.add(fn);
    return self;
  }

  /// Registers [fn] as an after-add listener.
  ///
  /// Called only if the scene add was not canceled.
  @nonVirtual
  E listenOnAfterSceneAdd(void Function(E self, Scene<T> scene) fn) {
    _onAfterSceneAddFns.add(fn);
    return self;
  }

  /// Registers [fn] as a before-remove listener.
  ///
  /// [fn] returning `false` cancels the scene remove.
  @nonVirtual
  E listenOnBeforeSceneRemove(bool Function(E self, Scene<T> scene) fn) {
    _onBeforeSceneRemoveFns.add(fn);
    return self;
  }

  /// Registers [fn] as a remove listener.
  ///
  /// Called when the remove operation is about to happen and was not canceled.
  @nonVirtual
  E listenOnSceneRemove(void Function(E self, Scene<T> scene) fn) {
    _onSceneRemoveFns.add(fn);
    return self;
  }

  /// Registers [fn] as an after-remove listener.
  ///
  /// Called only if the scene remove was not canceled.
  @nonVirtual
  E listenOnAfterSceneRemove(void Function(E self, Scene<T> scene) fn) {
    _onAfterSceneRemoveFns.add(fn);
    return self;
  }

  /// Runs all before-add listeners and [onBeforeSceneAdd].
  ///
  /// Returns `false` if any listener or the override cancels the add.
  bool _doOnBeforeSceneAdd(Scene<T> scene) {
    if (!_onBeforeSceneAddFns.every((f) => f(self, scene))) return false;
    return onBeforeSceneAdd(scene);
  }

  /// Runs all add listeners and [onSceneAdd].
  void _doOnSceneAdd(Scene<T> scene) {
    _onSceneAddFns.forEach((f) => f(self, scene));
    onSceneAdd(scene);
  }

  /// Runs all after-add listeners and [onAfterSceneAdd].
  void _doOnAfterSceneAdd(Scene<T> scene) {
    _onAfterSceneAddFns.forEach((f) => f(self, scene));
    onAfterSceneAdd(scene);
  }

  /// Runs all before-remove listeners and [onBeforeSceneRemove].
  ///
  /// Returns `false` if any listener or the override cancels the remove.
  bool _doOnBeforeSceneRemove(Scene<T> scene) {
    if (!_onBeforeSceneRemoveFns.every((f) => f(self, scene))) return false;
    return onBeforeSceneRemove(scene);
  }

  /// Runs all remove listeners and [onSceneRemove].
  void _doOnSceneRemove(Scene<T> scene) {
    _onSceneRemoveFns.forEach((f) => f(self, scene));
    onSceneRemove(scene);
  }

  /// Runs all after-remove listeners and [onAfterSceneRemove].
  void _doOnAfterSceneRemove(Scene<T> scene) {
    _onAfterSceneRemoveFns.forEach((f) => f(self, scene));
    onAfterSceneRemove(scene);
  }

  /// Override to cancel a scene add from within the class.
  ///
  /// Return `false` to abort. Called after all registered [listenOnBeforeSceneAdd] listeners.
  bool onBeforeSceneAdd(Scene<T> scene) => true;

  /// Override to react when a scene add is about to complete.
  ///
  /// Called by the host after all before-checks have passed.
  void onSceneAdd(Scene<T> scene) {}

  /// Override to react after a scene add has completed.
  ///
  /// Called after all registered [listenOnAfterSceneAdd] listeners.
  void onAfterSceneAdd(Scene<T> scene) {}

  /// Override to cancel a scene remove from within the class.
  ///
  /// Return `false` to abort. Called after all registered [listenOnBeforeSceneRemove] listeners.
  bool onBeforeSceneRemove(Scene<T> scene) => true;

  /// Override to react when a scene remove is about to complete.
  ///
  /// Called by the host after all before-checks have passed.
  void onSceneRemove(Scene<T> scene) {}

  /// Override to react after a scene remove has completed.
  ///
  /// Called after all registered [listenOnAfterSceneRemove] listeners.
  void onAfterSceneRemove(Scene<T> scene) {}

  // ░██████░███     ░███ ░█████████  ░██         
  //   ░██  ░████   ░████ ░██     ░██ ░██         
  //   ░██  ░██░██ ░██░██ ░██     ░██ ░██         
  //   ░██  ░██ ░████ ░██ ░█████████  ░██         
  //   ░██  ░██  ░██  ░██ ░██         ░██         
  //   ░██  ░██       ░██ ░██         ░██         
  // ░██████░██       ░██ ░██         ░██████████ 

  late final List<Scene<T>> _scenes = [];
  bool _dummyScenePresent = true;
  late Scene<T> _currentScene;

  void _assignDummyScene() {
    final dummyScene = FWidgetScene<T>(app);

    // message
    dummyScene.listenOnStart((_) => dummyScene.addEntity(FCenter(app,
      vertical: true,
      child: FColumn(app,
        alignment: .center,
        gap: 16,
        children: [
          FLabel(app, text: 'No scene is currently active.'),
          FLabel(app, text: 'Add a scene to get started.'),
        ],
      ),
    )));

    // background
    double time = 0.0;
    dummyScene.listenOnDraw((_, dt) {
      time += dt;

      final screen = sceneBounds.size;
      const waveCount = 6;
      
      for (int waveIndex = 0; waveIndex < waveCount; waveIndex++) {
        int x = 0;
        while (x < screen.x) {
          final y = (
            ((screen.y / waveCount) * waveIndex) +
            math.sin((x * 0.012) + (time * (1.2 + waveIndex * 0.3)) + (waveIndex * 0.8)) *
            (18.0 + waveIndex * 4.0)
          );
          
          final alpha = 40 + (waveIndex * 12);
          backend.render.drawPixel(x, y, .color(30, 120, 220, alpha));
          x += 2;
        }
      }
    });

    _dummyScenePresent = true;
    _currentScene = dummyScene;

    _scenes.clear();
    _scenes.add(_currentScene);
  }

  Iterable<Scene<T>> getScenes() => _scenes;

  Scene<T> get currentScene => _currentScene;

  /// Replaces the first scene whose `runtimeType == scene.runtimeType` with [scene].
  E replaceScene(Scene<T> scene) {
    final old = _scenes.where((c) => c.runtimeType == scene.runtimeType).firstOrNull;
    if (old != null) removeScene(old);
    addScene(scene);
    return self;
  }

  S? getSceneByKey<S extends Scene<T>>(String key) => _scenes.where((s) => s.key == key).firstOrNull as S?;

  S? getScene<S extends Scene<T>>() => _scenes.whereType<S>().firstOrNull;

  void swapScene(Scene<T> oldScene, Scene<T> newScene) {
    if (getSceneByKey(oldScene.key) != null) {
      removeScene(oldScene);
    }
    
    addScene(newScene);
    
    if (oldScene.id == _currentScene.id) {
      setScene(newScene);
    }
  }

  E addScene(Scene<T> scene) {
    final existingScene = getSceneByKey(scene.key);
    if (existingScene != null) {
      throw StateError('You are trying to register already registered Scene $scene.');
    }

    emit(EventSceneAdding(app, scene));

    if (!_doOnBeforeSceneAdd(scene)) {
      emit(EventSceneAddCancelled(app, scene));
      return self;
    }

    if (!scene._doOnBeforeAdd(self)) {
      emit(EventSceneAddCancelled(app, scene));
      return self;
    }

    if (_dummyScenePresent) {
      _scenes.clear();
    }
    
    _doOnSceneAdd(scene);
    if (!scene.isClone) scene._doAdd(self);
    _scenes.add(scene);

    if (_dummyScenePresent) {
      _dummyScenePresent = false;
      _currentScene = scene;
    }

    scene._doOnAfterAdd(self);
    _doOnAfterSceneAdd(scene);
    emit(EventSceneAdded(app, scene));

    return self;
  }

  E removeScene(Scene<T> scene) {
    emit(EventSceneRemoving(app, scene));
    
    if (!_doOnBeforeSceneRemove(scene)) {
      emit(EventSceneRemoveCancelled(app, scene));
      return self;
    }

    if (!scene._doOnBeforeRemove()) {
      emit(EventSceneRemoveCancelled(app, scene));
      return self;
    }
    
    _doOnSceneRemove(scene);
    scene._doRemove();
    _scenes.remove(scene);

    scene._doOnAfterRemove();
    _doOnAfterSceneRemove(scene);
    emit(EventSceneRemoved(app, scene));
    return self;
  }

  void nextScene() => setSceneByIndex((_scenes.indexOf(_currentScene) + 1) % _scenes.length);

  void previousScene() => setSceneByIndex((_scenes.indexOf(_currentScene) - 1) % _scenes.length);

  bool _leaveCurrentScene() {
    final scene = _currentScene;

    emit(EventSceneLeaving(app, scene));

    if (!_doOnBeforeSceneLeave(scene)) {
      emit(EventSceneLeaveCancelled(app, scene));
      return false;
    }

    if (!scene._doOnBeforeLeave()) {
      emit(EventSceneLeaveCancelled(app, scene));
      return false;
    } 

    _doOnSceneLeave(scene);
    scene._doOnLeave();

    _doOnAfterSceneLeave(scene);
    scene._doOnAfterLeave();
    emit(EventSceneLeft(app, scene));
    return true;
  }

  bool _enterScene(Scene<T> scene) {
    emit(EventSceneEntering(app, scene));

    if (!_doOnBeforeSceneEnter(scene)) {
      emit(EventSceneEnterCancelled(app, scene));
      return false;
    }

    if (!scene._doOnBeforeEnter()) {
      emit(EventSceneEnterCancelled(app, scene));
      return false;
    }

    _doOnSceneEnter(scene);
    scene._doOnEnter();
    _currentScene = scene;
    if (!scene.isClone) scene._doStart();

    _doOnAfterSceneEnter(scene);
    scene._doOnAfterEnter();
    emit(EventSceneEntered(app, scene));
    return true;
  }

  void setScene(Scene<T> scene) {
    final from = _currentScene;
    final to = scene;

    emit(EventSceneTransitioning(app, from, to));

    if (!_doOnBeforeSceneTransition(from, to)) {
      emit(EventSceneTransitionCancelled(app, from, to));
      return;
    }

    _doOnSceneTransition(from, to);

    if (from != to) {
      if (!_leaveCurrentScene()) {
        emit(EventSceneTransitionCancelled(app, from, to));
        return;
      }
    }

    if (!_enterScene(to)) {
      emit(EventSceneTransitionCancelled(app, from, to));
      return;
    }

    _doOnAfterSceneTransition(from, to);
    emit(EventSceneTransitioned(app, from, to));
  }

  void setSceneByIndex(int index) {
    var scene = _scenes.elementAtOrNull(index);
    if (scene == null) throw Exception('Invalid scene index: $index');
    setScene(scene);
  }

  void setSceneByKey(String key) {
    var scene = _scenes.where((s) => s.key == key).firstOrNull;
    if (scene == null) throw Exception('Invalid scene key: $key');
    setScene(scene);
  }
}

/// Adds scene system add/remove lifecycle hooks to an ECS object.
///
/// Covers two events: system add and system remove, each with a full
/// three-phase contract:
/// - **before** => cancelable; any listener or override returning `false` aborts the operation
/// - **on** => the operation is about to complete; called by the host after all before-checks pass
/// - **after** => the operation has completed; side-effects and cleanup go here
mixin IsSceneSystemManagable<T extends App<T>, E extends ECSBase<T>>
  on Self<E>, ECSBase<T>, IsEventEmittable<T, E> {

  // ░██     ░██   ░██████     ░██████   ░██     ░██   ░██████   
  // ░██     ░██  ░██   ░██   ░██   ░██  ░██    ░██   ░██   ░██  
  // ░██     ░██ ░██     ░██ ░██     ░██ ░██   ░██   ░██         
  // ░██████████ ░██     ░██ ░██     ░██ ░███████     ░████████  
  // ░██     ░██ ░██     ░██ ░██     ░██ ░██   ░██           ░██ 
  // ░██     ░██  ░██   ░██   ░██   ░██  ░██    ░██   ░██   ░██  
  // ░██     ░██   ░██████     ░██████   ░██     ░██   ░██████   
  
  List<bool Function(E self, SceneSystem<T> system)> _onBeforeSceneSystemAddFns = [];
  
  List<void Function(E self, SceneSystem<T> system)> _onSceneSystemAddFns = [];

  List<void Function(E self, SceneSystem<T> system)> _onAfterSceneSystemAddFns = [];
  
  List<bool Function(E self, SceneSystem<T> system)> _onBeforeSceneSystemRemoveFns = [];
  
  List<void Function(E self, SceneSystem<T> system)> _onSceneSystemRemoveFns = [];

  List<void Function(E self, SceneSystem<T> system)> _onAfterSceneSystemRemoveFns = [];

  /// Registers [fn] as a before-add listener.
  ///
  /// [fn] returning `false` cancels the system add.
  @nonVirtual
  E listenOnBeforeSceneSystemAdd(bool Function(E self, SceneSystem<T> system) fn) {
    _onBeforeSceneSystemAddFns.add(fn);
    return self;
  }

  /// Registers [fn] as an add listener.
  ///
  /// Called when the add operation is about to happen and was not canceled.
  @nonVirtual
  E listenOnSceneSystemAdd(void Function(E self, SceneSystem<T> system) fn) {
    _onSceneSystemAddFns.add(fn);
    return self;
  }

  /// Registers [fn] as an after-add listener.
  ///
  /// Called only if the system add was not canceled.
  @nonVirtual
  E listenOnAfterSceneSystemAdd(void Function(E self, SceneSystem<T> system) fn) {
    _onAfterSceneSystemAddFns.add(fn);
    return self;
  }

  /// Registers [fn] as a before-remove listener.
  ///
  /// [fn] returning `false` cancels the system remove.
  @nonVirtual
  E listenOnBeforeSceneSystemRemove(bool Function(E self, SceneSystem<T> system) fn) {
    _onBeforeSceneSystemRemoveFns.add(fn);
    return self;
  }

  /// Registers [fn] as a remove listener.
  ///
  /// Called when the remove operation is about to happen and was not canceled.
  @nonVirtual
  E listenOnSceneSystemRemove(void Function(E self, SceneSystem<T> system) fn) {
    _onSceneSystemRemoveFns.add(fn);
    return self;
  }

  /// Registers [fn] as an after-remove listener.
  ///
  /// Called only if the system remove was not canceled.
  @nonVirtual
  E listenOnAfterSceneSystemRemove(void Function(E self, SceneSystem<T> system) fn) {
    _onAfterSceneSystemRemoveFns.add(fn);
    return self;
  }

  /// Runs all before-add listeners and [onBeforeSceneSystemAdd].
  ///
  /// Returns `false` if any listener or the override cancels the add.
  bool _doOnBeforeSceneSystemAdd(SceneSystem<T> system) {
    if (!_onBeforeSceneSystemAddFns.every((f) => f(self, system))) return false;
    return onBeforeSceneSystemAdd(system);
  }

  /// Runs all add listeners and [onSceneSystemAdd].
  void _doOnSceneSystemAdd(SceneSystem<T> system) {
    _onSceneSystemAddFns.forEach((f) => f(self, system));
    onSceneSystemAdd(system);
  }

  /// Runs all after-add listeners and [onAfterSceneSystemAdd].
  void _doOnAfterSceneSystemAdd(SceneSystem<T> system) {
    _onAfterSceneSystemAddFns.forEach((f) => f(self, system));
    onAfterSceneSystemAdd(system);
  }

  /// Runs all before-remove listeners and [onBeforeSceneSystemRemove].
  ///
  /// Returns `false` if any listener or the override cancels the remove.
  bool _doOnBeforeSceneSystemRemove(SceneSystem<T> system) {
    if (!_onBeforeSceneSystemRemoveFns.every((f) => f(self, system))) return false;
    return onBeforeSceneSystemRemove(system);
  }

  /// Runs all remove listeners and [onSceneSystemRemove].
  void _doOnSceneSystemRemove(SceneSystem<T> system) {
    _onSceneSystemRemoveFns.forEach((f) => f(self, system));
    onSceneSystemRemove(system);
  }

  /// Runs all after-remove listeners and [onAfterSceneSystemRemove].
  void _doOnAfterSceneSystemRemove(SceneSystem<T> system) {
    _onAfterSceneSystemRemoveFns.forEach((f) => f(self, system));
    onAfterSceneSystemRemove(system);
  }

  /// Override to cancel a system add from within the class.
  ///
  /// Return `false` to abort. Called after all registered [listenOnBeforeSceneSystemAdd] listeners.
  bool onBeforeSceneSystemAdd(SceneSystem<T> system) => true;

  /// Override to react when a system add is about to complete.
  ///
  /// Called by the host after all before-checks have passed.
  /// 
  /// Called after all registered [listenOnSceneSystemAdd] listeners.
  void onSceneSystemAdd(SceneSystem<T> system) {}

  /// Override to react after a system add has completed.
  ///
  /// Called after all registered [listenOnAfterSceneSystemAdd] listeners.
  void onAfterSceneSystemAdd(SceneSystem<T> system) {}

  /// Override to cancel a system remove from within the class.
  ///
  /// Return `false` to abort. Called after all registered [listenOnBeforeSceneSystemRemove] listeners.
  bool onBeforeSceneSystemRemove(SceneSystem<T> system) => true;

  /// Override to react when a system remove is about to complete.
  ///
  /// Called by the host after all before-checks have passed.
  /// 
  /// Called after all registered [listenOnSceneSystemRemove] listeners.
  void onSceneSystemRemove(SceneSystem<T> system) {}

  /// Override to react after a system remove has completed.
  ///
  /// Called after all registered [listenOnAfterSceneSystemRemove] listeners.
  void onAfterSceneSystemRemove(SceneSystem<T> system) {}

  // ░██████░███     ░███ ░█████████  ░██         
  //   ░██  ░████   ░████ ░██     ░██ ░██         
  //   ░██  ░██░██ ░██░██ ░██     ░██ ░██         
  //   ░██  ░██ ░████ ░██ ░█████████  ░██         
  //   ░██  ░██  ░██  ░██ ░██         ░██         
  //   ░██  ░██       ░██ ░██         ░██         
  // ░██████░██       ░██ ░██         ░██████████ 

  final List<SceneSystem<T>> _systems = [];

  /// Returns all systems currently registered in this scene.
  Iterable<SceneSystem<T>> getSystems() => _systems;

  /// Replaces the first scene system whose `runtimeType == system.runtimeType` with [system].
  E replaceSystem(SceneSystem<T> system) {
    final old = _systems.where((c) => c.runtimeType == system.runtimeType).firstOrNull;
    if (old != null) _removeSceneSystemInstance(old);
    addSystem(system);
    return self;
  }

  /// Moves the first found system of type [S] to the specified [index].
  /// No-op if no system of type [S] is found.
  /// Clamps [index] to the valid range of the list.
  void relocateSystem<S extends SceneSystem<T>>(int index) {
    final currentIndex = _systems.indexWhere((s) => s is S);
    if (currentIndex == -1) return;

    final system = _systems.removeAt(currentIndex);
    final clampedIndex = index.clamp(0, _systems.length);
    _systems.insert(clampedIndex, system);
  }

  /// Exchanges the positions of the first found system of type [A]
  /// with the first found system of type [B].
  /// No-op if either type is not found.
  void exchangeSystems<A extends SceneSystem<T>, B extends SceneSystem<T>>() {
    final indexA = _systems.indexWhere((s) => s is A);
    if (indexA == -1) return;

    final indexB = _systems.indexWhere((s) => s is B);
    if (indexB == -1) return;

    if (indexA == indexB) return;

    final temp = _systems[indexA];
    _systems[indexA] = _systems[indexB];
    _systems[indexB] = temp;
  }

  /// Replaces the registered [A] system with [newSystem] of type [B] in one step.
  void swapSystem<A extends SceneSystem<T>>(SceneSystem<T> newSystem) {
    if (hasSystem<A>()) removeSystem<A>();
    addSystem(newSystem);
  }

  /// Replaces the system registered under [type] with [newSystem] in one step.
  void swapSystemByType<B extends SceneSystem<T>>(Type type, B newSystem) {
    if (hasSystemByType(type)) removeSystemByType(type);
    addSystem<B>(newSystem);
  }

  /// Registers [system] in this scene and runs the full add lifecycle.
  ///
  /// If a system of the same runtime type is already registered it is removed
  /// first. Emits [EventSceneSystemAdding]; cancellable hooks emit
  /// [EventSceneSystemAddCancelled]. On success emits [EventSceneSystemAdded].
  @mustCallSuper
  void addSystem<S extends SceneSystem<T>>(S system) {
    emit(EventSceneSystemAdding(app, scene, system));

    if (!_doOnBeforeSceneSystemAdd(system)) {
      emit(EventSceneSystemAddCancelled(app, scene, system));
      return;
    }

    if (!system._doOnBeforeAdd(self)) {
      emit(EventSceneSystemAddCancelled(app, scene, system));
      return;
    }

    _doOnSceneSystemAdd(system);
    if (!system.isClone) system._doAdd(self);
    
    _systems.add(system);

    system._doOnAfterAdd(self);
    _doOnAfterSceneSystemAdd(system);
    emit(EventSceneSystemAdded(app, scene, system));
  }

  /// Returns the registered system of type [S], or `null` if absent.
  S? getSystem<S extends SceneSystem<T>>() => _systems.whereType<S>().firstOrNull;

  /// Returns `true` if a system of type [S] is currently registered.
  bool hasSystem<S extends SceneSystem<T>>() => _systems.any((s) => s is S);

  /// Returns `true` if a system registered under [type] is currently present.
  bool hasSystemByType(Type type)
    => _systems.any((c) => c.runtimeType == type);

  /// Removes the system of type [S]. No-op if absent.
  E removeSystem<S extends SceneSystem<T>>() {
    final c = getSystem<S>();
    if (c != null) _removeSceneSystemInstance(c);
    return self;
  }

  /// Removes the system registered under [type] and runs the full remove
  /// lifecycle. Emits [EventSceneSystemRemoving]; cancellable hooks emit
  /// [EventSceneSystemRemoveCancelled]. On success emits
  /// [EventSceneSystemRemoved].
  E removeSystemByType(Type type) {
    final system = _systems.where((c) => c.runtimeType == type).firstOrNull;
    if (system != null) _removeSceneSystemInstance(system);
    return self;
  }

  void _removeSceneSystemInstance(SceneSystem<T> system) {
    if (!_systems.contains(system)) return;

    emit(EventSceneSystemRemoving(app, scene, system));

    if (!_doOnBeforeSceneSystemRemove(system)) {
      emit(EventSceneSystemRemoveCancelled(app, scene, system));
      return;
    }

    if (!system._doOnBeforeRemove()) {
      emit(EventSceneSystemRemoveCancelled(app, scene, system));
      return;
    }

    _doOnSceneSystemRemove(system);
    system._doRemove();
    _systems.remove(system);

    system._doOnAfterRemove();
    _doOnAfterSceneSystemRemove(system);
    emit(EventSceneSystemRemoved(app, scene, system));
  }
}

/// Adds scene transition lifecycle hooks to an ECS object.
///
/// Covers three transition events: enter, leave, and the full transition arc (from > to), each with a full three-phase contract:
/// - **before** => cancelable; any listener or override returning `false` aborts the operation
/// - **on** => the operation is about to complete; called by the host (e.g. [App]) after all before-checks pass
/// - **after** => the operation has completed; side-effects and cleanup go here
mixin IsSceneTransitionable<T extends App<T>, E extends ECSBase<T>> on Self<E> {

  List<bool Function(E self, Scene<T> scene)> _onBeforeSceneEnterFns = [];

  List<void Function(E self, Scene<T> scene)> _onSceneEnterFns = [];

  List<void Function(E self, Scene<T> scene)> _onAfterSceneEnterFns = [];

  List<bool Function(E self, Scene<T> scene)> _onBeforeSceneLeaveFns = [];

  List<void Function(E self, Scene<T> scene)> _onSceneLeaveFns = [];

  List<void Function(E self, Scene<T> scene)> _onAfterSceneLeaveFns = [];

  List<bool Function(E self, Scene<T> from, Scene<T> to)> _onBeforeSceneTransitionFns = [];

  List<void Function(E self, Scene<T> from, Scene<T> to)> _onSceneTransitionFns = [];

  List<void Function(E self, Scene<T> from, Scene<T> to)> _onAfterSceneTransitionFns = [];

  /// Registers [fn] as a before-enter listener.
  ///
  /// [fn] returning `false` cancels the scene enter.
  @nonVirtual
  E listenOnBeforeSceneEnter(bool Function(E self, Scene<T> scene) fn) {
    _onBeforeSceneEnterFns.add(fn);
    return self;
  }

  /// Registers [fn] as an enter listener.
  ///
  /// Called when the enter operation is about to happen and was not canceled.
  @nonVirtual
  E listenOnSceneEnter(void Function(E self, Scene<T> scene) fn) {
    _onSceneEnterFns.add(fn);
    return self;
  }

  /// Registers [fn] as an after-enter listener.
  ///
  /// Called only if the scene enter was not canceled.
  @nonVirtual
  E listenOnAfterSceneEnter(void Function(E self, Scene<T> scene) fn) {
    _onAfterSceneEnterFns.add(fn);
    return self;
  }

  /// Registers [fn] as a before-leave listener.
  ///
  /// [fn] returning `false` cancels the scene leave.
  @nonVirtual
  E listenOnBeforeSceneLeave(bool Function(E self, Scene<T> scene) fn) {
    _onBeforeSceneLeaveFns.add(fn);
    return self;
  }

  /// Registers [fn] as a leave listener.
  ///
  /// Called when the leave operation is about to happen and was not canceled.
  @nonVirtual
  E listenOnSceneLeave(void Function(E self, Scene<T> scene) fn) {
    _onSceneLeaveFns.add(fn);
    return self;
  }

  /// Registers [fn] as an after-leave listener.
  ///
  /// Called only if the scene leave was not canceled.
  @nonVirtual
  E listenOnAfterSceneLeave(void Function(E self, Scene<T> scene) fn) {
    _onAfterSceneLeaveFns.add(fn);
    return self;
  }

  /// Registers [fn] as a before-transition listener.
  ///
  /// [fn] returning `false` cancels the full scene transition.
  @nonVirtual
  E listenOnBeforeSceneTransition(bool Function(E self, Scene<T> from, Scene<T> to) fn) {
    _onBeforeSceneTransitionFns.add(fn);
    return self;
  }

  /// Registers [fn] as a transition listener.
  ///
  /// Called when the transition operation is about to happen and was not canceled.
  @nonVirtual
  E listenOnSceneTransition(void Function(E self, Scene<T> from, Scene<T> to) fn) {
    _onSceneTransitionFns.add(fn);
    return self;
  }

  /// Registers [fn] as an after-transition listener.
  ///
  /// Called only if the scene transition was not canceled.
  @nonVirtual
  E listenOnAfterSceneTransition(void Function(E self, Scene<T> from, Scene<T> to) fn) {
    _onAfterSceneTransitionFns.add(fn);
    return self;
  }

  /// Runs all before-enter listeners and [onBeforeSceneEnter].
  ///
  /// Returns `false` if any listener or the override cancels the enter.
  bool _doOnBeforeSceneEnter(Scene<T> scene) {
    if (!_onBeforeSceneEnterFns.every((f) => f(self, scene))) return false;
    return onBeforeSceneEnter(scene);
  }

  /// Runs all enter listeners and [onSceneEnter].
  void _doOnSceneEnter(Scene<T> scene) {
    _onSceneEnterFns.forEach((f) => f(self, scene));
    onSceneEnter(scene);
  }

  /// Runs all after-enter listeners and [onAfterSceneEnter].
  void _doOnAfterSceneEnter(Scene<T> scene) {
    _onAfterSceneEnterFns.forEach((f) => f(self, scene));
    onAfterSceneEnter(scene);
  }

  /// Runs all before-leave listeners and [onBeforeSceneLeave].
  ///
  /// Returns `false` if any listener or the override cancels the leave.
  bool _doOnBeforeSceneLeave(Scene<T> scene) {
    if (!_onBeforeSceneLeaveFns.every((f) => f(self, scene))) return false;
    return onBeforeSceneLeave(scene);
  }

  /// Runs all leave listeners and [onSceneLeave].
  void _doOnSceneLeave(Scene<T> scene) {
    _onSceneLeaveFns.forEach((f) => f(self, scene));
    onSceneLeave(scene);
  }

  /// Runs all after-leave listeners and [onAfterSceneLeave].
  void _doOnAfterSceneLeave(Scene<T> scene) {
    _onAfterSceneLeaveFns.forEach((f) => f(self, scene));
    onAfterSceneLeave(scene);
  }

  /// Runs all before-transition listeners and [onBeforeSceneTransition].
  ///
  /// Returns `false` if any listener or the override cancels the transition.
  bool _doOnBeforeSceneTransition(Scene<T> from, Scene<T> to) {
    if (!_onBeforeSceneTransitionFns.every((f) => f(self, from, to))) return false;
    return onBeforeSceneTransition(from, to);
  }

  /// Runs all transition listeners and [onSceneTransition].
  void _doOnSceneTransition(Scene<T> from, Scene<T> to) {
    _onSceneTransitionFns.forEach((f) => f(self, from, to));
    onSceneTransition(from, to);
  }

  /// Runs all after-transition listeners and [onAfterSceneTransition].
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

/// Adds a one-shot start lifecycle hook to an ECS object.
///
/// The **on** phase only, starting is not cancelable and fires at most once
/// regardless of how many times [_doStart] is called.
mixin IsStartable<T extends App<T>, E extends ECSBase<T>> on Self<E> {

  /// Whether this object has already started.
  bool hasStarted = false;

  List<void Function(E self)> _onStartFns = [];

  /// Registers [fn] to be called when this object starts.
  ///
  /// [fn] will fire at most once, on the first [_doStart] call.
  @nonVirtual
  E listenOnStart(void Function(E self) fn) {
    _onStartFns.add(fn);
    return self;
  }

  /// Commits the start: sets [hasStarted], notifies listeners, and calls [onStart].
  ///
  /// No-op if already started.
  void _doStart() {
    if (hasStarted) return;
    hasStarted = true;
    _onStartFns.forEach((fn) => fn(self));
    onStart();
  }

  /// Override to react when this object starts.
  ///
  /// Called after all registered [listenOnStart] listeners. Fires at most once.
  void onStart() {}
}

/// Adds [Task] processing capabilities to an ECS object.
///
/// Tasks are queued and executed in a controlled pipeline each frame.
/// Listeners can intercept and cancel tasks before they reach [onTask] or execute.
mixin IsTaskProcessable<T extends App<T>, E extends ECSBase<T>> on Self<E>, HasAppAccess<T>, IsEventEmittable<T, E> {
  
  // ░██     ░██   ░██████     ░██████   ░██     ░██   ░██████   
  // ░██     ░██  ░██   ░██   ░██   ░██  ░██    ░██   ░██   ░██  
  // ░██     ░██ ░██     ░██ ░██     ░██ ░██   ░██   ░██         
  // ░██████████ ░██     ░██ ░██     ░██ ░███████     ░████████  
  // ░██     ░██ ░██     ░██ ░██     ░██ ░██   ░██           ░██ 
  // ░██     ░██  ░██   ░██   ░██   ░██  ░██    ░██   ░██   ░██  
  // ░██     ░██   ░██████     ░██████   ░██     ░██   ░██████   

  List<void Function(Task<T> task)> _onTaskFns = [];

  /// Registers [fn] to be called for each task before it is executed.
  @nonVirtual
  E listenOnTask(bool Function(Task<T> task) fn) {
    _onTaskFns.add(fn);
    return self;
  }

  bool _doCanceledTask(Task<T> task) {
    if (!task.isCanceled) return false;
    emit(EventTaskCancelled(app, task));
    return true;
  }

  // (internal) called by task system to propagate task
  // by default just call the hooks
  bool _doTask(Task<T> task, double dt) {
    final isFirstRun = !task._hasStarted;
    task._hasStarted = true;
    if (isFirstRun) emit(EventTaskStarting(app, task));
    if (_doCanceledTask(task)) return true;
    for (final f in _onTaskFns) {
      if (_doCanceledTask(task)) return true;
      f(task);
    }
    if (_doCanceledTask(task)) return true;
    if (isFirstRun) onTask(task);
    if (_doCanceledTask(task)) return true;
    final result = task._doUpdate(dt);
    if (result) emit(EventTaskFinished(app, task));
    return result;
  }

  /// Override to intercept tasks before they execute.
  ///
  /// Called after all [listenOnTask] listeners and before [Task] is executed.
  /// The task can be canceled here via [Task.cancel].
  void onTask(Task<T> task) {}

  // ░██████░███     ░███ ░█████████  ░██         
  //   ░██  ░████   ░████ ░██     ░██ ░██         
  //   ░██  ░██░██ ░██░██ ░██     ░██ ░██         
  //   ░██  ░██ ░████ ░██ ░█████████  ░██         
  //   ░██  ░██  ░██  ░██ ░██         ░██         
  //   ░██  ░██       ░██ ░██         ░██         
  // ░██████░██       ░██ ░██         ░██████████ 

  Set<Task<T>> _taskQueue = {};
  
  Set<Task<T>> _pendingTaskQueue = {};

  /// Enqueues [task] for execution starting at the end of the current frame.
  @override
  void task(Task<T> task) {
    if (task._isQueued) return;
    task._isQueued = true;
    task._reset();
    _pendingTaskQueue.add(task);
  }

  /// Enqueues [task] and executes it immediately at the end of the current frame,
  /// if it isn't already running.
  @override
  E run(Task<T> task) {
    if (task._isQueued) return self;
    task._isQueued = true;
    task._reset();
    _pendingTaskQueue.add(task);

    final done = _doTask(task, time.dt);
    if (done) {
      _pendingTaskQueue.remove(task);
      task._isQueued = false;
    }
    return self;
  }

  void _processTasks(double dt) {
    if (_pendingTaskQueue.isNotEmpty) {
      _taskQueue.addAll(_pendingTaskQueue);
      _pendingTaskQueue.clear();
    }
    _taskQueue.removeWhere((task) {
      final done = _doTask(task, dt);
      if (done) task._isQueued = false;
      return done;
    });
  }

  /// Clears task queue.
  void clearTaskQueue() {
    _taskQueue.clear();
    _pendingTaskQueue.clear();
  }
}

/// Adds an update lifecycle hook to an ECS object.
///
/// The **on** phase only, updating is not cancelable.
mixin IsUpdatable<T extends App<T>, E extends ECSBase<T>> on Self<E>, ECSBase<T> {
  List<void Function(E self, double dt)> _onUpdateFns = [];

  /// Registers [fn] to be called during the update phase each frame.
  @nonVirtual
  E listenOnUpdate(void Function(E self, double dt) fn) {
    _onUpdateFns.add(fn);
    return self;
  }

  /// Propagates the update phase through listeners and the [onUpdate] hook.
  void _doUpdate(double dt) {
    _onUpdateFns.forEach((f) => f(self, dt));
    onUpdate(dt);
  }

  /// Override to react during the update phase each frame.
  ///
  /// Called after all registered [listenOnUpdate] listeners.
  void onUpdate(double dt) {}
}