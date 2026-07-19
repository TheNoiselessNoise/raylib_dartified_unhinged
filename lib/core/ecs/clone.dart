part of '../raylib_dartified_unhinged.dart';

/// Identifies the broad category of an ECS object being cloned.
///
/// Used by [ClonePolicy] to apply coarse-grained allow/deny rules before
/// the finer-grained [CloneHookType] and [CloneStateType] checks.
enum CloneKind {
  /// [AppSystem]
  appSystem,
  /// [Scene]
  scene,
  /// [SceneSystem]
  sceneSystem,
  /// [Entity]
  entity,
  /// [Comp]
  component,
  /// Any registered external hook.
  hook,
  /// Any object-specific internal state.
  state,
}

/// Identifies a specific listener/s that may be copied during cloning.
///
/// Passed to [Cloner.allowHook] so a [ClonePolicy] can selectively include
/// or exclude individual hook lists from the cloned object. Each value is
/// annotated with the mixin that owns it.
enum CloneHookType {
  // App-specific

  /// [App]
  shouldExit,
  /// [App]
  onFrame,
  /// [App]
  onFPSChange,
  /// [App]
  onInit,
  /// [App]
  onExit,

  // Scene-specific

  /// [Scene]
  onDrawBackground,
  /// [Scene]
  onDrawForeground,

  // IsActivatable

  /// [IsActivatable]
  onActivate,

  // IsAddable

  /// [IsAddable]
  onBeforeAdd,
  /// [IsAddable]
  onAdd,
  /// [IsAddable]
  onAfterAdd,

  // IsAppSystemManagable

  /// [IsAppSystemManagable]
  onBeforeAppSystemAdd,
  /// [IsAppSystemManagable]
  onAppSystemAdd,
  /// [IsAppSystemManagable]
  onAfterAppSystemAdd,
  /// [IsAppSystemManagable]
  onBeforeAppSystemRemove,
  /// [IsAppSystemManagable]
  onAppSystemRemove,
  /// [IsAppSystemManagable]
  onAfterAppSystemRemove,

  // IsBeginEndFrameable

  /// [IsBeginEndFrameable]
  onBeginFrame,
  /// [IsBeginEndFrameable]
  onEndFrame,

  // IsCancelable
  /// [IsCancelable]
  onBeforeCancel,
  /// [IsCancelable]
  onCancel,
  /// [IsCancelable]
  onAfterCancel,

  // IsClonable

  /// [IsClonable]
  onBeforeClone,
  /// [IsClonable]
  onClone,
  /// [IsClonable]
  onAfterClone,
  /// [IsClonable]
  whenOnClone,
  /// [IsClonable]
  whenOnCloned,
  /// [IsClonable]
  whenOnCreateInstance,

  // IsCollidable

  /// [IsCollidable]
  onBeforeCollision,
  /// [IsCollidable]
  onCollision,
  /// [IsCollidable]
  onAfterCollision,

  // IsCommandProcessable

  /// [IsCommandProcessable]
  onCommand,

  // IsComponentHostable

  /// [IsComponentManagable]
  onBeforeCompAdd,
  /// [IsComponentManagable]
  onCompAdd,
  /// [IsComponentManagable]
  onAfterCompAdd,
  /// [IsComponentManagable]
  onBeforeCompRemove,
  /// [IsComponentManagable]
  onCompRemove,
  /// [IsComponentManagable]
  onAfterCompRemove,
  /// [IsComponentManagable]
  onBeforeCompClone,
  /// [IsComponentManagable]
  onCompClone,
  /// [IsComponentManagable]
  onAfterCompClone,

  // IsDrawable

  /// [IsDrawable]
  onDraw,

  // IsEnterable

  /// [IsEnterable]
  onBeforeEnter,
  onEnter,
  onAfterEnter,

  // IsEntityManagable

  /// [IsEntityManagable]
  onBeforeEntityAdd,
  /// [IsEntityManagable]
  onEntityAdd,
  /// [IsEntityManagable]
  onAfterEntityAdd,
  /// [IsEntityManagable]
  onBeforeEntityRemove,
  /// [IsEntityManagable]
  onEntityRemove,
  /// [IsEntityManagable]
  onAfterEntityRemove,

  // IsEventEmittable

  /// [IsEventEmittable]
  onBeforeEvent,
  /// [IsEventEmittable]
  onEvent,

  // IsEventHistoryHolder

  /// [IsEventHistoryHolder]
  onBeforeEventRecorded,
  /// [IsEventHistoryHolder]
  onEventRecorded,

  // IsInputHandleable

  /// [IsInputHandleable]
  onHandleInput,

  // IsLeavable

  /// [IsLeavable]
  onBeforeLeave,
  onLeave,
  onAfterLeave,

  // IsDisposable

  /// [IsDisposable]
  onDispose,

  // IsPersistable

  /// [IsPersistable]
  onBeforeStorePersistable,
  /// [IsPersistable]
  onStorePersistable,

  // IsPrePostDrawable

