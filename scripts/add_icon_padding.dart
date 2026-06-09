import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  // Read the original image
  final originalImage = File('assets/images/name_2.png');
  
  if (!await originalImage.exists()) {
    print('Error: Original image not found at assets/images/name_2.png');
    exit(1);
  }

  final bytes = await originalImage.readAsBytes();
  final image = img.decodeImage(bytes);

  if (image == null) {
    print('Error: Could not decode image');
    exit(1);
  }

  print('Original image: ${image.width}x${image.height}');

  // Make the final image square (1:1 aspect ratio) for best launcher icon appearance
  // Add equal padding on all sides to center the logo in a square
  final targetSize = (image.width * 1.2).round(); // 20% larger than width
  final newWidth = targetSize;
  final newHeight = targetSize;

  print('New image: ${newWidth}x${newHeight}');

  // Create a new image with white background
  final paddedImage = img.Image(width: newWidth, height: newHeight);
  
  // Fill with white background
  img.fill(paddedImage, color: img.ColorRgb8(255, 255, 255));

  // Calculate position to center the original image
  final x = ((newWidth - image.width) / 2).round();
  final y = ((newHeight - image.height) / 2).round();

  // Draw the original image onto the new image using composite
  img.compositeImage(paddedImage, image, dstX: x, dstY: y);

  // Save the padded image
  final outputFile = File('assets/images/name_padded.png');
  await outputFile.writeAsBytes(img.encodePng(paddedImage));

  print('✓ Padded image saved to assets/images/name_padded.png');
  print('  Square icon with 20% padding around the logo');
  print('\nNow run: flutter pub run flutter_launcher_icons');
}
