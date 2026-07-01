part of '../../raylib_dartified_unhinged.dart';

class HeadlessRenderBackend extends RenderBackend {
  @override
  void drawText(String text, num posX, num posY, num fontSize, ColorD color) {}

  @override
  void drawTextEx(FontD font, String text, Vector2D position, num fontSize, num spacing, ColorD tint) {}

  @override
  void drawTextPro(FontD font, String text, Vector2D position, Vector2D origin, num rotation, num fontSize, num spacing, ColorD tint) {}

  @override
  void drawLineEx(Vector2D startPos, Vector2D endPos, num thick, ColorD color) {}

  @override
  int measureText(String text, num fontSize) => 0;
  
  @override
  Vector2D measureTextEx(FontD font, String text, num fontSize, num spacing) => .zero();

  @override
  void drawRectangle(num posX, num posY, num width, num height, ColorD color) {}

  @override
  void drawRectangleRounded(RectangleD rec, num roundness, num segments, ColorD color) {}

  @override
  void drawRectangleRoundedLinesEx(RectangleD rec, num roundness, num segments, num lineThick, ColorD color) {}

  @override
  void drawRectangleRec(RectangleD rec, ColorD color) {}

  @override
  void drawRectanglePro(RectangleD rec, Vector2D origin, num rotation, ColorD color) {}

  @override
  void drawPixel(num posX, num posY, ColorD color) {}

  @override
  void drawTriangle(Vector2D v1, Vector2D v2, Vector2D v3, ColorD color) {}

  @override
  void drawCircle(num centerX, num centerY, num radius, ColorD color) {}

  @override
  void drawTexturePro(TextureD texture, RectangleD source, RectangleD dest, Vector2D origin, num rotation, ColorD tint) {}

  @override
  void beginDrawing() {}

  @override
  void clearBackground(ColorD color) {}
  
  @override
  void endDrawing() {}

  @override
  void beginScissorMode(num x, num y, num width, num height) {}
    
  @override
  void endScissorMode() {}

  @override
  void drawRectangleLinesEx(RectangleD rec, num lineThick, ColorD color) {}

  @override
  void drawCircleLinesV(Vector2D center, num radius, ColorD color) {}

  @override
  void drawRectangleLinesRotated(RectangleD rect, num rotationDegrees, num lineThick, ColorD color) {}
}

class HeadlessInputBackend extends InputBackend {
  @override
  bool isKeyPressed(KeyboardKey key) => false;

  @override
  bool isKeyDown(KeyboardKey key) => false;

  @override
  bool isKeyUp(KeyboardKey key) => false;

  @override
  bool isKeyPressedRepeat(KeyboardKey key) => false;

  @override
  int getCharPressed() => 0;

  @override
  int getKeyPressed() => 0;
  
  @override
  bool isMouseButtonPressed(MouseButton button) => false;
  
  @override
  bool isMouseButtonDown(MouseButton button) => false;
}

class HeadlessCollisionBackend extends CollisionBackend {
  @override
  bool circles(Vector2D center1, num radius1, Vector2D center2, num radius2) => false;
  
  @override
  bool circleRectangle(Vector2D center, num radius, RectangleD rec) => false;
  
  @override
  bool rectangles(RectangleD rec1, RectangleD rec2) => false;

  @override
  bool pointRectangle(Vector2D point, RectangleD rec) => false;
}

class HeadlessAssetManager extends AssetManager {
  @override
  ImageD image(String id, {String? path}) => .zero();

  @override
  TextureD texture(String id, {String? path}) => .zero();

  @override
  FontD font(String id, {String? path, int fontSize = 32}) => .zero();
}

class HeadlessBackend extends UnhingedBackend {
  HeadlessBackend() : super(
    render: HeadlessRenderBackend(),
    input: HeadlessInputBackend(),
    collision: HeadlessCollisionBackend(),
    assets: HeadlessAssetManager(),
  );

  @override
  double getFrameTime() => 1;

  @override
  void setMouseCursor(MouseCursor cursor) {}

  @override
  void setClipboardText(String text) {}

  @override
  String getClipboardText() => '';

  @override
  void setTargetFPS(int fps) {}

  @override
  FontD getFontDefault() => .new();
}