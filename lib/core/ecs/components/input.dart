part of '../../raylib_dartified_unhinged.dart';

class CInput<T extends App<T>> extends Comp<T> {
    
  Map<String, MouseButton> mouseMap;
  Map<String, KeyboardKey> keyMap;

  CInput(super.app, {
    Map<String, MouseButton>? mouseMap,
    Map<String, KeyboardKey>? keyMap,
  }) :
    mouseMap = mouseMap ?? {},
    keyMap = keyMap ?? {};

  @override
  void onAdd(ECSBase<T> parent) {
    mouseMap.forEach((action, code) => input.mapMouse(action, code));
    keyMap.forEach((action, code) => input.mapKey(action, code));
  }

  void mapMouse(String action, MouseButton mouseButton)
    => input.mapMouse(action, mouseButton);

  void mapKey(String action, KeyboardKey key)
    => input.mapKey(action, key);

  // clone

  @override
  CInput<T> createInstance() => .new(app,
    mouseMap: .from(mouseMap),
    keyMap: .from(keyMap),
  );

  // state

  @override
  CInputSnapshot<T> createSnapshot() {
    final snapshot = CInputSnapshot<T>(namedId);
    snapshot.mouseMap = .from(mouseMap);
    snapshot.keyMap = .from(keyMap);
    return snapshot;
  }

  @override
  @mustCallSuper
  void restoreSnapshot(covariant CInputSnapshot<T> snapshot) {
    super.restoreSnapshot(snapshot);
    
    mouseMap = .from(snapshot.mouseMap);
    keyMap = .from(snapshot.keyMap);
  }
}

class CInputSnapshot<T extends App<T>> extends CompSnapshot<T, CInput<T>> {
  late Map<String, MouseButton> mouseMap;
  late Map<String, KeyboardKey> keyMap;
  
  CInputSnapshot(super.namedId);

  @override
  CInput<T> createInstance(T app) => CInput<T>(app,
    mouseMap: .from(mouseMap),
    keyMap: .from(keyMap),
  );
}