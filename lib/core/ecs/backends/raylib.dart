part of '../../raylib_dartified_unhinged.dart';

class RaylibRenderBackend extends RenderBackend {
  final Raylib rl;

  RaylibRenderBackend(this.rl);

  @override
  void drawText(String text, num posX, num posY, num fontSize, ColorD color)
    => rl.CoreD.DrawText(text, posX, posY, fontSize, color);

  @override
  void drawTextEx(FontD font, String text, Vector2D position, num fontSize, num spacing, ColorD tint)
    => rl.CoreD.DrawTextEx(font, text, position, fontSize, spacing, tint);

  @override
  void drawTextPro(FontD font, String text, Vector2D position, Vector2D origin, num rotation, num fontSize, num spacing, ColorD tint)
    => rl.CoreD.DrawTextPro(font, text, position, origin, rotation, fontSize, spacing, tint);

  @override
  void drawLineEx(Vector2D startPos, Vector2D endPos, num thick, ColorD color)
    => rl.CoreD.DrawLineEx(startPos, endPos, thick, color);

  @override
  int measureText(String text, num fontSize)
    => rl.CoreD.MeasureText(text, fontSize);

  @override
  Vector2D measureTextEx(FontD font, String text, num fontSize, num spacing)
    => rl.CoreD.MeasureTextEx(font, text, fontSize, spacing);
  
  @override
  void drawRectangle(num posX, num posY, num width, num height, ColorD color)
    => rl.CoreD.DrawRectangle(posX, posY, width, height, color);

  @override
  void drawRectangleRounded(RectangleD rec, num roundness, num segments, ColorD color)
    => rl.CoreD.DrawRectangleRounded(rec, roundness, segments, color);

  @override
  void drawRectangleRoundedLinesEx(RectangleD rec, num roundness, num segments, num lineThick, ColorD color)
    => rl.CoreD.DrawRectangleRoundedLinesEx(rec, roundness, segments, lineThick, color);

  @override
  void drawRectangleRec(RectangleD rec, ColorD color)
    => rl.CoreD.DrawRectangleRec(rec, color);

  @override
  void drawRectanglePro(RectangleD rec, Vector2D origin, num rotation, ColorD color)
    => rl.CoreD.DrawRectanglePro(rec, origin, rotation, color);

  @override
  void drawPixel(num posX, num posY, ColorD color)
    => rl.CoreD.DrawPixel(posX, posY, color);

  @override
  void drawTriangle(Vector2D v1, Vector2D v2, Vector2D v3, ColorD color)
    => rl.CoreD.DrawTriangle(v1, v2, v3, color);

  @override
  void drawCircle(num centerX, num centerY, num radius, ColorD color)
    => rl.CoreD.DrawCircle(centerX, centerY, radius, color);

  @override
  void drawTexturePro(TextureD texture, RectangleD source, RectangleD dest, Vector2D origin, num rotation, ColorD tint)
    => rl.CoreD.DrawTexturePro(texture, source, dest, origin, rotation, tint);

  @override
  void beginDrawing()
    => rl.CoreD.BeginDrawing();

  @override
  void clearBackground(ColorD color)
    => rl.CoreD.ClearBackground(color);
  
  @override
  void endDrawing()
    => rl.CoreD.EndDrawing();

  @override
  void beginScissorMode(num x, num y, num width, num height)
    => rl.CoreD.BeginScissorMode(x, y, width, height);
    
  @override
  void endScissorMode()
    => rl.CoreD.EndScissorMode();

  @override
  void drawRectangleLinesEx(RectangleD rec, num lineThick, ColorD color)
    => rl.CoreD.DrawRectangleLinesEx(rec, lineThick, color);

  @override
  void drawCircleLinesV(Vector2D center, num radius, ColorD color)
    => rl.CoreD.DrawCircleLinesV(center, radius, color);
  
  @override
  void drawRectangleLinesRotated(RectangleD rect, num rotationDegrees, num lineThick, ColorD color) {
    final centerX = rect.x + rect.width / 2;
    final centerY = rect.y + rect.height / 2;

    rl.RlglD.rlPushMatrix();
    rl.RlglD.rlTranslatef(centerX, centerY, 0);
    rl.RlglD.rlRotatef(rotationDegrees, 0, 0, 1);

    rl.CoreD.DrawRectangleLinesEx(
      .rect(-rect.width / 2, -rect.height / 2, rect.width, rect.height),
      lineThick,
      color,
    );

    rl.RlglD.rlPopMatrix();
  }
}

