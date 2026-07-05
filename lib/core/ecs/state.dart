part of '../raylib_dartified_unhinged.dart';

enum SnapshotMissingPolicy {
  /// Ignore snapshot entries that have no matching live origin.
  skip,

  /// Recreate the origin from its snapshot and re-add it to the parent.
  recreate,
}

enum SnapshotExtraPolicy {
  /// Leave live entries that aren't referenced by the snapshot untouched.
  keep,

  /// Remove live entries that aren't referenced by the snapshot.
  remove,
}

abstract class StateSnapshot<T extends App<T>, R> {
  late String sourceId;

  StateSnapshot(this.sourceId);

  SnapshotMissingPolicy onMissing = .skip;

  SnapshotExtraPolicy onExtra = .keep;

  /// User-faced, never called directly. See [reconstruct].
  R createInstance(T app);

  /// You call this directly.
  /// 
  /// Internal method utilizing [createInstance] and
  /// reconstructing internal (additional) stuff.
  R reconstruct(T app);
}

mixin IsStateHolder<
  T extends App<T>,
  E extends ECSBase<T>,
  S extends StateSnapshot<T, E>
> on ECSBase<T> {
  
  // ░██████░███     ░███ ░█████████  ░██         
  //   ░██  ░████   ░████ ░██     ░██ ░██         
  //   ░██  ░██░██ ░██░██ ░██     ░██ ░██         
  //   ░██  ░██ ░████ ░██ ░█████████  ░██         
  //   ░██  ░██  ░██  ░██ ░██         ░██         
  //   ░██  ░██       ░██ ░██         ░██         
  // ░██████░██       ░██ ░██         ░██████████ 
  
  final Map<String, S> _bookmarks = {};

  S createSnapshot();

  S captureSnapshot();

  X captureSnapshotAs<X extends S>() => captureSnapshot() as X;
  
  void restoreSnapshot(S snapshot);

  void _restoreSnapshotList<A extends ECSBase<T>, X extends StateSnapshot<T, A>>({
    required StateSnapshot<T, ECSBase<T>> originSnapshot,
    required List<A> sourceList,
    required List<X> sourceSnapshots,
    required Function(A) onRecreate,
    required Function(A, X) onRestore,
    required Function(A) onRemove,
  }) {
    final byId = {for (final c in sourceList) c.namedId: c};
    final restoredIds = <String>{};

    for (final snapshot in sourceSnapshots) {
      final origin = byId[snapshot.sourceId];

      if (origin == null) {
        switch (originSnapshot.onMissing) {
          case .skip:
            continue;
          case .recreate:
            final created = snapshot.createInstance(app);
            onRecreate(created);
            restoredIds.add(created.namedId);
        }
        continue;
      }

      restoredIds.add(origin.namedId);
      onRestore(origin, snapshot);
    }

    if (originSnapshot.onExtra == .remove) {
      final toRemove = sourceList
        .where((c) => !restoredIds.contains(c.namedId))
        .toList();

      toRemove.forEach(onRemove);
    }
  }

  S bookmarkState(String name) => _bookmarks[name] = captureSnapshot();
  
  void restoreBookmarkedState(String name, {
    SnapshotMissingPolicy onMissing = .skip,
    SnapshotExtraPolicy onExtra = .keep,
  }) {
    final snap = _bookmarks[name];
    if (snap != null) {
      snap.onMissing = onMissing;
      snap.onExtra = onExtra;
      restoreSnapshot(snap);
    }
  }
}

class _TimestampedSnapshot<T extends App<T>, E extends ECSBase<T>> {
  _TimestampedSnapshot(this.snapshot, this.simTime);
  final StateSnapshot<T, E> snapshot;
  final double simTime;
}

mixin IsPersistable<
  T extends App<T>,
  E extends IsStateHolder<T, E, StateSnapshot<T, E>>,
  S extends StateSnapshot<T, E>
> on IsStateHolder<T, E, S> {
  
  // ░██████░███     ░███ ░█████████  ░██         
  //   ░██  ░████   ░████ ░██     ░██ ░██         
  //   ░██  ░██░██ ░██░██ ░██     ░██ ░██         
  //   ░██  ░██ ░████ ░██ ░█████████  ░██         
  //   ░██  ░██  ░██  ░██ ░██         ░██         
  //   ░██  ░██       ░██ ░██         ░██         
  // ░██████░██       ░██ ░██         ░██████████ 

  String _getAutoSlotKey(int slot) => '_auto_$slot';

  final Map<String, _TimestampedSnapshot<T, E>> _savedSnapshots = {};

  double? _lastAutoSaveTime;
  int _autoSaveCounter = 0;

  S? persistAutoSave({
    required double interval,
    required int slots,
  }) {
    final double now = app.time.timeScaled;

    if (_lastAutoSaveTime != null && now - _lastAutoSaveTime! < interval) {
      return null;
    }

    final String key = _getAutoSlotKey(_autoSaveCounter % slots);
    final snap = captureSnapshotAs();
    _savedSnapshots[key] = _TimestampedSnapshot<T, E>(snap, now);

    _autoSaveCounter++;
    _lastAutoSaveTime = now;

    return snap;
  }

  void persistAutoLoad({
    int? slot,
  }) {
    if (_savedSnapshots.isEmpty) return;

    final _TimestampedSnapshot<T, E> target;

    if (slot != null) {
      final String key = _getAutoSlotKey(slot);
      final found = _savedSnapshots[key];
      if (found == null) return;
      target = found;
    } else {
      target = _savedSnapshots.values.reduce(
        (a, b) => a.simTime >= b.simTime ? a : b,
      );
    }

    restoreSnapshot(target.snapshot as S);
  }
}