part of '../raylib_dartified_unhinged.dart';

/// Per-type monotonic ID counter, used by [ECSBase] to assign unique IDs.
class _GlobalIdCounter {
  static final Map<Type, int> _counters = {};

  /// Returns the next ID for [type], incrementing its counter.
  static int nextIdForType(Type type)
    => _counters[type] = _counters.putIfAbsent(type, () => 0) + 1;
}

/// Base class for all ECS objects.
///
/// Provides a per-type auto-incrementing [id] and a default [name] derived from it
/// and an optional [parent] reference for tree traversal.
abstract class ECSBase<T extends App<T>> with HasAppAccess<T> {
  /// See [id].
  late final int _id;

  /// Per-type unique identifier, auto-assigned in the constructor.
  int get id => _id;

  /// See [namedId].
  late final String _namedId;

  /// Per-type unique String identifier, auto-assigned in the constructor.
  /// Defaults to `RuntimeType_id`.
  String get namedId => _namedId;

  /// Human-readable name, defaults to `RuntimeType_id`.
  late String name;

  /// Returns a key namespaced to this object's [namedId].
  ///
  /// Useful for storing per-instance data in a flat map without collisions.
  String uniqKey(String key) => '$_namedId.$key';

  ECSBase() {
    _id = _GlobalIdCounter.nextIdForType(runtimeType);
    _namedId = '${runtimeType}_$id';
    name = _namedId;
  }

  /// The parent object in the ECS tree, if any.
  ECSBase<T>? parent;

  /// Whether [parent] is of type [P].
  bool hasParentOf<P extends ECSBase<T>>() => parent is P;

  /// Returns [parent] cast to [P], or `null` if the cast would fail.
  P? getParentAs<P extends ECSBase<T>>() => parent is P ? parent as P : null;

  /// Returns the depth/level in the hierarchy.
  int getDepth() {
    int depth = 0;
    var current = parent;
    while (current != null) {
      depth++;
      current = current.parent;
    }
    return depth;
  }

  /// Returns the path from the root down to this one, inclusive.
  List<ECSBase<T>> getPath() {
    List<ECSBase<T>> path = [];
    ECSBase<T>? current = this;
    while (current != null) {
      path.insert(0, current);
      final parent = current.parent;
      if (parent != this) {
        current = parent;
      } else {
        break;
      }
    }
    return path;
  }

  /// Returns every ancestor of this component, from immediate parent up to the root.
  Iterable<ECSBase<T>> getAncestors() {
    List<ECSBase<T>> ancestors = [];
    var current = parent;
    while (current != null) {
      ancestors.add(current);
      current = current.parent;
    }
    return ancestors;
  }

  @override
  String toString() => '$runtimeType(id=$id)';
}

class VarKey<T> {
  final String name;
  
  const VarKey(this.name);
}

mixin HasVars<T extends App<T>, E extends ECSBase<T>> on Self<E> {
  Map<VarKey<dynamic>, dynamic> _vars = {};

  V getVar<V>(VarKey<V> key) => _vars[key] as V;

  V getVarSafe<V>(VarKey<V> key, V fallback)
    => _vars[key] is V ? _vars[key] as V : fallback;

  bool hasVar(VarKey key) => _vars.containsKey(key);

  V incVar<V extends num>(VarKey<V> key, [V? amount]) {
    final value = getVar(key);
    final next = (value + (amount ?? 1)) as V;
    setVar(key, next);
    return next;
  }

  V decVar<V extends num>(VarKey<V> key, [V? amount]) {
    final value = getVar(key);
    final next = (value + (amount ?? 1)) as V;
    setVar(key, next);
    return next;
  }

  E setVar<V>(VarKey<V> key, V value) {
    _vars[key] = value;
    return self;
  }

  V getOrSetVar<V>(VarKey<V> key, V fallback) {
    if (_vars.containsKey(key)) return getVar(key);
    setVar(key, fallback);
    return fallback;
  }
}

class Bounds {
  double top;
  double left;
  double bottom;
  double right;

  Bounds(this.top, this.left, this.bottom, this.right);

  double get width => (right - left).abs();
  double get height => (bottom - top).abs();

  factory Bounds.zero() => .new(0, 0, 0, 0);

  factory Bounds.bounds(num top, num left, num bottom, num right) => .new(
    top.toDouble(),
    left.toDouble(),
    bottom.toDouble(),
    right.toDouble(),
  );

  factory Bounds.fromRectangle(RectangleD rect) => .new(
    rect.y, // top
    rect.x, // left
    rect.y + rect.height, // bottom
    rect.x + rect.width, // right
  );

  Bounds set(num top, num left, num bottom, num right) {
    this.top = top.toDouble();
    this.left = left.toDouble();
    this.bottom = bottom.toDouble();
    this.right = right.toDouble();
    return this;
  }

  Vector2D get position => .vec2(left, top);

  Vector2D get size => .vec2(width, height);
  
  RectangleD get rectangle => .rect(left, top, width, height);

  @override
  String toString() => '$runtimeType(top=$top, left=$left, bottom=$bottom, right=$right)';

  Bounds copy() => .new(top, left, bottom, right);
}

abstract class UnhingedRaylibGame<T extends App<T>> extends RaylibGame {
  late T app;

  T create(RaylibBackend backend);

  @override
  void init(Raylib rl) => app = create(.new(rl))..init();

  @override
  bool shouldClose(Raylib rl) => app.shouldAppExit;

  @override
  void loop(Raylib rl) => app.frame();

  @override
  void close(Raylib rl) => app.exit();

  @override
  void dispose(Raylib rl) {}
}