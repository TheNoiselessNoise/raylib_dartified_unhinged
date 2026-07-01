// Run it: dart run test_tasks.dart
import '_base.dart';

class MessagesWidget extends ExampleMessagesWidget<G> {
  MessagesWidget(super.app);

  @override
  get header => FSized(app,
    heightMode: .flexible,
    widthMode: .flexible,
    child: FRow(app,
      gap: 8,
      children: [
        FLabel(app, fontSize: 14, text: 'SPACE = Delayed Task, ENTER = Duration Task, C = Clear Messages'),
      ],
    ),
  );

  @override
  void addMessage(String message, {bool? isValid}) => setState(() {
    super.addMessage(message, isValid: isValid);
  });

  @override
  void clear() => setState(() => super.clear());
}

class TestTasksScene extends FWidgetScene<G> {
  late MessagesWidget messagesWidget;

  TestTasksScene(super.app) {
    addEntity(messagesWidget = MessagesWidget(app));
  }

  @override
  void onInput() {
    if (rl.CoreD.IsKeyPressed(.KEY_SPACE)) {
      task(DelayTask(app,
        seconds: .2,
        action: (_) => messagesWidget.addMessage('DelayTask: Executed!'),
      ));
    }

    if (rl.CoreD.IsKeyPressed(.KEY_ENTER)) {
      task(DurationTask(app,
        seconds: .2,
        actionUpdate: (_, dt) => messagesWidget.addMessage('DurationTask: Updating!'),
        actionFinish: (_) => messagesWidget.addMessage('DurationTask: Finished!'),
      ));
    }

    if (rl.CoreD.IsKeyPressed(.KEY_C)) {
      messagesWidget.clear();
    }
  }

  @override
  void onTask(Task<G> task) {
    messagesWidget.addMessage('onTask: $task');
  }

  @override
  void onEvent(Event<G> event) {
    if (event case EventTaskStarting e) {
      messagesWidget.addMessage('onEvent: Starting task ${e.startingTask}');
    }

    if (event case EventTaskCancelled e) {
      messagesWidget.addMessage('onEvent: Cancelled task ${e.cancelledTask}');
    }

    if (event case EventTaskFinished e) {
      messagesWidget.addMessage('onEvent: Finished task ${e.finishedTask}');
    }
  }
}

typedef G = TestTasksApp;

class TestTasksApp extends ExampleRaylibApp<G> {
  TestTasksApp(super.backend);

  @override
  void onInit() {
    rl.CoreD.InitWindow(screenWidth, screenHeight, "test_tasks");
    rl.CoreD.SetWindowMonitor(0);
    rl.CoreD.SetTargetFPS(60);

    addScene(TestTasksScene(app));
  }
}

void main() => runExample((backend) => G(backend));
