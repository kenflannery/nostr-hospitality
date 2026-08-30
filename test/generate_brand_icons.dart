// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

/// Generates clean, modern, flat Sage & Lavender brand assets for Hospitality Libre.
void main() {
  print('Generating clean Sage & Lavender brand assets for Hospitality Libre...');

  final brandingDir = Directory('assets/branding');
  if (!brandingDir.existsSync()) {
    brandingDir.createSync(recursive: true);
  }

  // 1. Generate SVG master
  final svgContent = _generateSvg(512);
  File('assets/branding/logo.svg').writeAsStringSync(svgContent);
  print('Generated assets/branding/logo.svg');

  // 2. Generate Web PNGs
  _generateAndSavePng(512, 'web/icons/Icon-512.png');
  _generateAndSavePng(512, 'web/icons/Icon-maskable-512.png', isMaskable: true);
  _generateAndSavePng(192, 'web/icons/Icon-192.png');
  _generateAndSavePng(192, 'web/icons/Icon-maskable-192.png', isMaskable: true);
  _generateAndSavePng(64, 'web/favicon.png');
  _generateAndSavePng(512, 'assets/branding/logo.png');

  // 3. Generate Android Launcher Icons
  _generateAndSavePng(48, 'android/app/src/main/res/mipmap-mdpi/ic_launcher.png');
  _generateAndSavePng(72, 'android/app/src/main/res/mipmap-hdpi/ic_launcher.png');
  _generateAndSavePng(96, 'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png');
  _generateAndSavePng(144, 'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png');
  _generateAndSavePng(192, 'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png');

  print('All clean Sage & Lavender brand assets successfully generated!');
}

