import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CacheImage extends StatelessWidget {
  const CacheImage({super.key, required this.url, this.size = 48});
  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      width: size,
      height: size,
      imageUrl: url,
      httpHeaders: const {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
      },
      placeholder: (context, url) => Image.asset(
        'assets/images/load_img.jpeg',
        fit: BoxFit.cover,
      ),
      errorWidget: (context, url, error) => Image.asset(
        'assets/images/load_img.jpeg',
        fit: BoxFit.cover,
      ),
      fit: BoxFit.cover, // Ensure the image fits within the provided dimensions
    );
  }
}
