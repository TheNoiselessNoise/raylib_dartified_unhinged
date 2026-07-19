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

typedef AnyStateSnapshot<T extends App<T>> = StateSnapshot<T, ECSBase<T>>;

abstract class StateSnapshot<T extends App<T>, E extends ECSBase<T>> {
  late int sourceId;

  StateSnapshot(this.sourceId);

  SnapshotMissingPolicy onMissing = .skip;

  SnapshotExtraPolicy onExtra = .keep;

  /// Bare instance.
  E createInstance(T app);
}

mixin IsStateHolderBase<T extends App<T>> on ECSBase<T> {
  AnyStateSnapshot<T> createSnapshot();

  AnyStateSnapshot<T> captureSnapshot();
  
  void restoreSnapshot(covariant AnyStateSnapshot<T> snapshot);

  AnyStateSnapshot<T> bookmarkState(String name);
  
  void restoreBookmarkedState(String name, {
    SnapshotMissingPolicy onMissing = .skip,
    SnapshotExtraPolicy onExtra = .keep,
  });
}

typedef IsAnyStateHolder<T extends App<T>> = IsStateHolderBase<T>;

mixin IsStateHolder<
  T extends App<T>,
  E extends IsStateHolder<T, E, S>,
  S extends StateSnapshot<T, E>
