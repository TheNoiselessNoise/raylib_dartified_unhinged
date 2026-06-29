part of '../raylib_dartified_unhinged.dart';

class AssetManager<T extends App<T>> extends AppService<T> {
  AssetManager(super.app);

  final Map<String, ImageD> _images = {};
  final Map<String, TextureD> _textures = {};
  final Map<String, FontD> _fonts = {};

  ImageD image(String id, {String? path}) {
    var existing = _images[id] ?? _images[path];
    if (existing != null) return existing;
    return _images[id] = rl.CoreD.LoadImage(path ?? id);
  }

  TextureD texture(String id, {String? path}) {
    var existing = _textures[id] ?? _textures[path];
    if (existing != null) return existing;
    return _textures[id] = rl.CoreD.LoadTexture(path ?? id);
  }

  FontD font(String id, {String? path, int fontSize = 32}) {
    var existing = _fonts[id] ?? _fonts[path];
    if (existing != null) return existing;
    return _fonts[id] = rl.CoreD.LoadFontEx(path ?? id, fontSize);
  }

  @override
  void _doOnDispose() {
    _textures.values.forEach(rl.CoreD.UnloadTexture);
    _images.values.forEach(rl.CoreD.UnloadImage);
    _fonts.values.forEach(rl.CoreD.UnloadFont);
    super._doOnDispose();
  }
}