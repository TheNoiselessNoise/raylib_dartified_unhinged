part of '../raylib_dartified_unhinged.dart';

abstract class Command<T extends App<T>> extends ECSBase<T> with
  Self<Command<T>>,
  IsCancelable<T, Command<T>>
{

  @override
  final T app;
  
  Command(this.app);

  void execute();

  void _doExecute() {
    if (isCanceled) return;
    execute();
  }
}

class AddEntityCommand<T extends App<T>> extends Command<T> {
  final Entity<T> entity;
  
  AddEntityCommand(super.app, this.entity);

  @override
  void execute() => app.scene.addEntity(entity);
}

class RemoveEntityCommand<T extends App<T>> extends Command<T> {
  final Entity<T> entity;
  
  RemoveEntityCommand(super.app, this.entity);

  @override
  void execute() => app.scene.removeEntity(entity);
}

class NextSceneCommand<T extends App<T>> extends Command<T> {
  NextSceneCommand(super.app);

  @override
  void execute() => app.nextScene();
}

class PrevSceneCommand<T extends App<T>> extends Command<T> {
  PrevSceneCommand(super.app);

  @override
  void execute() => app.previousScene();
}

class SetSceneCommand<T extends App<T>> extends Command<T> {
  final Scene<T> nextScene;

  SetSceneCommand(super.app, this.nextScene);

  @override
  void execute() => app.setScene(nextScene);
}

class SetSceneKeyCommand<T extends App<T>> extends Command<T> {
  final String key;

  SetSceneKeyCommand(super.app, this.key);

  @override
  void execute() => app.setSceneByKey(key);
}

class ExitAppCommand<T extends App<T>> extends Command<T> {
  ExitAppCommand(super.app);

  @override
  void execute() => app._exitApp = true;
}
