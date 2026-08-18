part of '../../raylib_dartified_unhinged.dart';

/// Adds app system add/remove lifecycle hooks to an [App].
///
/// Covers two events: system add and system remove, each with a full
/// three-phase contract:
/// - **before** => cancelable; any listener or override returning `false` aborts the operation
/// - **on** => the operation is about to complete; called by the host after all before-checks pass
/// - **after** => the operation has completed; side-effects and cleanup go here
mixin IsAppSystemManagable<
  T extends App<T>,
  E extends ECSBase<T>
> on
  Self<E>,
  ECSBase<T>,
  IsEventEmittable<T, E>
{

  // ░██     ░██   ░██████     ░██████   ░██     ░██   ░██████   
  // ░██     ░██  ░██   ░██   ░██   ░██  ░██    ░██   ░██   ░██  
  // ░██     ░██ ░██     ░██ ░██     ░██ ░██   ░██   ░██         
  // ░██████████ ░██     ░██ ░██     ░██ ░███████     ░████████  
  // ░██     ░██ ░██     ░██ ░██     ░██ ░██   ░██           ░██ 
  // ░██     ░██  ░██   ░██   ░██   ░██  ░██    ░██   ░██   ░██  
  // ░██     ░██   ░██████     ░██████   ░██     ░██   ░██████   

  late final hookOnBeforeAppSystemAddKey = ECSHookKey<bool Function(E self, AppSystem<T> system)>(
    'IsAppSystemManagable', 'onBeforeAppSystemAdd'
  );

  late final hookOnAppSystemAddKey = ECSHookKey<void Function(E self, AppSystem<T> system)>(
    'IsAppSystemManagable', 'onAppSystemAdd'
  );

  late final hookOnAfterAppSystemAddKey = ECSHookKey<void Function(E self, AppSystem<T> system)>(
    'IsAppSystemManagable', 'onAfterAppSystemAdd'
  );

  late final hookOnBeforeAppSystemRemoveKey = ECSHookKey<bool Function(E self, AppSystem<T> system)>(
    'IsAppSystemManagable', 'onBeforeAppSystemRemove'
  );

  late final hookOnAppSystemRemoveKey = ECSHookKey<void Function(E self, AppSystem<T> system)>(
    'IsAppSystemManagable', 'onAppSystemRemove'
  );

  late final hookOnAfterAppSystemRemoveKey = ECSHookKey<void Function(E self, AppSystem<T> system)>(
    'IsAppSystemManagable', 'onAfterAppSystemRemove'
  );

  Iterable<bool Function(E self, AppSystem<T> system)> get _onBeforeAppSystemAddFns
    => hooksOf(hookOnBeforeAppSystemAddKey);

  Iterable<void Function(E self, AppSystem<T> system)> get _onAppSystemAddFns
    => hooksOf(hookOnAppSystemAddKey);

  Iterable<void Function(E self, AppSystem<T> system)> get _onAfterAppSystemAddFns
    => hooksOf(hookOnAfterAppSystemAddKey);

  Iterable<bool Function(E self, AppSystem<T> system)> get _onBeforeAppSystemRemoveFns
    => hooksOf(hookOnBeforeAppSystemRemoveKey);

  Iterable<void Function(E self, AppSystem<T> system)> get _onAppSystemRemoveFns
    => hooksOf(hookOnAppSystemRemoveKey);

  Iterable<void Function(E self, AppSystem<T> system)> get _onAfterAppSystemRemoveFns
    => hooksOf(hookOnAfterAppSystemRemoveKey);

  /// Registers [fn] as a before-add listener.
  ///
  /// [fn] returning `false` cancels the system add.
  @nonVirtual
  E listenOnBeforeAppSystemAdd(bool Function(E self, AppSystem<T> system) fn) {
    addHook(hookOnBeforeAppSystemAddKey, fn);
    return self;
  }

  /// Registers [fn] as an add listener.
  ///
  /// Called when the add operation is about to happen and was not canceled.
  @nonVirtual
  E listenOnAppSystemAdd(void Function(E self, AppSystem<T> system) fn) {
    addHook(hookOnAppSystemAddKey, fn);
    return self;
  }

  /// Registers [fn] as an after-add listener.
  ///
  /// Called only if the system add was not canceled.
  @nonVirtual
  E listenOnAfterAppSystemAdd(void Function(E self, AppSystem<T> system) fn) {
    addHook(hookOnAfterAppSystemAddKey, fn);
    return self;
  }

  /// Registers [fn] as a before-remove listener.
  ///
  /// [fn] returning `false` cancels the system remove.
  @nonVirtual
  E listenOnBeforeAppSystemRemove(bool Function(E self, AppSystem<T> system) fn) {
    addHook(hookOnBeforeAppSystemRemoveKey, fn);
    return self;
  }

  /// Registers [fn] as a remove listener.
  ///
  /// Called when the remove operation is about to happen and was not canceled.
  @nonVirtual
  E listenOnAppSystemRemove(void Function(E self, AppSystem<T> system) fn) {
    addHook(hookOnAppSystemRemoveKey, fn);
    return self;
  }

  /// Registers [fn] as an after-remove listener.
  ///
  /// Called only if the system remove was not canceled.
  @nonVirtual
  E listenOnAfterAppSystemRemove(void Function(E self, AppSystem<T> system) fn) {
    addHook(hookOnAfterAppSystemRemoveKey, fn);
    return self;
  }

  /// Runs all before-add listeners and [onBeforeAppSystemAdd].
  ///
  /// Returns `false` if any listener or the override cancels the add.
  @mustCallSuper
  bool _doOnBeforeAppSystemAdd(AppSystem<T> system) {
    if (!_onBeforeAppSystemAddFns.every((f) => f(self, system))) return false;
    return onBeforeAppSystemAdd(system);
  }
  
  /// Runs all add listeners and [onAppSystemAdd].
  @mustCallSuper
  void _doOnAppSystemAdd(AppSystem<T> system) {
    _onAppSystemAddFns.forEach((f) => f(self, system));
    onAppSystemAdd(system);
  }

  /// Runs all after-add listeners and [onAfterAppSystemAdd].
  @mustCallSuper
  void _doOnAfterAppSystemAdd(AppSystem<T> system) {
    _onAfterAppSystemAddFns.forEach((f) => f(self, system));
    onAfterAppSystemAdd(system);
  }

  /// Runs all before-remove listeners and [onBeforeAppSystemRemove].
  ///
  /// Returns `false` if any listener or the override cancels the remove.
  @mustCallSuper
  bool _doOnBeforeAppSystemRemove(AppSystem<T> system) {
    if (!_onBeforeAppSystemRemoveFns.every((f) => f(self, system))) return false;
    return onBeforeAppSystemRemove(system);
  }

  /// Runs all remove listeners and [onAppSystemRemove].
  @mustCallSuper
  void _doOnAppSystemRemove(AppSystem<T> system) {
    _onAppSystemRemoveFns.forEach((f) => f(self, system));
    onAppSystemRemove(system);
  }

  /// Runs all after-remove listeners and [onAfterAppSystemRemove].
  @mustCallSuper
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

    system.parent = self;
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