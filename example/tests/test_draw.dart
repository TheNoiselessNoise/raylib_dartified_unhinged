// Run it: dart run test_draw.dart
import '_base.dart';

class Comp1 extends Comp<G> {
  // INVARIANT: a component can only addComp() children once its own `entity`/parent
  // field has been set, and that field is set by addComp() itself, partway through
  // attaching this component to its parent. So "can I add children yet?" is really
  // "has addComp() already run on me?" Two consequences below.

  Comp1(super.app) {
    // 1) Not yet, here: the constructor runs *before* addComp() is ever called on this
    //    instance, so `entity` is still unset.
    //
    //    This throws: LateInitializationError: Field 'entity' has not been initialized.
    //    addComp(Comp2(app));
  }

  @override
  void onAdd(ECSBase<G> parent) {
    // 2) Not yet, inline, here either: by the time onAdd() runs, *this* component's
    //    `entity` is set, but a freshly constructed child isn't attached until its
    //    own addComp() call completes. A cascade builds the child before that happens:
    //
    //    // FAILS => Comp2 isn't attached when ..addComp() runs:
    //
    //    addComp(Comp2(app)..addComp(Comp3(app)));
    //
    //    // CORRECT => split construction, attachment, and the grandchild add into separate
    //    //            statements so each addComp() finishes before the next depends on it:
    //
    //    final c = Comp2(app);  // construct
    //    addComp(c);            // attach c to this (sets c.entity)
    //    c.addComp(Comp3(app)); // now c can add its own child
  }
}
class Comp2 extends Comp<G> { Comp2(super.app); }
class Comp3 extends Comp<G> { Comp3(super.app); }
class Comp4 extends Comp<G> { Comp4(super.app); }
class Comp5 extends Comp<G> { Comp5(super.app); }

class MyEntity extends Entity<G> {
  late Comp1 c1;
  late Comp2 c2;
  late Comp3 c3;
  late Comp4 c4;
  late Comp5 c5;

  MyEntity(super.app) {
    // 1
    c1 = Comp1(app);
    addComp(c1);

    // 2
    c2 = Comp2(app);
    c1.addComp(c2);
    
    // 3
    c3 = Comp3(app);
    c2.addComp(c3);
    
    // 4
    c4 = Comp4(app);
    c3.addComp(c4);
    
    // 5
    c5 = Comp5(app);
    c4.addComp(c5);

    // extra
    addComp(Comp2(app));
    addComp(Comp3(app));

    c1.addComp(Comp3(app));
    c1.addComp(Comp4(app));

    c2.addComp(Comp4(app));
    c2.addComp(Comp5(app));

    c3.addComp(Comp1(app));
    c3.addComp(Comp2(app));

    c4.addComp(Comp2(app));
    c4.addComp(Comp3(app));

    c5.addComp(Comp3(app));
    c5.addComp(Comp4(app));
  }
}

class TestDrawScene extends DrawScene<G> {
  late MyEntity myEntity;

  TestDrawScene(super.app);

  @override
  void onStart() => addEntity(myEntity = MyEntity(app));

  @override
  void onDrawBackground() {
    draw.component.entityTree(myEntity, 10, 10, 20);
  }
}

typedef G = TestDrawApp;

class TestDrawApp extends ExampleRaylibApp<G> {
  TestDrawApp(super.backend);

  @override
  void onInit() {
    rl.CoreD.InitWindow(screenWidth, screenHeight, "test_draw");
    rl.CoreD.SetWindowMonitor(0);
    rl.CoreD.SetTargetFPS(60);

    addScene(TestDrawScene(app));
  }
}

void main() => runExample((backend) => G(backend));
