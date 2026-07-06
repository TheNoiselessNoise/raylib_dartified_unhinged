// Run it: dart run test_tasks.dart
import '_base.dart';

class TestTasksScene extends FWidgetScene<G> {
  late ExampleMessagesWidget<G> messagesWidget;

  TestTasksScene(super.app) {
    addEntity(FPadding.LTRB(app, 0, 50, 0, 0,
      child: messagesWidget = .new(app),
    ));
  }

  void addMessage(String message) {
    print(message);
    messagesWidget.addMessage(message);
    messagesWidget.rebuild();
  }

  void clearMessages() {
    messagesWidget.clear();
    messagesWidget.rebuild();
  }

  @override
  void onDrawBackground() => draw.text
    .fontSize(14)
    .position(10, 10)
    .text('[Q]', .ORANGE).text(' = Delayed Task')
    .gap(8)
    .text('[W]', .ORANGE).text(' = Duration Task')
    .gap(8)
    .text('[E]', .ORANGE).text(' = Interval Task')
    .gap(8)
    .text('[C]', .ORANGE).text('= Clear Messages');

  @override
  void onInput() {
    if (rl.CoreD.IsKeyPressed(.KEY_Q)) {
      task(DelayTask(app,
        seconds: .2,
        action: (_) => addMessage('DelayTask: Executed!'),
      ));
    }

    if (rl.CoreD.IsKeyPressed(.KEY_W)) {
      task(DurationTask(app,
        seconds: .2,
        actionUpdate: (_, dt) => addMessage('DurationTask: Updating!'),
        actionFinish: (_) => addMessage('DurationTask: Finished!'),
      ));
    }

    if (rl.CoreD.IsKeyPressed(.KEY_E)) {
      task(IntervalTask(app,
        remaining: .2,
        interval: .05,
        triggerImmediately: true,
        actionUpdate: (_, dt) => addMessage('IntervalTask: Updating $dt!'),
        actionFinish: (_) => addMessage('IntervalTask: Finished!'),
      ));
    }

    if (rl.CoreD.IsKeyPressed(.KEY_C)) clearMessages();
  }

  @override
  void onTask(Task<G> task) {
    addMessage('onTask: $task');
  }

  @override
  void onEvent(Event<G> event) {
    if (event case EventTaskStarting e) {
      addMessage('onEvent: Starting task ${e.startingTask}');
    }

    if (event case EventTaskCancelled e) {
      addMessage('onEvent: Cancelled task ${e.cancelledTask}');
    }

    if (event case EventTaskFinished e) {
      addMessage('onEvent: Finished task ${e.finishedTask}');
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
