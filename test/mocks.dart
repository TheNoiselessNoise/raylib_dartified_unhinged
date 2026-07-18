import 'package:raylib_dartified_unhinged/raylib_dartified_unhinged.dart';

T buildApp<T extends App<T>>({
  bool clearInitEvents = false,
  required T Function() factory,
}) {
  final app = factory()..init();
  if (clearInitEvents) {
    app.processQueuedEventsForTest();
    app.clearEventHistory();
  }
  return app;
}