part of '../../raylib_dartified_unhinged.dart';

abstract class RenderBackend {
  void drawText(String text, num posX, num posY, num fontSize, ColorD color);

  void drawTextEx(FontD font, String text, Vector2D position, num fontSize, num spacing, ColorD tint);

  void drawTextPro(FontD font, String text, Vector2D position, Vector2D origin, num rotation, num fontSize, num spacing, ColorD tint);

  void drawLineEx(Vector2D startPos, Vector2D endPos, num thick, ColorD color);
  
  int measureText(String text, num fontSize);

  Vector2D measureTextEx(FontD font, String text, num fontSize, num spacing);
  
  void drawRectangle(num posX, num posY, num width, num height, ColorD color);

  void drawRectangleRounded(RectangleD rec, num roundness, num segments, ColorD color);

  void drawRectangleRoundedLinesEx(RectangleD rec, num roundness, num segments, num lineThick, ColorD color);

  void drawRectangleRec(RectangleD rec, ColorD color);

  void drawRectanglePro(RectangleD rec, Vector2D origin, num rotation, ColorD color);

  void drawPixel(num posX, num posY, ColorD color);

  void drawTriangle(Vector2D v1, Vector2D v2, Vector2D v3, ColorD color);

  void drawCircle(num centerX, num centerY, num radius, ColorD color);

  void drawTexturePro(TextureD texture, RectangleD source, RectangleD dest, Vector2D origin, num rotation, ColorD tint);

  void beginDrawing();

  void clearBackground(ColorD color);
  
  void endDrawing();

  void beginScissorMode(num x, num y, num width, num height);
    
  void endScissorMode();
  
  void drawRectangleLinesEx(RectangleD rec, num lineThick, ColorD color);

  void drawCircleLinesV(Vector2D center, num radius, ColorD color);

  void drawRectangleLinesRotated(RectangleD rect, num rotationDegrees, num lineThick, ColorD color);

  void dispose() {}
}

abstract class InputBackend {
  bool isKeyPressed(KeyboardKey key);

  bool isKeyDown(KeyboardKey key);

  bool isKeyUp(KeyboardKey key);

  bool isKeyPressedRepeat(KeyboardKey key);

  int getCharPressed();

  int getKeyPressed();
  
  bool isMouseButtonPressed(MouseButton button);
  
  bool isMouseButtonDown(MouseButton button);

  void dispose() {}
}

abstract class CollisionBackend {
  bool circles(Vector2D center1, num radius1, Vector2D center2, num radius2);
  
  bool circleRectangle(Vector2D center, num radius, RectangleD rec);
  
  bool rectangles(RectangleD rec1, RectangleD rec2);

  bool pointRectangle(Vector2D point, RectangleD rec);

  void dispose() {}
}

abstract class AssetManager {
  ImageD image(String id, {String? path});

  TextureD texture(String id, {String? path});

  FontD font(String id, {String? path, int fontSize = 32});

  void dispose() {}
}

abstract class UnhingedBackend {
  final RenderBackend render;
  final InputBackend input;
  final CollisionBackend collision;
  final AssetManager assets;

  UnhingedBackend({
    required this.render,
    required this.input,
    required this.collision,
    required this.assets,
  });

  MouseInfo<Vector2D> mouse = .new();

  void beginFrame() {}
  
  void endFrame() {}

  double getFrameTime();

  void setMouseCursor(MouseCursor cursor);

  void setClipboardText(String text);

  String getClipboardText();

  void setTargetFPS(int fps);

  FontD getFontDefault();

  @mustCallSuper
  void dispose() {
    render.dispose();
    input.dispose();
    collision.dispose();
    assets.dispose();
  }
}