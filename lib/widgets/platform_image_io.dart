import 'dart:io';
import 'package:flutter/material.dart';

Widget getPlatformImage(String path, {BoxFit fit = BoxFit.cover}) {
  return Image.file(File(path), fit: fit);
}