import 'package:raylib_dartified_unhinged/raylib_dartified_unhinged.dart';
export 'package:raylib_dartified_unhinged/raylib_dartified_unhinged.dart';

extension ExampleHasAppAccess on HasAppAccess<ExampleRaylibApp> {
  Raylib get rl => app.rl;
}

abstract class ExampleRaylibApp<T extends ExampleRaylibApp<T>> extends App<T> {
  ExampleRaylibApp(super.backend);

  Raylib get rl => (backend as RaylibBackend).rl;

  @override
  bool shouldExit() => rl.CoreD.WindowShouldClose();
}

class ExampleRaylibBridge<T extends ExampleRaylibApp<T>> extends UnhingedRaylibGame<ExampleRaylibApp<T>> {
  late T Function(UnhingedBackend backend) constructor;

  @override
  T create(UnhingedBackend backend) => constructor(backend);
}

void runExample<T extends ExampleRaylibApp<T>>(T Function(UnhingedBackend backend) constructor) {
  final example = ExampleRaylibBridge<T>();
  example.constructor = constructor;
  runRaylib(example, nativeLibPath: 'raylib-5.5_linux_amd64/lib');
}

class Message {
  final DateTime date;
  final String message;
  final bool? isValid;

  Message(this.date, this.message, this.isValid);

  String get formattedDate => [
    date.day.pad(), '-', date.month.pad(), '-', date.year.pad(), ' ',
    date.minute.pad(), ':', date.second.pad(), ':', date.millisecond.pad(3), '.',
    date.millisecond.pad(3)
  ].join('');
}

class ExampleMessagesWidget<T extends ExampleRaylibApp<T>> extends FWidget<T> {
  ExampleMessagesWidget(super.app);

  final List<Message> messages = [];

  void clear()
    => messages.clear();
  
  void addMessage(String message, {bool? isValid})
    => messages.add(.new(.now(), message, isValid));
  
  int get fontSize => 16;

  ColorD messageColor(Message message) => switch (message.isValid) {
    false => .RED,
    true => .GREEN,
    null => .WHITE,
  };

  FWidget<T> _messageWidget(Message message) => FRow(app,
    gap: 8,
    children: [
      FSized(app,
        width: 220,
        heightMode: .flexible,
        child: FLabel(app,
          text: message.formattedDate,
          fontSize: fontSize,
          color: messageColor(message),
        ),
      ),
      FLabel(app,
        text: message.message,
        fontSize: fontSize,
        color: messageColor(message),
      ),
    ],
  );

  FWidget<T>? get header => null;

  @override
  FWidget<T> build() => FPadding.all(app, 8,
    child: FColumn(app,
      gap: 16,
      children: [
        ?header,

        FExpanded(app,
          child: FSingleChildScrollView(app,
            defaultScrollSupportSpeed: 50,
            child: FColumn(app,
              gap: 2,
              children: messages.map(_messageWidget).toList(),
            ),
          ),
        ),
      ],
    ),
  );
}