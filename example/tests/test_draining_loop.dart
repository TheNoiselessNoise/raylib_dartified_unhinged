// Run it: dart run test_draw.dart
import '_base.dart';

mixin IsSourcedEvent on Event<G> {
  String get source;
}

class MyEvent extends Event<G> with IsSourcedEvent {
  @override final String source;

  MyEvent(super.app, this.source);
}

class MySecondEvent extends Event<G> with IsSourcedEvent {
  @override final String source;
  
  MySecondEvent(super.app, this.source);
}

extension on HasAppAccess<G> {
  TestDrainingLoopScene get mainScene => app.getScene()!;
  void addMessage(String message, {bool? isValid}) => mainScene.messagesWidget.addMessage(message, isValid: isValid);
  void rebuildMessages() => mainScene.messagesWidget.rebuild();
}

class TestDrainingLoopScene extends DrawScene<G> {
  late ExampleMessagesWidget<G> messagesWidget;

  TestDrainingLoopScene(super.app);

  @override
  void onStart() => addEntity(messagesWidget = .new(app));
}

typedef G = TestDrainingLoopApp;

class TestDrainingLoopApp extends ExampleRaylibApp<G> {
  TestDrainingLoopApp(super.backend);

  @override
  void onInit() {
    rl.CoreD.InitWindow(screenWidth, screenHeight, "test_draw");
    rl.CoreD.SetWindowMonitor(0);
    rl.CoreD.SetTargetFPS(60);

    addScene(TestDrainingLoopScene(app));
  }

  void printEvent(IsSourcedEvent event) {
    addMessage('$event at frame ${time.frameCount} from ${event.source}');
    rebuildMessages();
  }

  @override
  void onEvent(Event<G> event) {
    if (event is MyEvent) {
      printEvent(event);
      emit(MySecondEvent(app, '[App.onEvent, emit]'), scope: .self);
      callback(() => emit(MySecondEvent(app, '[App.onEvent, callback]'), scope: .self));
      task(DelayTask(app,
        action: (_) => emit(MySecondEvent(app, '[App.onEvent, task]'), scope: .self),
      ));
    }

    if (event is MySecondEvent) {
      printEvent(event);
    }
  }

  @override
  void onInput() {
    if (rl.CoreD.IsKeyPressed(.KEY_SPACE)) {
      emit(MyEvent(app, 'App.onInput'), scope: .self);
    }
  }
}

void main() => runExample((backend) => G(backend));
