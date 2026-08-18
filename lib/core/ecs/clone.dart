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

/// Identifies a category of internal state that may be copied during cloning.
///
/// Passed to [Cloner.allowState] so a [ClonePolicy] can selectively include
/// or exclude state categories from the cloned object.
// enum CloneStateType {
//   /// The object's identity fields (e.g. [ECSBase.id], [ECSBase.name]).
//   ///
//   /// Excluded by [DefaultPolicy], clones always receive their own identity.
//   identity,

//   /// The object's active/disabled state ([IsActivatable]).
//   active,

//   /// User-defined variables stored on the object ([HasVars]).
//   vars,

//   /// Event history state. ([IsEventHistoryHolder]).
//   eventHistory,

//   /// Event queue state. ([IsEventQueueHolder]).
//   eventQueue,

//   /// Callbackl queue state. ([IsCallbackProcessable]).
//   callbackQueue,

//   /// Groups ([QueryGroup]) within a [QueryComponentManagable].
//   queryGroups,

//   /// Source list within a [QueryComponentManagable].
//   querySourceList,

//   /// Pending task queue state. ([IsTaskProcessable]).
//   pendingTaskQueue,

//   /// Task queue state. ([IsTaskProcessable]).
//   taskQueue,
// }

/// Defines the allow/deny rules for a cloning operation.
///
/// Implement this to control which parts of an ECS object are copied during
/// cloning. The [allow] method is the single decision point, receiving a
/// [CloneKind] and optional [owner]/[payload] for context.
///
/// See [DefaultPolicy] for a permissive default, and [Cloner] for the typed
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
  bool allowAppSystem(T owner, AppSystem<T> appSystem)
    => allow(.appSystem, owner: owner, payload: appSystem);

  /// Whether [scene] should be included in the clone of [owner].
  bool allowScene(T owner, Scene<T> scene)
    => allow(.scene, owner: owner, payload: scene);

  /// Whether [sceneSystem] should be included in the clone of [owner].
  bool allowSceneSystem(Scene<T> owner, SceneSystem<T> sceneSystem)
    => allow(.sceneSystem, owner: owner, payload: sceneSystem);

  /// Whether [entity] should be included in the clone.
  bool allowEntity(IsAnyEntityManagable<T> owner, Entity<T> entity)
    => allow(.entity, owner: owner, payload: entity);

  /// Whether [comp] should be included in the clone of [owner].
  bool allowComp(IsAnyComponentManagable<T> owner, Comp<T> comp)
    => allow(.component, owner: owner, payload: comp);

  /// Whether the listener/s identified by [type] should be copied to the clone.
  bool allowHook(ECSBase<T> owner, ECSHookKey type)
    => allow(.hook, owner: owner, payload: type);

  /// Whether the state category identified by [type] should be copied to the clone.
  bool allowState(ECSBase<T> owner, ECSStateKey type)
    => allow(.state, owner: owner, payload: type);
}

/// A [ClonePolicy] that allows everything except [CloneStateType.identity].
///
/// Identity fields ([ECSBase.id], [ECSBase.namedId], [ECSBase.name]) are always
/// excluded so that clones receive their own auto-assigned identity rather than
/// sharing the origin's.
class DefaultPolicy<T extends App<T>> implements ClonePolicy<T> {
  const DefaultPolicy();

  @override
  bool allow(CloneKind kind, {ECSBase<T>? owner, Object? payload}) {
    if (kind == .state) {
      return payload != owner?.stateIdentityKey;
    }

    return true;
  }
}

/// A [Cloner] scoped to [Entity] cloning operations.
class EntityCloner<T extends App<T>> extends Cloner<T> {
  const EntityCloner(super.policy);

  /// Creates an [EntityCloner] using [DefaultPolicy], or a custom [policy].
  factory EntityCloner.Default([ClonePolicy<T>? policy])
    => .new(policy ?? DefaultPolicy<T>());
}

/// A [Cloner] scoped to [SceneSystem] cloning operations.
class SceneSystemCloner<T extends App<T>> extends Cloner<T> {
  const SceneSystemCloner(super.policy);

  /// Creates a [SceneSystemCloner] using [DefaultPolicy], or a custom [policy].
  factory SceneSystemCloner.Default([ClonePolicy<T>? policy])
    => .new(policy ?? DefaultPolicy<T>());
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

  /// Creates a [SceneCloner] using [DefaultPolicy] at all levels, or a custom [policy].
  factory SceneCloner.Default([ClonePolicy<T>? policy]) => .new(
    scenePolicy: policy ?? DefaultPolicy<T>(),
    entityCloner: .Default(policy),
    systemCloner: .Default(policy),
  );
}

/// A [Cloner] scoped to [AppSystem] cloning operations.
class AppSystemCloner<T extends App<T>> extends Cloner<T> {
  const AppSystemCloner({
    required ClonePolicy<T> systemPolicy,
  }) : super(systemPolicy);

  /// Creates an [AppSystemCloner] using [DefaultPolicy], or a custom [policy].
  factory AppSystemCloner.Default([ClonePolicy<T>? policy]) => .new(
    systemPolicy: policy ?? DefaultPolicy<T>(),
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

  /// Creates an [AppCloner] using [DefaultPolicy] at all levels, or a custom [policy].
  factory AppCloner.Default([ClonePolicy<T>? policy]) => .new(
    appPolicy: policy ?? DefaultPolicy<T>(),
    sceneCloner: .Default(policy),
    systemCloner: .Default(policy),
  );
}