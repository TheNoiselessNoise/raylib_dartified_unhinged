// Run it: dart run test_event_replaying.dart
import '_base.dart';

class MyEvent extends Event<G> {
  MyEvent(super.app);
}

class MyEntity extends Entity<G> {
  MyEntity(super.app);
}

extension on HasAppAccess<G> {
  TestEventReplayingScene get mainScene => app.getScene()!;
  ExampleMessagesWidget<G> get messages => mainScene.messages;

  void addMessage(String message) => messages.setState(() => messages.addMessage(message));
  void clearMessages() => messages.setState(() => messages.clear());
}

class TestEventReplayingScene extends DrawScene<G> {
  late ExampleMessagesWidget<G> messages;
  late MyEntity myEntity;

  TestEventReplayingScene(super.app) {
    addEntity(messages = .new(app));
    addEntity(myEntity = .new(app));

    app.listenOnEvent(appEventHandler);
    myEntity.listenOnEvent(myEntityEventHandler);
  }

  void appEventHandler(G app, Event<G> event) {
    if (event is! MyEvent) return;
    print('App.MyEvent');
  }

  @override
  void onEvent(Event<G> event) {
    if (event is! MyEvent) return;
    print('Scene.MyEvent');
  }

  void myEntityEventHandler(Entity<G> entity, Event<G> event) {
    if (event is! MyEvent) return;
    print('Entity.MyEvent');
  }

  @override
  void onInput() {
    if (rl.CoreD.IsKeyPressed(.KEY_SPACE)) addMessage('Frame ${app.time.frameCount}');
    if (rl.CoreD.IsKeyPressed(.KEY_BACKSPACE)) clearMessages();
    if (rl.CoreD.IsKeyPressed(.KEY_Q)) app.emit(MyEvent(app), scope: .self);
    if (rl.CoreD.IsKeyPressed(.KEY_W)) emit(MyEvent(app), scope: .self);
    if (rl.CoreD.IsKeyPressed(.KEY_E)) myEntity.emit(MyEvent(app), scope: .self);

    clearMessages();
    for (final (i, event) in app.getRecordedEvents().indexed) {
      if (event is! MyEvent) continue;
      String origin = switch (event.origin) {
        G _ => 'App',
        Scene<G> _ => 'Scene',
        Entity<G> _ => 'Entity',
        _ => 'unknown',
      };
      addMessage('$i) MyEvent (origin: $origin)');
    }

    if (rl.CoreD.IsKeyPressed(.KEY_ENTER)) {
      app.replayRecordedEvents(filter: (event) => event is MyEvent);
    }

    // if (rl.CoreD.IsKeyDown(.KEY_UP))
    // if (rl.CoreD.IsKeyDown(.KEY_DOWN))
    // if (rl.CoreD.IsKeyDown(.KEY_W))
    // if (rl.CoreD.IsKeyDown(.KEY_S))
    // if (rl.CoreD.IsKeyDown(.KEY_A))
    // if (rl.CoreD.IsKeyDown(.KEY_D))
  }

  @override
  void onDraw(double dt) {

  }
}

typedef G = TestEventReplayingApp;

class TestEventReplayingApp extends ExampleRaylibApp<G> {
  TestEventReplayingApp(super.backend);

  @override
  void onInit() {
    rl.CoreD.InitWindow(screenWidth, screenHeight, "test_event_replaying");
    rl.CoreD.SetWindowMonitor(0);
    rl.CoreD.SetTargetFPS(60);

    addScene(TestEventReplayingScene(app));
  }
}

void main() => runExample((backend) => G(backend));
