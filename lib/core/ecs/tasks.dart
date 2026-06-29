part of '../raylib_dartified_unhinged.dart';

abstract class Task<T extends App<T>> extends ECSBase<T> with
  Self<Task<T>>,
  IsCancelable<T, Task<T>>
{

  @override
  final T app;
  
  Task(this.app);

  bool _hasStarted = false;

  bool update(double dt);

  bool _doUpdate(double dt) {
    if (isCanceled) return true;
    return update(dt);
  }
}

class DelayTask<T extends App<T>> extends Task<T> {
  double remaining;
  final void Function(DelayTask<T> self) action;

  DelayTask(super.app, {
    double seconds = 0,
    required this.action,
  }) : remaining = seconds;

  @override
  bool update(double dt) {
    remaining -= dt;
    if (remaining <= 0) {
      action(this);
      return true;
    }
    return false;
  }
}

class DurationTask<T extends App<T>> extends Task<T> {
  double remaining;
  final void Function(DurationTask<T> self, double dt) actionUpdate;
  final void Function(DurationTask<T> self)? actionFinish;

  DurationTask(super.app, {
    double seconds = 0,
    required this.actionUpdate,
    this.actionFinish,
  }) : remaining = seconds;

  @override
  bool update(double dt) {
    actionUpdate(this, dt);
    remaining -= dt;

    if (remaining <= 0) {
      actionFinish?.call(this);
      return true;
    }

    return false;
  }
}