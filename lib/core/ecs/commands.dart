part of '../raylib_dartified_unhinged.dart';

// TODO: think about removing whole `Command` system
//       (isn't it useless if we have `Callback` system?)

abstract class Command<T extends App<T>> extends ECSBase<T> with
  Self<Command<T>>,
  IsCancelable<T, Command<T>>
{

  @override
  final T app;
  
  Command(this.app);

  void executeCommand();

  void _doExecuteCommand() {
    if (isCanceled) return;
    executeCommand();
  }
}

class AddEntityCommand<T extends App<T>> extends Command<T> {
  final Entity<T> entity;
  
  AddEntityCommand(super.app, this.entity);

  @override
  void executeCommand() => app.scene.addEntity(entity);
}

class RemoveEntityCommand<T extends App<T>> extends Command<T> {
  final Entity<T> entity;
  
  RemoveEntityCommand(super.app, this.entity);

  @override
  void executeCommand() => app.scene.removeEntity(entity);
}

class NextSceneCommand<T extends App<T>> extends Command<T> {
  NextSceneCommand(super.app);

  @override
  void executeCommand() => app.nextScene();
}

class PrevSceneCommand<T extends App<T>> extends Command<T> {
  PrevSceneCommand(super.app);

  @override
  void executeCommand() => app.previousScene();
}

class SetSceneCommand<T extends App<T>> extends Command<T> {
  final Scene<T> nextScene;

  SetSceneCommand(super.app, this.nextScene);

  @override
  void executeCommand() => app.setScene(nextScene);
}

class SetSceneKeyCommand<T extends App<T>> extends Command<T> {
  final String key;

  SetSceneKeyCommand(super.app, this.key);

  @override
  void executeCommand() => app.setSceneByKey(key);
}

class ExitAppCommand<T extends App<T>> extends Command<T> {
  ExitAppCommand(super.app);

  @override
  void executeCommand() => app._exitApp = true;
}
