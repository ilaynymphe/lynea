import 'package:flutter/material.dart';
import 'platform_image_io.dart' if (dart.library.html) 'platform_image_web.dart';

Widget buildPickedImage(String path, {BoxFit fit = BoxFit.cover}) {
  return getPlatformImage(path, fit: fit);
}