// Run it: dart run test_state.dart
import '_base.dart';

class MyComponent extends Comp<G> {
  int compField;

  MyComponent(super.app, {
    required this.compField,
  });

// NOTE: this is optional, only for custom state `compField`
  @override
  MyComponentSnapshot createSnapshot() => .new(id, compField);

// NOTE: this is optional, only for custom state `compField`
  @override
  void restoreSnapshot(MyComponentSnapshot snapshot) {
    super.restoreSnapshot(snapshot);
    compField = snapshot.compField;
  }
}

// NOTE: this is optional, only for custom state `compField`
class MyComponentSnapshot extends CompSnapshot<G, MyComponent> {
  int compField;

  MyComponentSnapshot(super.namedId, this.compField);

  @override
  MyComponent createInstance(G app) => .new(app,
    compField: compField,
  );
}

class MyEntity extends Entity<G> {
  int entityField;

  late MyComponent comp;

  MyEntity(super.app, {
    required this.entityField
  }) {
    addComp(CTransform(app, position: screenSize.divideBy(2)));
    addComp(CRectCollider(app, size: .vec2(64, 64), debugDraw: true, debugColor: .GREEN));
    addComp(comp = MyComponent(app, compField: 420));
  } 

  // NOTE: this is optional, only for custom state `entityField`
  @override
  MyEntitySnapshot createSnapshot() => .new(id, entityField);

  // NOTE: this is optional, only for custom state `entityField`
  @override
  void restoreSnapshot(MyEntitySnapshot snapshot) {
    super.restoreSnapshot(snapshot);
    entityField = snapshot.entityField;
  }
}

// NOTE: this is optional, only for custom state `entityField`
class MyEntitySnapshot extends EntitySnapshot<G, MyEntity> {
  int entityField;

  MyEntitySnapshot(super.namedId, this.entityField);

  @override
  MyEntity createInstance(G app) => .new(app,
    entityField: entityField,
  );
}

class TestStateScene extends DrawScene<G> {
  late MyEntity myEntity;

  TestStateScene(super.app) {
    addEntity(myEntity = MyEntity(app, entityField: 69));
  }

  final List<AnySceneSnapshot<G>> snapshots = [];
  int snapIndex = 0;

  @override
  void onInput() {
    // NOTE: Upon restoring a snapshot you should see these changes:
    //       - `MyEntity.entityField`
    //       - `MyComponent.compField`
    //       - MyEntity's hopping to stored position due to `CTransform` component
    if (rl.CoreD.IsKeyPressed(.KEY_SPACE)) restoreSnapshot(snapshots[snapIndex]);
    if (rl.CoreD.IsKeyPressed(.KEY_LEFT)) snapIndex = --snapIndex % snapshots.length;
    if (rl.CoreD.IsKeyPressed(.KEY_RIGHT)) snapIndex = ++snapIndex % snapshots.length;

    // change some state
    if (rl.CoreD.IsKeyDown(.KEY_UP)) myEntity.comp.compField++;
    if (rl.CoreD.IsKeyDown(.KEY_DOWN)) myEntity.comp.compField--;
    if (rl.CoreD.IsKeyDown(.KEY_W)) myEntity.entityField++;
    if (rl.CoreD.IsKeyDown(.KEY_S)) myEntity.entityField--;
    if (rl.CoreD.IsKeyDown(.KEY_A)) myEntity.transform!.position.x--;
    if (rl.CoreD.IsKeyDown(.KEY_D)) myEntity.transform!.position.x++;
  }

  @override
  void onDraw(double dt) {
    rl.CoreD.DrawText('MyEntity.entityField: ${myEntity.entityField}', 10, 10, 20, .WHITE);
    rl.CoreD.DrawText('MyComponent.compField: ${myEntity.comp.compField}', 10, 30, 20, .WHITE);
    rl.CoreD.DrawText('Snapshots: ${snapshots.length} (selected: $snapIndex)', 10, 70, 20, .WHITE);

    final lastSnapshotEntityPosition = snapshots.lastOrNull
      // we know there's `MyEntity`
      ?.entitySnapshots.first
      // we know there's CTransform component
      .componentSnapshots.whereType<CTransformSnapshot<G>>().first
      // just get the `position` from the snapshot
      .position;

    if (lastSnapshotEntityPosition != null) {
      rl.CoreD.DrawText('last snap transform: $lastSnapshotEntityPosition', 10, 90, 20, .WHITE);
    } else {
      rl.CoreD.DrawText('last snap transform: (none)', 10, 90, 20, .WHITE);
    }

    rl.CoreD.DrawText('Press [SPACE] to restore selected snapshot', 10, screenHeight - 30, 20, .WHITE);
  }

  @override
  void onEndFrame(double dt) {
    final snapshot = persistAutoSave(interval: 3, slots: 5);
    if (snapshot != null) snapshots.add(snapshot);
  }

  @override
  TestStateScene createInstance() => .new(app);
}

typedef G = TestStateApp;

class TestStateApp extends ExampleRaylibApp<G> {
  TestStateApp(super.backend);

  @override
  void onInit() {
    rl.CoreD.InitWindow(screenWidth, screenHeight, "test_state");
    rl.CoreD.SetWindowMonitor(0);
    rl.CoreD.SetTargetFPS(60);
    addScene(TestStateScene(app));
  }

  @override
  void onEndFrame(double dt) {
    // NOTE: whole `TestStateApp` state every 3 seconds saving up to 5 oldest ones
    //       (it can be null, because the interval wasn't hit)
    // final snapshot = persistAutoSave(interval: 3, slots: 5);

    // NOTE: capture whole `TestStateApp` state directly here
    // final snapshot = captureSnapshot();
  }

  @override
  TestStateApp createInstance() => .new(backend);
}

void main() => runExample((backend) => G(backend));