> on ECSBase<T> implements IsStateHolderBase<T> {
  
  // ░██████░███     ░███ ░█████████  ░██         
  //   ░██  ░████   ░████ ░██     ░██ ░██         
  //   ░██  ░██░██ ░██░██ ░██     ░██ ░██         
  //   ░██  ░██ ░████ ░██ ░█████████  ░██         
  //   ░██  ░██  ░██  ░██ ░██         ░██         
  //   ░██  ░██       ░██ ░██         ░██         
  // ░██████░██       ░██ ░██         ░██████████ 
  
  final Map<String, S> _bookmarks = {};

  @override
  S createSnapshot();

  @override
  S captureSnapshot();

  X captureSnapshotAs<X extends S>() => captureSnapshot() as X;
  
  @override
  void restoreSnapshot(S snapshot);

  void _restoreSnapshotList<
    A extends IsAnyStateHolder<T>,
    X extends StateSnapshot<T, IsAnyStateHolder<T>>
  >({
    required AnyStateSnapshot<T> originSnapshot,
    required List<A> sourceList,
    required List<X> sourceSnapshots,
    required void Function(A) onRecreate,
    required void Function(A, X) onRestore,
    required void Function(A) onRemove,
  }) {
    final byId = {for (final c in sourceList) c.id: c};
    final restoredIds = <int>{};

    for (final snapshot in sourceSnapshots) {
      final origin = byId[snapshot.sourceId];

      if (origin == null) {
        switch (originSnapshot.onMissing) {
          case .skip:
            continue;
          case .recreate:
            final created = snapshot.createInstance(app);
            created.restoreSnapshot(snapshot);
            onRecreate(created as A);
            restoredIds.add(created.id);
        }
        continue;
      }

      restoredIds.add(origin.id);
      onRestore(origin, snapshot);
    }

    if (originSnapshot.onExtra == .remove) {
      final toRemove = sourceList
        .where((c) => !restoredIds.contains(c.id))
        .toList();

      toRemove.forEach(onRemove);
    }
  }

  @override
  S bookmarkState(String name) => _bookmarks[name] = captureSnapshot();
  
  @override
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

class _TimestampedSnapshot<
  T extends App<T>,
  E extends ECSBase<T>,
  S extends StateSnapshot<T, E>
> {
  _TimestampedSnapshot(this.snapshot, this.simTime);
  final S snapshot;
  final double simTime;
}

mixin IsPersistableBase<T extends App<T>, E extends ECSBase<T>> on ECSBase<T> {
  abstract List<bool Function(E self)> _onBeforeStorePersistableFns;
  
  abstract List<MapData Function(E self, MapData data)> _onStorePersistableFns;

  MapData? storePersistable();

  AnyStateSnapshot<T>? persistAutoSave({
    required double interval,
    required int slots,
  });

  void persistAutoLoad({
    int? slot,
  });

  String get persistentId;
  set persistentId(String value);

  String get persistentTypeId;

  MapData getPersistableData({bool force = false});

  @mustCallSuper
  void restorePersistableData(MapTraversable data, {String? id});
}

typedef IsAnyPersistable<T extends App<T>> = IsPersistableBase<T, ECSBase<T>>;

mixin IsPersistable<
  T extends App<T>,
  E extends IsPersistable<T, E, S>,
  S extends StateSnapshot<T, E>
> on Self<E>, IsStateHolder<T, E, S> implements IsPersistableBase<T, E> {

  // ░██     ░██   ░██████     ░██████   ░██     ░██   ░██████   
  // ░██     ░██  ░██   ░██   ░██   ░██  ░██    ░██   ░██   ░██  
  // ░██     ░██ ░██     ░██ ░██     ░██ ░██   ░██   ░██         
  // ░██████████ ░██     ░██ ░██     ░██ ░███████     ░████████  
  // ░██     ░██ ░██     ░██ ░██     ░██ ░██   ░██           ░██ 
  // ░██     ░██  ░██   ░██   ░██   ░██  ░██    ░██   ░██   ░██  
  // ░██     ░██   ░██████     ░██████   ░██     ░██   ░██████   

  // NOTE: no `listen` hook available for `onRestorePersistableData`,
  //       since it happens only at new instance creation

  /// Override to react during the restoration of persistable data.
  void onRestorePersistableData(MapTraversable data, {String? id}) {}

  @override
  List<bool Function(E self)> _onBeforeStorePersistableFns = [];
  
  @override
  List<MapData Function(E self, MapData data)> _onStorePersistableFns = [];

  /// Registers [fn] as a before-persistence listener.
  ///
  /// [fn] returning `false` cancels the persistence.
  @nonVirtual
  E listenOnBeforeStorePersistable(bool Function(E self) fn) {
    _onBeforeStorePersistableFns.add(fn);
    return self;
  }

  /// Registers [fn] as an store persistable listener.
  ///
  /// Called when the persistence is about to happen and was not canceled.
  @nonVirtual
  E listenOnStorePersistable(MapData Function(E self, MapData data) fn) {
    _onStorePersistableFns.add(fn);
    return self;
  }

  /// Runs all before-persistence listeners and [onBeforeStorePersistable].
  ///
  /// Returns `false` if any listener or the override cancels the persistence.
  bool _doOnBeforeStorePersistable() {
    if (!_onBeforeStorePersistableFns.every((f) => f(self))) return false;
    return onBeforeStorePersistable();
  }

  /// Runs all persistence listeners and [onStorePersistable].
  MapData _doOnStorePersistable(MapData data) {
    for (final f in _onStorePersistableFns) {
      data = f(self, data);
    }
    return onStorePersistable(data);
  }

  /// Override to cancel the persistence from within the class.
  ///
  /// Return `false` to abort. Called after all registered [listenOnBeforeStorePersistable] listeners.
  bool onBeforeStorePersistable() => true;

  /// Override to react when the persistence is about to complete.
  ///
  /// Called after all registered [listenOnStorePersistable] listeners.
  MapData onStorePersistable(MapData data) => data;

  @override
  MapData? storePersistable() {
    if (!_doOnBeforeStorePersistable()) return null;
    return _doOnStorePersistable(getPersistableData());
  }

  // ░██████░███     ░███ ░█████████  ░██         
  //   ░██  ░████   ░████ ░██     ░██ ░██         
  //   ░██  ░██░██ ░██░██ ░██     ░██ ░██         
  //   ░██  ░██ ░████ ░██ ░█████████  ░██         
  //   ░██  ░██  ░██  ░██ ░██         ░██         
  //   ░██  ░██       ░██ ░██         ░██         
  // ░██████░██       ░██ ░██         ░██████████ 

  bool populateDefaults = true;
  
  String _getAutoSlotKey(int slot) => '_auto_$slot';

  final Map<String, _TimestampedSnapshot<T, E, S>> _savedSnapshots = {};

  double? _lastAutoSaveTime;
  int _autoSaveCounter = 0;

  @override
  S? persistAutoSave({
    required double interval,
    required int slots,
  }) {
    final double now = app.time.timeScaled;

    if (_lastAutoSaveTime != null && now - _lastAutoSaveTime! < interval) {
      return null;
    }

    final String key = _getAutoSlotKey(_autoSaveCounter % slots);
    final snap = captureSnapshot();
    _savedSnapshots[key] = .new(snap, now);

    _autoSaveCounter++;
    _lastAutoSaveTime = now;

    return snap;
  }

  @override
  void persistAutoLoad({
    int? slot,
  }) {
    if (_savedSnapshots.isEmpty) return;

    final _TimestampedSnapshot<T, E, S> target;

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

    restoreSnapshot(target.snapshot);
  }

  late String _persistentId = Uuid().v4();

  @override
  String get persistentId => _persistentId;

  @override
  set persistentId(String value) => _persistentId = value;

  @override
  String get persistentTypeId;

  @override
  @mustCallSuper
  MapData getPersistableData({bool force = false}) => {
    ECSPersistentKeys.id: persistentId,
    ECSPersistentKeys.type: persistentTypeId,
  };

  @override
  @mustCallSuper
  void restorePersistableData(MapTraversable data, {String? id}) {
    final extractedId = data.getStringOrNull(ECSPersistentKeys.id, id);
    if (extractedId != null) persistentId = extractedId;
  }

  MapData _storePersistableJsonObjectMap<A extends IsAnyPersistable<T>>(Iterable<A> list, {
    bool force = false,
  }) {
    final MapData jsonData = {};

    for (final instance in list) {
      MapData? instanceData;
      if (force) instanceData = instance.getPersistableData(force: force);
      else instanceData = instance.storePersistable();
      
      if (instanceData == null) continue;
      jsonData[instance.persistentId] = instanceData;
    }

    return jsonData;
  }

  void _restorePersistableJsonObjectMap<A extends ECSBase<T>>({
    required MapTraversable data,
    required String key,
    required ECSBaseFactoryRegistry<T, A> factory,
    required void Function(A) onRestored,
  }) {
    final listData = data.getMapTraversable<MapData>(key);

    for (final entry in listData.entries) {
      final MapTraversable objData = .new(entry.value);
      final typeId = objData.getString(ECSPersistentKeys.type);
      final instance = factory.create(typeId, app);

      if (instance is! IsAnyPersistable<T>) {
        throw StateError("Tried to instantiate $A, but it's not persistable.");
      }

      instance.restorePersistableData(objData, id: entry.key);
      onRestored(instance);
    }
  }
}

class ECSPersistentKeys {
  static final String appSystems = '__appSystems__';
  static final String scenes = '__scenes__';
  static final String sceneSystems = '__sceneSystems__';
  static final String entities = '__entities__';
  static final String components = '__components__';

  // fields
  static final String id = '__id__';
  static final String type = '__type__';
}