/// Brand Palette:
/// Sage:     #749681 (rgb: 116, 150, 129)
/// Lavender: #9D8EC2 (rgb: 157, 142, 194)
/// Dark BG:  #151C18 (rgb: 21, 28, 24)
/// Slate:    #2A362F (rgb: 42, 54, 47)
String _generateSvg(int size) {
  return '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $size $size" width="$size" height="$size">
  <!-- Minimal Dark Sage Container -->
  <rect width="$size" height="$size" rx="${size * 0.24}" fill="#151C18"/>
  
  <!-- Subtle Framing Line -->
  <rect x="${size * 0.02}" y="${size * 0.02}" width="${size * 0.96}" height="${size * 0.96}" rx="${size * 0.22}" fill="none" stroke="#25322B" stroke-width="2"/>

  <!-- Minimal Sage Shelter Chevron (Clean Gable Roof) -->
  <path d="M ${size * 0.22} ${size * 0.44} L ${size * 0.50} ${size * 0.22} L ${size * 0.78} ${size * 0.44}" 
        fill="none" 
        stroke="#749681" 
        stroke-width="${size * 0.085}" 
        stroke-linecap="round" 
        stroke-linejoin="round"/>

  <!-- Minimal Lavender Open Archway (Welcoming Hospitality Door) -->
  <path d="M ${size * 0.35} ${size * 0.76} L ${size * 0.35} ${size * 0.54} C ${size * 0.35} ${size * 0.45}, ${size * 0.65} ${size * 0.45}, ${size * 0.65} ${size * 0.54} L ${size * 0.65} ${size * 0.76}" 
        fill="none" 
        stroke="#9D8EC2" 
        stroke-width="${size * 0.075}" 
        stroke-linecap="round" 
        stroke-linejoin="round"/>

  <!-- Sovereign Keypoint Core in Lavender -->
  <circle cx="${size * 0.50}" cy="${size * 0.55}" r="${size * 0.045}" fill="#9D8EC2"/>
</svg>''';
}

void _generateAndSavePng(int size, String outputPath, {bool isMaskable = false}) {
  final bytes = _renderRasterPng(size, isMaskable: isMaskable);
  final file = File(outputPath);
  if (!file.parent.existsSync()) {
    file.parent.createSync(recursive: true);
  }
  file.writeAsBytesSync(bytes);
  print('Saved $outputPath (${size}x$size)');
}

Uint8List _renderRasterPng(int size, {bool isMaskable = false}) {
  final rgba = Uint8List(size * size * 4);
  final cornerRadius = isMaskable ? 0.0 : size * 0.24;

  // Colors
  const bgR = 21, bgG = 28, bgB = 24; // #151C18
  const sageR = 116, sageG = 150, sageB = 129; // #749681
  const lavR = 157, lavG = 142, lavB = 194; // #9D8EC2

  // Geometry parameters in normalized units [0..1]
  final strokeRoof = 0.085;
  final strokeDoor = 0.075;

  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      final index = (y * size + x) * 4;

      // Rounded container clipping
      if (!isMaskable) {
        final double dx = (x < cornerRadius)
            ? cornerRadius - x
            : (x > size - 1 - cornerRadius)
                ? x - (size - 1 - cornerRadius)
                : 0.0;
        final double dy = (y < cornerRadius)
            ? cornerRadius - y
            : (y > size - 1 - cornerRadius)
                ? y - (size - 1 - cornerRadius)
                : 0.0;

        if (dx > 0 && dy > 0) {
          final dist = sqrt(dx * dx + dy * dy);
          if (dist > cornerRadius) {
            rgba[index] = 0;
            rgba[index + 1] = 0;
            rgba[index + 2] = 0;
            rgba[index + 3] = 0;
            continue;
          }
        }
      }

      final nx = x / size.toDouble();
      final ny = y / size.toDouble();

      int r = bgR;
      int g = bgG;
      int b = bgB;
      int a = 255;

      // 1. Distance to Sage Gable Roof (two line segments: (0.22, 0.44) -> (0.50, 0.22) and (0.50, 0.22) -> (0.78, 0.44))
      final dLeft = _distToSegment(nx, ny, 0.22, 0.44, 0.50, 0.22);
      final dRight = _distToSegment(nx, ny, 0.50, 0.22, 0.78, 0.44);
      final dRoof = min(dLeft, dRight);

      // 2. Distance to Lavender Door Arch:
      // Vertical left post (0.35, 0.54) to (0.35, 0.76)
      final dDoorL = _distToSegment(nx, ny, 0.35, 0.54, 0.35, 0.76);
      // Vertical right post (0.65, 0.54) to (0.65, 0.76)
      final dDoorR = _distToSegment(nx, ny, 0.65, 0.54, 0.65, 0.76);
      // Door top arc: center (0.50, 0.54), radius 0.15, for ny <= 0.54
      double dDoorArc = 10.0;
      if (ny <= 0.54) {
        final distCenter = sqrt(pow(nx - 0.50, 2) + pow(ny - 0.54, 2));
        dDoorArc = (distCenter - 0.15).abs();
      }
      final dDoor = min(min(dDoorL, dDoorR), dDoorArc);

      // 3. Central Dot / Beacon: center (0.50, 0.55), radius 0.045
      final dDot = sqrt(pow(nx - 0.50, 2) + pow(ny - 0.55, 2));

      // Anti-aliased rendering
      final halfStrokeRoof = strokeRoof / 2.0;
      final halfStrokeDoor = strokeDoor / 2.0;
      final pxSize = 1.0 / size.toDouble();

      if (dDot <= 0.045) {
        r = lavR;
        g = lavG;
        b = lavB;
      } else if (dDoor <= halfStrokeDoor) {
        final edgeFactor = ((halfStrokeDoor - dDoor) / (pxSize * 1.5)).clamp(0.0, 1.0);
        r = (lavR * edgeFactor + bgR * (1 - edgeFactor)).toInt();
        g = (lavG * edgeFactor + bgG * (1 - edgeFactor)).toInt();
        b = (lavB * edgeFactor + bgB * (1 - edgeFactor)).toInt();
      } else if (dRoof <= halfStrokeRoof) {
        final edgeFactor = ((halfStrokeRoof - dRoof) / (pxSize * 1.5)).clamp(0.0, 1.0);
        r = (sageR * edgeFactor + bgR * (1 - edgeFactor)).toInt();
        g = (sageG * edgeFactor + bgG * (1 - edgeFactor)).toInt();
        b = (sageB * edgeFactor + bgB * (1 - edgeFactor)).toInt();
      }

      rgba[index] = r;
      rgba[index + 1] = g;
      rgba[index + 2] = b;
      rgba[index + 3] = a;
    }
  }

  return _encodePng(size, size, rgba);
}

double _distToSegment(double px, double py, double x1, double y1, double x2, double y2) {
  final l2 = pow(x2 - x1, 2) + pow(y2 - y1, 2);
  if (l2 == 0) return sqrt(pow(px - x1, 2) + pow(py - y1, 2));
  final t = max(0.0, min(1.0, ((px - x1) * (x2 - x1) + (py - y1) * (y2 - y1)) / l2));
  final projX = x1 + t * (x2 - x1);
  final projY = y1 + t * (y2 - y1);
  return sqrt(pow(px - projX, 2) + pow(py - projY, 2));
}

/// Standard uncompressed/DEFLATE PNG encoder.
Uint8List _encodePng(int width, int height, Uint8List rgba) {
  final buffer = BytesBuilder();
  buffer.add([137, 80, 78, 71, 13, 10, 26, 10]);

  final ihdrData = ByteData(13);
  ihdrData.setUint32(0, width);
  ihdrData.setUint32(4, height);
  ihdrData.setUint8(8, 8);
  ihdrData.setUint8(9, 6);
  ihdrData.setUint8(10, 0);
  ihdrData.setUint8(11, 0);
  ihdrData.setUint8(12, 0);
  _writeChunk(buffer, 'IHDR', ihdrData.buffer.asUint8List());

  final rawScanlines = BytesBuilder();
  final rowBytes = width * 4;
  for (int y = 0; y < height; y++) {
    rawScanlines.addByte(0);
    rawScanlines.add(rgba.sublist(y * rowBytes, (y + 1) * rowBytes));
  }

  final compressed = zlib.encode(rawScanlines.toBytes());
  _writeChunk(buffer, 'IDAT', Uint8List.fromList(compressed));
  _writeChunk(buffer, 'IEND', Uint8List(0));

  return buffer.toBytes();
}

void _writeChunk(BytesBuilder builder, String type, Uint8List data) {
  final chunkLen = ByteData(4)..setUint32(0, data.length);
  builder.add(chunkLen.buffer.asUint8List());

  final typeBytes = Uint8List.fromList(type.codeUnits);
  builder.add(typeBytes);
  builder.add(data);

  final crcData = Uint8List(typeBytes.length + data.length);
  crcData.setRange(0, typeBytes.length, typeBytes);
  crcData.setRange(typeBytes.length, crcData.length, data);

  final crcVal = _crc32(crcData);
  final crcBytes = ByteData(4)..setUint32(0, crcVal);
  builder.add(crcBytes.buffer.asUint8List());
}

int _crc32(Uint8List data) {
  int crc = 0xFFFFFFFF;
  for (final byte in data) {
    crc ^= byte;
    for (int j = 0; j < 8; j++) {
      if ((crc & 1) != 0) {
        crc = (crc >>> 1) ^ 0xEDB88320;
      } else {
        crc = crc >>> 1;
      }
    }
  }
  return crc ^ 0xFFFFFFFF;
}
