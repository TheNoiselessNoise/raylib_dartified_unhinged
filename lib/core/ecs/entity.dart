part of '../raylib_dartified_unhinged.dart';

/// A single actor in the ECS, the fundamental building block of a [Scene].
///
/// An [Entity] owns a set of [Comp] components and participates in the full
/// ECS lifecycle: input handling, update, draw, and event propagation. All
/// three passes (input → update → draw) are forwarded to every attached
/// component before the entity's own override hooks are called.
///
/// ## Lifecycle order (per frame)
///
/// ```
/// _doHandleInput()  →  components → onInput()
/// _doUpdate(dt)     →  components → listeners → onUpdate(dt)
/// _doDraw(dt)       →  components → listeners → onDraw(dt)
/// ```
///
/// Disabled entities skip all three passes entirely.
///
/// ## Querying components
///
/// Two Query-like entry points are available:
///
/// ```dart
/// entity.Query      // direct components only
/// entity.QueryDeep  // all components, including those on child components
/// ```
///
/// ## Position
///
/// [worldPosition] and [localPosition] are derived from whichever transform
/// component is present ([CTransform] for world-space, [CLocalTransform] for
/// parent-relative). [bounds] is derived from the first collider or visual
/// component found.
///
/// ## Removal
///
/// Call [removeThis] to schedule removal via the scene's command queue rather
/// than removing the entity mid-iteration.
class Entity<T extends App<T>> extends ECSBase<T> with

  // identity
  Self<Entity<T>>,

  // has
  HasSceneAccess<T>,
  HasEntityAccess<T>,
  HasVars<T, Entity<T>>,

  // is
  IsActivatable<T, Entity<T>>,
  IsAddable<T, Entity<T>>,
  IsClonable<T, Entity<T>, EntityCloner<T>>,
  IsDisposable<T, Entity<T>>,
  IsDrawable<T, Entity<T>>,
  IsEventEmittable<T, Entity<T>>,
  IsEventHistoryHolder<T, Entity<T>>,
  IsInputHandleable<Entity<T>>,
  IsRemovable<T, Entity<T>>,
  IsUpdatable<T, Entity<T>>,
  
  // special
  IsComponentManagable<T, Entity<T>>,
  IsStateHolder<T, Entity<T>, AnyEntitySnapshot<T>>,
  IsPersistable<T, Entity<T>, AnyEntitySnapshot<T>>
{
  
  @override
  final T app;

  Entity(this.app) {
    emit(EventEntityInitialized(app, this));
  }

  @override
  Entity<T> get entity => self;

  /// When `false`, the scene's draw loop skips this entity entirely.
  bool _sceneLevelDrawEnabled = true;

  /// When `false`, the any draw loop (SHOULD) skip this entity entirely.
  bool _drawEnabled = true;

  /// Prevents the scene's render loop from drawing this entity.
  void disableSceneLevelDraw() => _sceneLevelDrawEnabled = false;
  
  /// Prevents any render loop from drawing this entity.
  void disableDraw() => _drawEnabled = false;

  //   ░██████  ░██████████   ░██████   
  //  ░██   ░██ ░██          ░██   ░██  
  // ░██        ░██         ░██     ░██ 
  // ░██  █████ ░█████████  ░██     ░██ 
  // ░██     ██ ░██         ░██     ░██ 
  //  ░██  ░███ ░██          ░██   ░██  
  //   ░█████░█ ░██████████   ░██████   

  /// The entity's position in scene space.
  ///
  /// Resolution order:
  /// 1. [CTransform] returns its position directly.
  /// 2. [CLocalTransform] with an [Entity] parent, adds the offset to the
  ///    parent's [worldPosition] recursively.
  /// 3. Falls back to [Scene.sceneBounds]'s position if neither is present.
  Vector2D get worldPosition {
    final sceneOffset = sceneBounds.position;

    final transform = this.transform;
    if (transform != null) return sceneOffset.add(transform.position);

    final local = localTransform;
    if (local != null) {
      if (parent case Entity<T> parentEntity) {
        return parentEntity.worldPosition.add(local.offset);
      }
    }

    return sceneOffset;
  }

  /// The entity's position relative to its parent.
  ///
  /// Returns [CLocalTransform.offset] if present, otherwise [Vector2D.zero].
  Vector2D get localPosition {
    final local = localTransform;
    if (local != null) return local.offset;
    return .zero();
  }

  /// An axis-aligned bounding box derived from the entity's collider or visual
  /// component, or `null` if neither is present.
  ///
  /// Resolution order:
  /// 1. [CCircleCollider] bounding box of the circle.
  /// 2. [CRectCollider] bounding box of the rect.
  /// 3. [CImage] centered on [worldPosition], sized from [CImage.size] or
  ///    the texture dimensions.
  /// 4. [CSprite] centered on [worldPosition], sized from the sprite.
  Bounds? get bounds {
    final circle = get<CCircleCollider<T>>();
    if (circle != null) return .new(
      circle.center.y - circle.radius,
      circle.center.x - circle.radius,
      circle.center.y + circle.radius,
      circle.center.x + circle.radius,
    );

    final rect = get<CRectCollider<T>>();
    if (rect != null) return .fromRectangle(rect.rect);

    final pos = worldPosition;

    final image = get<CImage<T>>();
    if (image != null) {
      final size = image.size ?? .vec2(
        image.texture.width,
        image.texture.height
      );
      final half = size.divideBy(2);
      return .new(
        pos.y - half.y,
        pos.x - half.x,
        pos.y + half.y,
        pos.x + half.x
      );
    }

    final sprite = get<CSprite<T>>();
    if (sprite != null) {
      final half = sprite.size.divideBy(2);
      return .new(
        pos.y - half.y,
        pos.x - half.x,
        pos.y + half.y,
        pos.x + half.x
      );
    }

    return null;
  }

  CTransform<T>? get transform => get<CTransform<T>>();
  Entity<T> onTransform(void Function(CTransform<T> t) fn) => on<CTransform<T>>(fn);

  CLocalTransform<T>? get localTransform => get<CLocalTransform<T>>();
  Entity<T> onLocalTransform(void Function(CLocalTransform<T> v) fn) => on<CLocalTransform<T>>(fn);

  CCollider<T>? get collider => get<CCollider<T>>();
  Entity<T> onCollider(void Function(CCollider<T> v) fn) => on<CCollider<T>>(fn);

  CVelocity<T>? get velocity => get<CVelocity<T>>();
  Entity<T> onVelocity(void Function(CVelocity<T> v) fn) => on<CVelocity<T>>(fn);

  CPhysicsBody<T>? get physicsBody => get<CPhysicsBody<T>>();
  Entity<T> onPhysicsBody(void Function(CPhysicsBody<T> v) fn) => on<CPhysicsBody<T>>(fn);

  // ░██████░███     ░███ ░█████████  ░██         
  //   ░██  ░████   ░████ ░██     ░██ ░██         
  //   ░██  ░██░██ ░██░██ ░██     ░██ ░██         
  //   ░██  ░██ ░████ ░██ ░█████████  ░██         
  //   ░██  ░██  ░██  ░██ ░██         ░██         
  //   ░██  ░██       ░██ ░██         ░██         
  // ░██████░██       ░██ ░██         ░██████████ 

  /// Schedules removal of this entity from its scene via the command queue.
  ///
  /// Prefer this over calling `scene.removeEntity` directly during an update
  /// or draw pass, where mutating the entity set mid-iteration is unsafe.
  /// Returns `this` for chaining.
  Entity<T> removeThis() {
    command(RemoveEntityCommand(app, self));
    return self;
  }

  @override
  void _doOnComponentParentSet(Comp<T> component) {
    component.entity = self;
  }

  /// Forwards input handling to all components, then calls [onInput].
  /// Skipped entirely when the entity is disabled.
  @override
  @nonVirtual
  void _doHandleInput() {
    if (isDisabled) return;
    _components.forEach((e) => e._doHandleInput());
    super._doHandleInput();
  }

  /// Advances all components by [dt], fires update listeners, then calls
  /// [onUpdate]. Skipped entirely when the entity is disabled.
  @override
  @mustCallSuper
  void _doUpdate(double dt) {
    if (isDisabled) return;
    _components.forEach((c) => c._doUpdate(dt));
    super._doUpdate(dt);
  }

  /// Draws all components for [dt], fires draw listeners, then calls
  /// [onDraw]. Skipped entirely when the entity is disabled.
  @override
  @mustCallSuper
  void _doDraw(double dt) {
    if (isDisabled) return;
    _components.forEach((c) => c._doDraw(dt));
    super._doDraw(dt);
  }

  //   ░██████   ░██     ░██ ░██████████ ░█████████  ░██     ░██ 
  //  ░██   ░██  ░██     ░██ ░██         ░██     ░██  ░██   ░██  
  // ░██     ░██ ░██     ░██ ░██         ░██     ░██   ░██ ░██   
  // ░██     ░██ ░██     ░██ ░█████████  ░█████████     ░████    
  // ░██     ░██ ░██     ░██ ░██         ░██   ░██       ░██     
  //  ░██   ░██   ░██   ░██  ░██         ░██    ░██      ░██     
  //   ░██████     ░██████   ░██████████ ░██     ░██     ░██     
  //        ░██                                                  

  /// Returns a fresh [QueryEntityComponent] scoped to this entity's direct components.
  ///
  /// Entry point for the **Query-like DSL** over components.
  QueryEntityComponent<T> get QueryComp => .new(app, this);

  /// Returns a fresh [QueryEntityComponentDeep] that searches all components
  /// recursively, including those on child components.
  QueryEntityComponentDeep<T> get QueryCompDeep => .new(app, this);

  //   ░██████  ░██           ░██████   ░███    ░██ ░██████████ 
  //  ░██   ░██ ░██          ░██   ░██  ░████   ░██ ░██         
  // ░██        ░██         ░██     ░██ ░██░██  ░██ ░██         
  // ░██        ░██         ░██     ░██ ░██ ░██ ░██ ░█████████  
  // ░██        ░██         ░██     ░██ ░██  ░██░██ ░██         
  //  ░██   ░██ ░██          ░██   ░██  ░██   ░████ ░██         
  //   ░██████  ░██████████   ░██████   ░██    ░███ ░██████████ 

  void _doOnCloneEntityStart(Entity<T> copy, [EntityCloner<T>? cloner]) {
    emit(EventEntityCloning(app, self, copy));

    _components.forEach((comp) {
      if (!(cloner?.allowComp(copy, comp) ?? false)) return;

      _doCloneComp(
        to: copy,
        what: comp,
        cloner: cloner,
        replaceComponent: true,
      );
    });
  }

  @override
  void _doOnClone(Entity<T> copy, [EntityCloner<T>? cloner]) {
    _doOnCloneEntityStart(copy, cloner);
    super._doOnClone(copy, cloner);
  }

  @override
  @nonVirtual
  void _doCloneAfter(Entity<T> target, [EntityCloner<T>? cloner]) {
    super._doCloneAfter(target, cloner);
    emit(EventEntityCloned(app, self, target));
  }

  // clone

  @override
  Entity<T> createInstance() => .new(app);

  // state

  @override
  AnyEntitySnapshot<T> createSnapshot() => .new(namedId);  

  @override
  @nonVirtual
  AnyEntitySnapshot<T> captureSnapshot() {
    final snapshot = createSnapshot();
    snapshot.componentSnapshots = _components
      .map((c) => c.captureSnapshot())
      .toList();
    return snapshot;
  }

  @override
  @mustCallSuper
  void restoreSnapshot(covariant AnyEntitySnapshot<T> snapshot) {
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

typedef AnyEntitySnapshot<T extends App<T>> = EntitySnapshot<T, Entity<T>>;

class EntitySnapshot<T extends App<T>, E extends Entity<T>> extends StateSnapshot<T, E> {
  late List<AnyCompSnapshot<T>> componentSnapshots;

  EntitySnapshot(super.sourceId);

  @override
  E createInstance(T app) => Entity<T>(app) as E;

  E assignComponents(T app, E destination) {
    for (final snap in componentSnapshots) {
      destination.addComp(snap.reconstruct(app));
    }
    return destination;
  }

  @override
  E reconstruct(T app) => assignComponents(app, createInstance(app));
}

typedef AnyEntityGroup<T extends App<T>> = EntityGroup<T, Entity<T>>;

/// A logical group of related [Entity] objects managed as a single unit.
///
/// An [EntityGroup] is itself an [Entity], so it participates in the scene
/// lifecycle normally. It additionally maintains an ordered [entities] list
/// whose members receive update, draw, and event calls immediately after the
/// group itself.
///
/// ## Transform management
///
/// When an entity is added via [addEntity], [_ensureLocalPosition] reconciles
/// whichever transform style the entity was given:
///
/// - **World transform only** ([CTransform]) => converted to a [CLocalTransform]
///   offset relative to the group's world position.
/// - **Local transform only** ([CLocalTransform]) => a matching [CTransform] is
///   created at the correct world position.
/// - **Both** => left untouched; the caller is assumed to know what they're
///   doing.
/// - **Neither** => left as-is; the propagation system will skip it.
class EntityGroup<T extends App<T>, E extends Entity<T>> extends Entity<T> with
  IsEntityManagable<T, EntityGroup<T, E>, E>
{
  
  EntityGroup(super.app);

  @override
  Bounds? get bounds {
    Bounds? result;

    for (final entity in _entities) {
      final b = entity.bounds;
      if (b == null) continue;

      result = result == null ? b : .new(
        math.min(result.top, b.top),
        math.min(result.left, b.left),
        math.max(result.bottom, b.bottom),
        math.max(result.right, b.right),
      );
    }

    return result;
  }

  @override
  void _doRemove() {
    _entities.toList().forEach(removeEntity);
    super._doRemove();
  }

  //   ░██████  ░██           ░██████   ░███    ░██ ░██████████ 
  //  ░██   ░██ ░██          ░██   ░██  ░████   ░██ ░██         
  // ░██        ░██         ░██     ░██ ░██░██  ░██ ░██         
  // ░██        ░██         ░██     ░██ ░██ ░██ ░██ ░█████████  
  // ░██        ░██         ░██     ░██ ░██  ░██░██ ░██         
  //  ░██   ░██ ░██          ░██   ░██  ░██   ░████ ░██         
  //   ░██████  ░██████████   ░██████   ░██    ░███ ░██████████ 

  void _doOnCloneEntityGroupStart(Entity<T> copy, [EntityCloner<T>? cloner]) {
    if (copy is! EntityGroup<T, E>) throw StateError('unreachable');

    _doOnCloneEntityStart(copy, cloner);

    _entities.forEach((e) {
      if (!(cloner?.allowEntity(copy, e) ?? false)) return;
      copy.addEntity(e.clone(cloner));
    });
  }

  @override
  void _doOnClone(Entity<T> copy, [EntityCloner<T>? cloner]) {
    _doOnCloneEntityGroupStart(copy, cloner);
    super._doOnClone(copy, cloner);
  }

  //   ░██████   ░██     ░██ ░██████████ ░█████████  ░██     ░██ 
  //  ░██   ░██  ░██     ░██ ░██         ░██     ░██  ░██   ░██  
  // ░██     ░██ ░██     ░██ ░██         ░██     ░██   ░██ ░██   
  // ░██     ░██ ░██     ░██ ░█████████  ░█████████     ░████    
  // ░██     ░██ ░██     ░██ ░██         ░██   ░██       ░██     
  //  ░██   ░██   ░██   ░██  ░██         ░██    ░██      ░██     
  //   ░██████     ░██████   ░██████████ ░██     ░██     ░██     
  //        ░██                                                   

  /// Returns a fresh [QueryEntities] scoped to this entity group.
  ///
  /// Entry point for the **Query-like DSL**.
  QueryEntities<T, EntityGroup<T, E>> get QueryEntity => .new(app, self);
  
  /// Advances the group itself, then advances each member entity.
  /// Member updates are skipped when the group is disabled.
  @override
  void _doUpdate(double dt) {
    super._doUpdate(dt);
    if (isDisabled) return;
    _updateEntities(dt);
  }

  /// Draws the group itself, then draws each member entity.
  /// Member draws are skipped when the group is disabled.
  @override
  void _doDraw(double dt) {
    super._doDraw(dt);
    if (isDisabled) return;
    _drawEntities(dt);
  }

  /// Dispatches [event] to the group itself, then to each member entity.
  /// Propagation stops if [Event.isStopped] becomes `true` after the group.
  @override
  @nonVirtual
  void _doOnEvent(Event<T> event) {
    super._doOnEvent(event);
    if (event.isStopped) return;
    _entities.forEach((e) => e._doOnEvent(event));
  }

  @override
  bool addEntity(E entity) {
    if (!super.addEntity(entity)) return false;
    _ensureLocalPosition(entity);
    return true;
  }

  /// Reconciles the transform components of [entity] so that both a world
  /// [CTransform] and a [CLocalTransform] offset are always present.
  void _ensureLocalPosition(Entity<T> entity) {
    final worldPos = entity.get<CTransform<T>>();
    final localPos = entity.get<CLocalTransform<T>>();

    if (worldPos != null && localPos == null) {
      // user placed entity using world-style, convert to local
      final entityPosition = entity.transform!.position;
      final groupPosition = transform!.position;
      final offset = entityPosition.sub(groupPosition);
      entity.addComp(CLocalTransform<T>(app, offset: offset));
      return;
    }

    if (localPos != null && worldPos == null) {
      // user placed entity using local-style, create world transform
      final entityLocalPosition = localPos.offset;
      final groupPosition = transform!.position;
      final offset = groupPosition.add(entityLocalPosition);
      entity.addComp(CTransform<T>(app, position: offset));
      return;
    }

    // if has both: user knows what they're doing, leave it
    // if has neither: propagation system will just skip it
  }

  @override
  EntityGroup<T, E> createInstance() => .new(app);
}

abstract class EntityGroupSnapshot<T extends App<T>, E extends AnyEntityGroup<T>> extends StateSnapshot<T, E> {
  List<AnyEntitySnapshot<T>> entitySnapshots = [];

  EntityGroupSnapshot(super.namedId);

  @override
  E createInstance(T app) => AnyEntityGroup<T>(app) as E;

  void assignEntities(T app, E destination) {
    for (final snap in entitySnapshots) {
      destination.addEntity(snap.reconstruct(app));
    }
  }

  @override
  E reconstruct(T app);
}