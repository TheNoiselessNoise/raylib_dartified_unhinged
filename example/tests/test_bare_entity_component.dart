// Run it: dart run test_bare_entity_component.dart
import '_base.dart';

final varCount = VarKey<int>('count');

class MyScene extends FWidgetScene<G> {
  late Entity<G> myEntity;
  
  Comp<G> get myComp => myEntity.getComponents().first;

  MyScene(super.app) {
    myEntity = .new(app)..addComp(Comp(app)..setVar(varCount, 0));
  }

  @override
  void onStart() => addEntity(myEntity);

  @override
  void onInput() {
    if (rl.CoreD.IsKeyPressed(.KEY_UP))   myComp.incVar(varCount,  1);
    if (rl.CoreD.IsKeyPressed(.KEY_DOWN)) myComp.incVar(varCount, -1);
  }

  @override
  void onDrawBackground() {
    rl.CoreD.DrawText('Count: ${myComp.getVar(varCount)}', 20, 20, 20, .WHITE);
    rl.CoreD.DrawText('[UP] = +1 [DOWN] = -1', 20, screenHeight - 40, 20, .WHITE);
  }
}

typedef G = MyApp;

class MyApp extends ExampleApp<G> {
  MyApp(super.rl);

  @override
  void onInit() {
    rl.CoreD.InitWindow(screenWidth, screenHeight, "test_bare_entity_component");
    rl.CoreD.SetWindowMonitor(0);
    rl.CoreD.SetTargetFPS(60);

    addScene(MyScene(app));
  }
}

void main() => runExample((rl) => G(rl));
