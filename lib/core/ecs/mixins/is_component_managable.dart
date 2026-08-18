part of '../../raylib_dartified_unhinged.dart';

typedef IsAnyComponentManagable<T extends App<T>> = IsComponentManagable<T, ECSBase<T>>;

mixin IsComponentManagable<
  T extends App<T>,
  E extends ECSBase<T>
> on
  HasEntityAccess<T>,
  IsEventEmittable<T, E>,
  IsDisposable<T, E>
{
  // ░██     ░██   ░██████     ░██████   ░██     ░██   ░██████   
  // ░██     ░██  ░██   ░██   ░██   ░██  ░██    ░██   ░██   ░██  
  // ░██     ░██ ░██     ░██ ░██     ░██ ░██   ░██   ░██         
  // ░██████████ ░██     ░██ ░██     ░██ ░███████     ░████████  
  // ░██     ░██ ░██     ░██ ░██     ░██ ░██   ░██           ░██ 
  // ░██     ░██  ░██   ░██   ░██   ░██  ░██    ░██   ░██   ░██  
  // ░██     ░██   ░██████     ░██████   ░██     ░██   ░██████   

  late final hookOnBeforeCompAddKey = ECSHookKey<bool Function(E self, Comp<T> component)>(
    'IsComponentManagable', 'onBeforeCompAdd'
  );

  late final hookOnCompAddKey = ECSHookKey<void Function(E self, Comp<T> component)>(
    'IsComponentManagable', 'onCompAdd'
  );

  late final hookOnAfterCompAddKey = ECSHookKey<void Function(E self, Comp<T> component)>(
    'IsComponentManagable', 'onAfterCompAdd'
  );

  late final hookOnBeforeCompRemoveKey = ECSHookKey<bool Function(E self, Comp<T> component)>(
    'IsComponentManagable', 'onBeforeCompRemove'
  );

  late final hookOnCompRemoveKey = ECSHookKey<void Function(E self, Comp<T> component)>(
    'IsComponentManagable', 'onCompRemove'
  );

  late final hookOnAfterCompRemoveKey = ECSHookKey<void Function(E self, Comp<T> component)>(
    'IsComponentManagable', 'onAfterCompRemove'
  );

  late final hookOnBeforeCompCloneKey = ECSHookKey<bool Function(E self, Comp<T> component)>(
    'IsComponentManagable', 'onBeforeCompClone'
  );

  late final hookOnCompCloneKey = ECSHookKey<void Function(E self, Comp<T> component)>(
    'IsComponentManagable', 'onCompClone'
  );

  late final hookOnAfterCompCloneKey = ECSHookKey<void Function(E self, Comp<T> component)>(
    'IsComponentManagable', 'onAfterCompClone'
  );

  Iterable<bool Function(E self, Comp<T> component)> get _onBeforeCompAddFns
    => hooksOf(hookOnBeforeCompAddKey);

  Iterable<void Function(E self, Comp<T> component)> get _onCompAddFns
    => hooksOf(hookOnCompAddKey);

  Iterable<void Function(E self, Comp<T> component)> get _onAfterCompAddFns
    => hooksOf(hookOnAfterCompAddKey);

  Iterable<bool Function(E self, Comp<T> component)> get _onBeforeCompRemoveFns
    => hooksOf(hookOnBeforeCompRemoveKey);

  Iterable<void Function(E self, Comp<T> component)> get _onCompRemoveFns
    => hooksOf(hookOnCompRemoveKey);

  Iterable<void Function(E self, Comp<T> component)> get _onAfterCompRemoveFns
    => hooksOf(hookOnAfterCompRemoveKey);

  Iterable<bool Function(E self, Comp<T> component)> get _onBeforeCompCloneFns
    => hooksOf(hookOnBeforeCompCloneKey);

  Iterable<void Function(E self, Comp<T> component)> get _onCompCloneFns
    => hooksOf(hookOnCompCloneKey);

  Iterable<void Function(E self, Comp<T> component)> get _onAfterCompCloneFns
    => hooksOf(hookOnAfterCompCloneKey);

  @nonVirtual
  E listenOnBeforeCompAdd(bool Function(E self, Comp<T> component) fn) {
    addHook(hookOnBeforeCompAddKey, fn);
    return self;
  }

  @nonVirtual
  E listenOnCompAdd(void Function(E self, Comp<T> component) fn) {
    addHook(hookOnCompAddKey, fn);
    return self;
  }

  @nonVirtual
  E listenOnAfterCompAdd(void Function(E self, Comp<T> component) fn) {
    addHook(hookOnAfterCompAddKey, fn);
    return self;
  }

  @nonVirtual
  E listenOnBeforeCompRemove(bool Function(E self, Comp<T> component) fn) {
    addHook(hookOnBeforeCompRemoveKey, fn);
    return self;
  }

  @nonVirtual
  E listenOnCompRemove(void Function(E self, Comp<T> component) fn) {
    addHook(hookOnCompRemoveKey, fn);
    return self;
  }

  @nonVirtual
  E listenOnAfterCompRemove(void Function(E self, Comp<T> component) fn) {
    addHook(hookOnAfterCompRemoveKey, fn);
    return self;
  }

  @nonVirtual
  E listenOnBeforeCompClone(bool Function(E self, Comp<T> component) fn) {
    addHook(hookOnBeforeCompCloneKey, fn);
    return self;
  }

  @nonVirtual
  E listenOnCompClone(void Function(E self, Comp<T> component) fn) {
    addHook(hookOnCompCloneKey, fn);
    return self;
  }

  @nonVirtual
  E listenOnAfterCompClone(void Function(E self, Comp<T> component) fn) {
    addHook(hookOnAfterCompCloneKey, fn);
    return self;
  }

  @mustCallSuper
  bool _doOnBeforeCompAdd(Comp<T> component) {
    if (!_onBeforeCompAddFns.every((f) => f(self, component))) return false;
    return onBeforeCompAdd(component);
  }
  
  @mustCallSuper
  void _doOnCompAdd(Comp<T> component) {
    _onCompAddFns.forEach((f) => f(self, component));
    onCompAdd(component);
  }

  @mustCallSuper
  void _doOnAfterCompAdd(Comp<T> component) {
    _onAfterCompAddFns.forEach((f) => f(self, component));
    onAfterCompAdd(component);
  }

  @mustCallSuper
  bool _doOnBeforeCompRemove(Comp<T> component) {
    if (!_onBeforeCompRemoveFns.every((f) => f(self, component))) return false;
    return onBeforeCompRemove(component);
  }

  @mustCallSuper
  void _doOnCompRemove(Comp<T> component) {
    _onCompRemoveFns.forEach((f) => f(self, component));
    onCompRemove(component);
  }

  @mustCallSuper
  void _doOnAfterCompRemove(Comp<T> component) {
    _onAfterCompRemoveFns.forEach((f) => f(self, component));
    onAfterCompRemove(component);
  }

  @mustCallSuper
  bool _doOnBeforeCompClone(Comp<T> component) {
    if (!_onBeforeCompCloneFns.every((f) => f(self, component))) return false;
    return onBeforeCompClone(component);
  }

  @mustCallSuper
  void _doOnCompClone(Comp<T> component) {
    _onCompCloneFns.forEach((f) => f(self, component));
    onCompClone(component);
  }

  @mustCallSuper
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
  @mustCallSuper
  bool _doEventLocal(Event<T> event) {
    if (event.scope == .root) return false;
    if (event.scope == .sceneOnly) return false;

    if (_doEventVisitedCheck(event)) return true;
    if (event.isStopped) return true;

    if (_doEventSelfCheck(event)) return true;
    if (event.isStopped) return true;

    if (event.scope == .local || event.scope == .rootAndLocal) {
      _doOnEvent(event);

      for (final c in _components) {
        if (event.isStopped) return true;
        c._propagate(event);
      }

      if (event.isStopped) return true;

      // `.local` must never leave this subtree, always stop.
      // `.rootAndLocal` is done, but if this IS the origin, it still owes a trip to App
      if (event.scope == .rootAndLocal) {
        return event.origin != self;
      }

      return true;
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
    getAll<C>().forEach((c) => c.setEnabled(true));
    return self;
  }

  /// Activates all top-level components.
  E enableComps() {
    _components.forEach((c) => c.setEnabled(true));
    return self;
  }

  /// Recursively activates every component, including nested ones.
  E enableEverything() {
    _components.forEach((c) {
      c.setEnabled(true);
      c.enableEverything();
    });
    return self;
  }

  /// Deactivates every top-level component of type [C].
  E disableComp<C extends Comp<T>>() {
    getAll<C>().forEach((c) => c.setEnabled(false));
    return self;
  }

  /// Deactivates all top-level components (not nested).
  E disableComps() {
    _components.forEach((c) => c.setEnabled(false));
    return self;
  }

  /// Recursively deactivates every component, including nested ones.
  E disableEverything() {
    _components.forEach((c) {
      c.setEnabled(false);
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
    component.entity = entity;

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
    ClonePolicy<T>? policy,
    bool replaceComponents = true,
  }) {
    _components.forEach((childComp) {
      if (!(policy?.allowComp(into, childComp) ?? true)) return;

      _doCloneComp(
        to: into,
        what: childComp,
        policy: policy,
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
    ClonePolicy<T>? policy,
    bool replaceComponent = false,
  }) {
    if (!what.isCloneable) return;
    if (!_doOnBeforeCompClone(what)) return;
    
    _doOnCompClone(what);
    // This clone() call ALREADY does everything.
    // Returns the fully cloned component
    final fullyClonedComp = what.clone(policy);

    if (replaceComponent) {
      to.replaceComp(fullyClonedComp);
    } else {
      to.addComp(fullyClonedComp);
    }
    
    // Post-clone hook for the parent
    _doOnAfterCompClone(what);
  }

  @override
  @mustCallSuper
  void _doOnDispose() {
    _components.forEach((s) => s._doOnDispose());
    super._doOnDispose();
  }
}