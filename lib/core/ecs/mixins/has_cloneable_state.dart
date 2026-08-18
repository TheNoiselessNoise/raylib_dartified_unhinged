part of '../../raylib_dartified_unhinged.dart';

/// Single key to state storage.
final class ECSStateKey<S> {
  final String family;
  final String name;
  final S Function()? get;
  final void Function(S)? set;

  const ECSStateKey(this.family, this.name, {
    this.get,
    this.set,
  });

  void copyFrom(ECSStateKey<S> other) {
    if (set == null && other.get == null) return;
    if (set != null && other.get == null) throw StateError("Key '$fullId' is missing a getter.");
    if (set == null && other.get != null) throw StateError("Key '$fullId' is missing a setter.");
    set!(other.get!());
  }

  String get fullId => '$family.$name';

  @override
  bool operator ==(Object other)
    => other is ECSStateKey<S> && other.fullId == fullId;

  @override
  int get hashCode => Object.hash(S, fullId);

  @override
  String toString() => fullId;
}

final class ECSStateTagKey extends ECSStateKey<void> {
  ECSStateTagKey(super.family, super.name);
}

mixin HasCloneableState<T extends App<T>> {
  final Map<ECSStateKey, ECSStateKey> _cloneableStates = {};

  Map<ECSStateKey, ECSStateKey> get devTestCloneableStates => _cloneableStates;

  @mustCallSuper
  void _registerBuiltinStateKeys() {}

  void registerStateKey<S>(ECSStateKey<S> key)
    => _cloneableStates[key] = key;

  void _copyStateTo(HasCloneableState<T> target, bool Function(ECSStateKey) allowed) {
    _cloneableStates.forEach((key, desc) {
      final targetDesc = target._cloneableStates[key];
      if (allowed(key) && targetDesc != null) {
        targetDesc.copyFrom(desc);
      }
    });
  }
}