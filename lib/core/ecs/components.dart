part of '../raylib_dartified_unhinged.dart';

class Comp<T extends App<T>> extends ECSBase<T> with

  // identity
  Self<Comp<T>>,

  // has
  HasSceneAccess<T>,
  HasEntityAccess<T>,
  HasVars<T, Comp<T>>,

  // is
  IsActivatable<T, Comp<T>>,
  IsAddable<T, Comp<T>>,
  IsClonable<T, Comp<T>, Cloner<T>>,
  IsDisposable<T, Comp<T>>,
  IsDrawable<T, Comp<T>>,
  IsEventEmittable<T, Comp<T>>,
  IsEventHistoryHolder<T, Comp<T>>,
  IsInputHandleable<Comp<T>>,
  IsRemovable<T, Comp<T>>,
  IsUpdatable<T, Comp<T>>,

  // special
  IsComponentManagable<T, Comp<T>>,
  IsStateHolder<T, Comp<T>, AnyCompSnapshot<T>>,
  IsPersistable<T, Comp<T>, AnyCompSnapshot<T>>

{
  
  @override
  final T app;

  Comp(this.app);

  @override
  late Entity<T> entity;

  bool isAncestorOf(Comp<T> other) {
    var current = other.parent;
    while (current != null) {
      if (identical(current, this)) return true;
      current = current.parent;
    }
    return false;
  }

  bool isDescendantOf(Comp<T> other) {
    return other.isAncestorOf(this);
  }

  //   ░██████   ░██     ░██ ░██████████ ░█████████  ░██     ░██ 
  //  ░██   ░██  ░██     ░██ ░██         ░██     ░██  ░██   ░██  
  // ░██     ░██ ░██     ░██ ░██         ░██     ░██   ░██ ░██   
  // ░██     ░██ ░██     ░██ ░█████████  ░█████████     ░████    
  // ░██     ░██ ░██     ░██ ░██         ░██   ░██       ░██     
  //  ░██   ░██   ░██   ░██  ░██         ░██    ░██      ░██     
  //   ░██████     ░██████   ░██████████ ░██     ░██     ░██     
  //        ░██                                                  

  /// Returns a fresh [QueryComponentComponent] scoped to this component's direct children.
  ///
  /// Entry point for the **Query-like DSL** over components.
  QueryComponentComponent<T> get QueryComp => .new(app, this);

  /// Returns a fresh [QueryComponentComponentDeep] that searches all descendant
  /// components recursively, including those on nested child components.
  QueryComponentComponentDeep<T> get QueryCompDeep => .new(app, this);

  // ░██████░███     ░███ ░█████████  ░██         
  //   ░██  ░████   ░████ ░██     ░██ ░██         
  //   ░██  ░██░██ ░██░██ ░██     ░██ ░██         
  //   ░██  ░██ ░████ ░██ ░█████████  ░██         
  //   ░██  ░██  ░██  ░██ ░██         ░██         
  //   ░██  ░██       ░██ ░██         ░██         
  // ░██████░██       ░██ ░██         ░██████████ 

  @override
  @nonVirtual
  void _doHandleInput() {
    if (isDisabled) return;
    _components.forEach((e) => e._doHandleInput());
    super._doHandleInput();
  }

  @override
  @nonVirtual
  void _doUpdate(double dt) {
    if (isDisabled) return;
    _components.forEach((c) => c._doUpdate(dt));
    super._doUpdate(dt);
  }

  @override
  @nonVirtual
  void _doDraw(double dt) {
    if (isDisabled) return;
    _components.forEach((c) => c._doDraw(dt));
    super._doDraw(dt);
  }

  @override
  void _doOnComponentParentSet(Comp<T> component) {
    component.entity = entity;
  }

  //   ░██████  ░██           ░██████   ░███    ░██ ░██████████ 
  //  ░██   ░██ ░██          ░██   ░██  ░████   ░██ ░██         
  // ░██        ░██         ░██     ░██ ░██░██  ░██ ░██         
  // ░██        ░██         ░██     ░██ ░██ ░██ ░██ ░█████████  
  // ░██        ░██         ░██     ░██ ░██  ░██░██ ░██         
  //  ░██   ░██ ░██          ░██   ░██  ░██   ░████ ░██         
  //   ░██████  ░██████████   ░██████   ░██    ░███ ░██████████ 

  @override
  @nonVirtual
  void _doOnClone(Comp<T> copy, [Cloner<T>? cloner]) {
    emit(EventCompCloning(app, self, copy));

    _components.forEach((childComp) {
      if (!(cloner?.allowComp(copy, childComp) ?? false)) return;

      _doCloneComp(
        to: copy,
        what: childComp,
        cloner: cloner,
        replaceComponent: true,
      );
    });

    super._doOnClone(copy, cloner);
  }

  @override
  @nonVirtual
  void _doCloneAfter(Comp<T> target, [Cloner<T>? cloner]) {
    super._doCloneAfter(target, cloner);
    emit(EventCompCloned(app, self, target));
  }

  // clone

  @override
  Comp<T> createInstance() => .new(app);

  // state

  @override
  AnyCompSnapshot<T> createSnapshot() => .new(namedId);  

  @override
  @nonVirtual
  AnyCompSnapshot<T> captureSnapshot() {
    final snapshot = createSnapshot();
    snapshot.componentSnapshots = _components
      .map((c) => c.captureSnapshot())
      .toList();
    return snapshot;
  }

  @override
  @mustCallSuper
  void restoreSnapshot(covariant AnyCompSnapshot<T> snapshot) {
    _restoreSnapshotList(
      originSnapshot: snapshot,
      sourceList: _components.toList(),
      sourceSnapshots: snapshot.componentSnapshots,
      onRecreate: (x) => addComp(x),
      onRestore: (x, s) => x.restoreSnapshot(s),
      onRemove: _removeComponentInstance,
    );
  }
}

typedef AnyCompSnapshot<T extends App<T>> = CompSnapshot<T, Comp<T>>;

class CompSnapshot<T extends App<T>, C extends Comp<T>> extends StateSnapshot<T, C> {
  late List<AnyCompSnapshot<T>> componentSnapshots;

  CompSnapshot(super.sourceId);

  @override
  C createInstance(T app) => Comp<T>(app) as C;

  @nonVirtual
  C assignComponents(T app, C destination) {
    for (final snap in componentSnapshots) {
      destination.addComp(snap.reconstruct(app));
    }
    return destination;
  }

  @override
  @nonVirtual
  C reconstruct(T app) => assignComponents(app, createInstance(app));
}
