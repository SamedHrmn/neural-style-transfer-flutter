import 'package:flutter/material.dart';
import 'package:style_transfer_client/utils/image_util.dart';

class AppMemoryImage extends StatelessWidget {
  const AppMemoryImage({super.key, required this.base64Str});

  final String base64Str;

  @override
  Widget build(BuildContext context) {
    return Image.memory(
      ImageUtil.decodeBase64(base64Str),
      fit: BoxFit.cover,
    );
  }
}