  /// [IsPrePostDrawable]
  onPreDraw,
  /// [IsPrePostDrawable]
  onPostDraw,

  // IsPrePostUpdatable

  /// [IsPrePostUpdatable]
  onPreUpdate,
  /// [IsPrePostUpdatable]
  onPostUpdate,

  // IsRemovable

  /// [IsRemovable]
  onBeforeRemove,
  /// [IsRemovable]
  onRemove,
  /// [IsRemovable]
  onAfterRemove,

  // IsSceneManagable

  /// [IsSceneManagable]
  onBeforeSceneAdd,
  /// [IsSceneManagable]
  onSceneAdd,
  /// [IsSceneManagable]
  onAfterSceneAdd,
  /// [IsSceneManagable]
  onBeforeSceneRemove,
  /// [IsSceneManagable]
  onSceneRemove,
  /// [IsSceneManagable]
  onAfterSceneRemove,

  // IsSceneSystemManagable

  /// [IsSceneSystemManagable]
  onBeforeSceneSystemAdd,
  /// [IsSceneSystemManagable]
  onSceneSystemAdd,
  /// [IsSceneSystemManagable]
  onAfterSceneSystemAdd,
  /// [IsSceneSystemManagable]
  onBeforeSceneSystemRemove,
  /// [IsSceneSystemManagable]
  onSceneSystemRemove,
  /// [IsSceneSystemManagable]
  onAfterSceneSystemRemove,

  // IsSceneTransitionable

  /// [IsSceneTransitionable]
  onBeforeSceneEnter,
  /// [IsSceneTransitionable]
  onSceneEnter,
  /// [IsSceneTransitionable]
  onAfterSceneEnter,
  /// [IsSceneTransitionable]
  onBeforeSceneLeave,
  /// [IsSceneTransitionable]
  onSceneLeave,
  /// [IsSceneTransitionable]
  onAfterSceneLeave,
  /// [IsSceneTransitionable]
  onBeforeSceneTransition,
  /// [IsSceneTransitionable]
  onSceneTransition,
  /// [IsSceneTransitionable]
  onAfterSceneTransition,

  // IsStartable

  /// [IsStartable]
  onStart,

  // IsTaskProcessable

  /// [IsTaskProcessable]
  onTask,

  // IsUpdatable

  /// [IsUpdatable]
  onUpdate,
}

/// Identifies a category of internal state that may be copied during cloning.
///
/// Passed to [Cloner.allowState] so a [ClonePolicy] can selectively include
/// or exclude state categories from the cloned object.
enum CloneStateType {
  /// The object's identity fields (e.g. [ECSBase.id], [ECSBase.name]).
  ///
  /// Excluded by [AllowAllPolicy], clones always receive their own identity.
  identity,

  /// The object's active/disabled state ([IsActivatable]).
  active,

  /// User-defined variables stored on the object ([HasVars]).
  vars,

  /// Event history state. ([IsEventHistoryHolder]).
  eventHistory,

  /// Event queue state. ([IsEventQueueHolder]).
  eventQueue,

  /// Callbackl queue state. ([IsCallbackProcessable]).
  callbackQueue,

  /// Command queue state. ([IsCommandProcessable]).
  commandQueue,

  /// Groups ([QueryGroup]) within a [QueryComponentManagable].
  queryGroups,

  /// Source list within a [QueryComponentManagable].
  querySourceList,

  /// Pending task queue state. ([IsTaskProcessable]).
  pendingTaskQueue,

  /// Task queue state. ([IsTaskProcessable]).
  taskQueue,
}

/// Defines the allow/deny rules for a cloning operation.
///
/// Implement this to control which parts of an ECS object are copied during
/// cloning. The [allow] method is the single decision point, receiving a
/// [CloneKind] and optional [owner]/[payload] for context.
///
/// See [AllowAllPolicy] for a permissive default, and [Cloner] for the typed
/// helper methods that delegate to this policy.
abstract class ClonePolicy<T extends App<T>> {
  bool allow(
    CloneKind kind, {
    ECSBase<T>? owner,
    Object? payload,
  });
}

/// Applies a [ClonePolicy] to a cloning operation with typed convenience methods.
///
/// Each `allow*` method translates a specific cloning decision into a
/// [ClonePolicy.allow] call with the appropriate [CloneKind] and payload.
/// Concrete subclasses ([EntityCloner], [SceneCloner], etc.) scope the cloner
/// to a specific ECS object type and may carry nested cloners for child objects.
abstract class Cloner<T extends App<T>> {
  final ClonePolicy<T> policy;
  const Cloner(this.policy);

  /// Delegates to [policy] with the given [kind], [owner], and [payload].
  bool allow(
    CloneKind kind, {
    ECSBase<T>? owner,
    Object? payload,
  }) => policy.allow(kind, owner: owner, payload: payload);

  /// Whether [appSystem] should be included in the clone of [owner].
  bool allowAppSystem(App<T> owner, AppSystem<T> appSystem)
    => allow(.appSystem, owner: owner, payload: appSystem);