class RaylibInputBackend extends InputBackend {
  final Raylib rl;

  RaylibInputBackend(this.rl);

  @override
  bool isKeyPressed(KeyboardKey key)
    => rl.CoreD.IsKeyPressed(key);

  @override
  bool isKeyDown(KeyboardKey key)
    => rl.CoreD.IsKeyDown(key);

  @override
  bool isKeyUp(KeyboardKey key)
    => rl.CoreD.IsKeyUp(key);

  @override
  bool isKeyPressedRepeat(KeyboardKey key)
    => rl.CoreD.IsKeyPressedRepeat(key);

  @override
  int getCharPressed()
    => rl.CoreD.GetCharPressed();

  @override
  int getKeyPressed()
    => rl.CoreD.GetKeyPressed();
  
  @override
  bool isMouseButtonPressed(MouseButton button)
    => rl.CoreD.IsMouseButtonPressed(button);
  
  @override
  bool isMouseButtonDown(MouseButton button)
    => rl.CoreD.IsMouseButtonDown(button);
}

class RaylibCollisionBackend extends CollisionBackend {
  final Raylib rl;

  RaylibCollisionBackend(this.rl);

  @override
  bool circles(Vector2D center1, num radius1, Vector2D center2, num radius2)
    => rl.CoreD.CheckCollisionCircles(center1, radius1, center2, radius2);
  
  @override
  bool circleRectangle(Vector2D center, num radius, RectangleD rec)
    => rl.CoreD.CheckCollisionCircleRec(center, radius, rec);
  
  @override
  bool rectangles(RectangleD rec1, RectangleD rec2)
    => rl.CoreD.CheckCollisionRecs(rec1, rec2);

  @override
  bool pointRectangle(Vector2D point, RectangleD rec)
    => rl.CoreD.CheckCollisionPointRec(point, rec);
}

class RaylibAssetManager extends AssetManager {
  final Raylib rl;

  RaylibAssetManager(this.rl);

  final Map<String, ImageD> _images = {};
  final Map<String, TextureD> _textures = {};
  final Map<String, FontD> _fonts = {};

  @override
  ImageD image(String id, {String? path}) {
    var existing = _images[id] ?? _images[path];
    if (existing != null) return existing;
    return _images[id] = rl.CoreD.LoadImage(path ?? id);
  }

  @override
  TextureD texture(String id, {String? path}) {
    var existing = _textures[id] ?? _textures[path];
    if (existing != null) return existing;
    return _textures[id] = rl.CoreD.LoadTexture(path ?? id);
  }

  @override
  FontD font(String id, {String? path, int fontSize = 32}) {
    var existing = _fonts[id] ?? _fonts[path];
    if (existing != null) return existing;
    return _fonts[id] = rl.CoreD.LoadFontEx(path ?? id, fontSize);
  }

  @override
  void dispose() {
    _textures.values.forEach(rl.CoreD.UnloadTexture);
    _images.values.forEach(rl.CoreD.UnloadImage);
    _fonts.values.forEach(rl.CoreD.UnloadFont);
  }
}

class RaylibBackend extends UnhingedBackend {
  final Raylib rl;

  RaylibBackend(this.rl) : super(
    render: RaylibRenderBackend(rl),
    input: RaylibInputBackend(rl),
    collision: RaylibCollisionBackend(rl),
    assets: RaylibAssetManager(rl),
  );
  
  @override
  void beginFrame() => mouse = rl.CoreD.GetMouseInfo();

  @override
  double getFrameTime() => rl.CoreD.GetFrameTime();

  @override
  void setMouseCursor(MouseCursor cursor)
    => rl.CoreD.SetMouseCursor(cursor);

  @override
  void setClipboardText(String text)
    => rl.CoreD.SetClipboardText(text);

  @override
  String getClipboardText()
    // ignore: deprecated_member_use
    => rl.CoreD.GetClipboardText();

  @override
  void setTargetFPS(int fps) => rl.CoreD.SetTargetFPS(fps);

  @override
  FontD getFontDefault() => rl.CoreD.GetFontDefault();

  @override
  void dispose() {
    super.dispose();
    rl.dispose();
  }
}