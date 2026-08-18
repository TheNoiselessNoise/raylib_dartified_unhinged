part of '../../raylib_dartified_unhinged.dart';

/// Adds an input handling hook to an ECS object.
///
/// The **on** phase only, input handling is not cancelable.
///
/// Note: this mixin does not read or process input itself; it merely provides
/// a conventional hook point where input handling *should* occur. Actual input
/// polling is left entirely to the override or registered listeners.
mixin IsInputHandleable<
  T extends App<T>,
  E extends ECSBase<T>
> on
  Self<E>,
  ECSBase<T>
{
  late final hookOnHandleInputKey = ECSHookKey<void Function(E self)>(
    'IsInputHandleable', 'onHandleInput'
  );

  Iterable<void Function(E self)> get _onHandleInputFns 
    => hooksOf(hookOnHandleInputKey);

  /// Registers [fn] to be called during the input handling phase.
  @nonVirtual
  E listenHandleInput(void Function(E self) fn) {
    addHook(hookOnHandleInputKey, fn);
    return self;
  }

  /// Propagates the input phase through listeners and the [onInput] hook.
  void _doHandleInput() {
    _onHandleInputFns.forEach((f) => f(self));
    onInput();
  }

  /// Override to handle input within the class.
  ///
  /// Called after all registered [listenHandleInput] listeners.
  /// 
  /// This method does not read or process input itself; it merely provides
  /// a conventional hook point where input handling *should* occur.
  void onInput() {}
}