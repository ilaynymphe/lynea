import 'package:flutter/material.dart';

Widget getPlatformImage(String path, {BoxFit fit = BoxFit.cover}) {
  return Image.network(path, fit: fit);
}