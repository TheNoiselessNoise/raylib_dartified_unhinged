// Run it: dart run test_event_recording.dart
import '_base.dart';

class TestEvent extends Event<G> {
  TestEvent(super.app);
}

class TestEventsComponent1 extends Comp<G> {
  TestEventsComponent1(super.app);
}

class TestEventsEntity1 extends Entity<G> {
  late TestEventsComponent1 comp1;

  TestEventsEntity1(super.app) {
    addComp(comp1 = .new(app));
  }
}

class PrintEvent extends Event<G> {
  PrintEvent(super.app);
}

class TestEventsEntity2 extends Entity<G> {
  TestEventsEntity2(super.app);

  @override
  void onEvent(Event<G> event) {
    if (event is PrintEvent) {
      addMessage('Entity2 recieved a PrintEvent!');
      rebuildWidget();
    }
  }
}

extension on HasAppAccess<G> {
  TestEventsScene get eventsScene => app.getScene()!;
  void addMessage(String message, {bool? isValid}) => eventsScene.messagesWidget.addMessage(message, isValid: isValid);
  void clearMessages() => eventsScene.messagesWidget.clear();
  void rebuildWidget() => eventsScene.messagesWidget.rebuild();
}

enum EmitterType {
  app,
  scene,
  entity1,
  entity2,
  comp;

  EmitterType get prev => switch (this) {
    comp => entity2,
    entity2 => entity1,
    entity1 => scene,
    scene => app,
    app => comp,
  };

  EmitterType get next => switch (this) {
    app => scene,
    scene => entity1,
    entity1 => entity2,
    entity2 => comp,
    comp => app,
  };
}

class MessagesWidget extends ExampleMessagesWidget<G> {
  MessagesWidget(super.app);

  @override
  get header => FSized(app,
    heightMode: .flexible,
    widthMode: .flexible,
    child: FRow(app,
      gap: 8,
      children: [
        FLabel(app, fontSize: 14, text: 'SELECTED TYPE: ${eventsScene.selectedType.name}'),
        FLabel(app, fontSize: 14, text: 'SELECTED SCOPE: ${eventsScene.selectedScope.name}'),
        FLabel(app, fontSize: 14, text: 'ALL: ${eventsScene.all ? 'YES' : 'NO'}'),
      ],
    ),
  );
}

class TestEventsScene extends FWidgetScene<G> {
  late MessagesWidget messagesWidget;
  late TestEventsEntity1 entity1;
  late TestEventsEntity2 entity2;

  TestEventsScene(super.app) {
    addEntity(entity1 = .new(app));
    addEntity(entity2 = .new(app));
  }

  @override
  void onStart() {
    addEntity(messagesWidget = .new(app));
    refreshTable();
  }

  EventScope selectedScope = .global;
  EmitterType selectedType = .app;
  bool all = false;

  void fire() {
    final event = TestEvent(app)..scope = selectedScope;

    switch (selectedType) {
      case .app:     app.dispatch(event);
      case .scene:   dispatch(event);
      case .entity1: entity1.dispatch(event);
      case .comp:    entity1.comp1.dispatch(event);
      case .entity2: entity2.dispatch(event);
    }
  }

  void refreshTable() {
    clearMessages();

    IsAnyEventHistoryHolder<G> origin = switch (selectedType) {
      .app => app,
      .scene => this,
      .entity1 => entity1,
      .comp => entity1.comp1,
      .entity2 => entity2,
    };

    final originEvents = origin.getEvents();
    addMessage('Origin (${selectedType.name}) has ${originEvents.length} events recorded.');
    for (final (i, e) in originEvents.indexed) {
      addMessage('${i+1}) $e');
    }

    final rootEvents = app.getEvents(origin: all ? null : origin);
    final originStr = all ? '' : ' (origin: ${selectedType.name})';
    addMessage('Root$originStr has ${rootEvents.length} events recorded.');
    for (final (i, e) in rootEvents.indexed) {
      addMessage('${i+1}) $e');
    }

    rebuildWidget();
  }

  void fireAndRefreshTable() {
    fire();
    refreshTable();
  }

  @override
  void onInput() {
    if (rl.CoreD.IsKeyPressed(.KEY_SPACE)) {
      fireAndRefreshTable();
    }

    if (rl.CoreD.IsKeyPressed(.KEY_LEFT)) {
      selectedType = selectedType.prev;
      refreshTable();
    }

    if (rl.CoreD.IsKeyPressed(.KEY_RIGHT)) {
      selectedType = selectedType.next;
      refreshTable();
    }

    if (rl.CoreD.IsKeyPressed(.KEY_UP)) {
      selectedScope = selectedScope.prev;
      refreshTable();
    }

    if (rl.CoreD.IsKeyPressed(.KEY_DOWN)) {
      selectedScope = selectedScope.next;
      refreshTable();
    }

    if (rl.CoreD.IsKeyPressed(.KEY_L)) {
      all = !all;
      refreshTable();
    }
    
    if (rl.CoreD.IsKeyPressed(.KEY_C)) {
      clearAllEventHistory();
      refreshTable();
    }

    // entity 2
    if (rl.CoreD.IsKeyPressed(.KEY_W)) {
      entity2.dispatch(PrintEvent(app), scope: .self);
    }

    if (rl.CoreD.IsKeyPressed(.KEY_E)) {
      entity2.replayEvents();
    }
  }
}

typedef G = TestEventsApp;

extension on HasAppAccess<G> {
  void clearAllEventHistory() {
    app.clearEventHistory();
    eventsScene.clearEventHistory();
    eventsScene.entity1.clearEventHistory();
    eventsScene.entity1.comp1.clearEventHistory();
    eventsScene.entity2.clearEventHistory();
  }
}

class TestEventsApp extends ExampleApp<G> {
  TestEventsApp(super.rl);

  @override
  void onInit() {
    rl.CoreD.InitWindow(screenWidth, screenHeight, "test_event_recording");
    rl.CoreD.SetWindowMonitor(0);
    rl.CoreD.SetTargetFPS(60);

    addScene(TestEventsScene(app));
    clearAllEventHistory();
  }

  @override
  bool onBeforeEventRecorded(Event<G> event) {
    return event is TestEvent || event is PrintEvent;
  }
}

void main() => runExample((rl) => G(rl));