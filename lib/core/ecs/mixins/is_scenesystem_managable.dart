part of '../../raylib_dartified_unhinged.dart';

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