  /// Whether [scene] should be included in the clone of [owner].
  bool allowScene(App<T> owner, Scene<T> scene)
    => allow(.scene, owner: owner, payload: scene);

  /// Whether [sceneSystem] should be included in the clone of [owner].
  bool allowSceneSystem(Scene<T> owner, SceneSystem<T> sceneSystem)
    => allow(.sceneSystem, owner: owner, payload: sceneSystem);

  /// Whether [entity] should be included in the clone.
  bool allowEntity(IsEntityManagable<T, ECSBase<T>, Entity<T>> owner, Entity<T> entity)
    => allow(.entity, owner: owner, payload: entity);

  /// Whether [comp] should be included in the clone of [owner].
  bool allowComp(IsComponentManagable<T, ECSBase<T>> owner, Comp<T> comp)
    => allow(.component, owner: owner, payload: comp);

  /// Whether the listener/s identified by [type] should be copied to the clone.
  bool allowHook(ECSBase<T> owner, CloneHookType type)
    => allow(.hook, owner: owner, payload: type);

  /// Whether the state category identified by [type] should be copied to the clone.
  bool allowState(ECSBase<T> owner, CloneStateType type)
    => allow(.state, owner: owner, payload: type);
}

/// A [ClonePolicy] that allows everything except [CloneStateType.identity].
///
/// Identity fields ([ECSBase.id], [ECSBase.namedId], [ECSBase.name]) are always
/// excluded so that clones receive their own auto-assigned identity rather than
/// sharing the origin's.
class AllowAllPolicy<T extends App<T>> implements ClonePolicy<T> {
  const AllowAllPolicy();

  @override
  bool allow(CloneKind kind, {ECSBase<T>? owner, Object? payload})
    => payload != CloneStateType.identity;
}

/// A [Cloner] scoped to [Entity] cloning operations.
class EntityCloner<T extends App<T>> extends Cloner<T> {
  const EntityCloner(super.policy);

  /// Creates an [EntityCloner] using [AllowAllPolicy], or a custom [policy].
  factory EntityCloner.AllowAll([ClonePolicy<T>? policy])
    => .new(policy ?? AllowAllPolicy<T>());
}

/// A [Cloner] scoped to [SceneSystem] cloning operations.
class SceneSystemCloner<T extends App<T>> extends Cloner<T> {
  const SceneSystemCloner(super.policy);

  /// Creates a [SceneSystemCloner] using [AllowAllPolicy], or a custom [policy].
  factory SceneSystemCloner.AllowAll([ClonePolicy<T>? policy])
    => .new(policy ?? AllowAllPolicy<T>());
}

/// A [Cloner] scoped to [Scene] cloning operations.
///
/// Carries nested cloners for the entities and scene systems owned by the scene,
/// allowing independent policies at each level of the hierarchy.
class SceneCloner<T extends App<T>> extends Cloner<T> {
  /// The cloner applied to each [Entity] within the scene.
  final EntityCloner<T> entityCloner;

  /// The cloner applied to each [SceneSystem] within the scene.
  final SceneSystemCloner<T> systemCloner;

  const SceneCloner({
    required ClonePolicy<T> scenePolicy,
    required this.entityCloner,
    required this.systemCloner,
  }) : super(scenePolicy);

  /// Creates a [SceneCloner] using [AllowAllPolicy] at all levels, or a custom [policy].
  factory SceneCloner.AllowAll([ClonePolicy<T>? policy]) => .new(
    scenePolicy: policy ?? AllowAllPolicy<T>(),
    entityCloner: .AllowAll(policy),
    systemCloner: .AllowAll(policy),
  );
}

/// A [Cloner] scoped to [AppSystem] cloning operations.
class AppSystemCloner<T extends App<T>> extends Cloner<T> {
  const AppSystemCloner({
    required ClonePolicy<T> systemPolicy,
  }) : super(systemPolicy);

  /// Creates an [AppSystemCloner] using [AllowAllPolicy], or a custom [policy].
  factory AppSystemCloner.AllowAll([ClonePolicy<T>? policy]) => .new(
    systemPolicy: policy ?? AllowAllPolicy<T>(),
  );
}

/// A [Cloner] scoped to [App] cloning operations.
///
/// Carries nested cloners for the scenes and app systems owned by the app,
/// allowing independent policies at each level of the hierarchy.
class AppCloner<T extends App<T>> extends Cloner<T> {
  /// The cloner applied to each [Scene] within the app.
  final SceneCloner<T> sceneCloner;

  /// The cloner applied to each [AppSystem] within the app.
  final AppSystemCloner<T> systemCloner;

  const AppCloner({
    required ClonePolicy<T> appPolicy,
    required this.sceneCloner,
    required this.systemCloner,
  }) : super(appPolicy);

  /// Creates an [AppCloner] using [AllowAllPolicy] at all levels, or a custom [policy].
  factory AppCloner.AllowAll([ClonePolicy<T>? policy]) => .new(
    appPolicy: policy ?? AllowAllPolicy<T>(),
    sceneCloner: .AllowAll(policy),
    systemCloner: .AllowAll(policy),
  );
}