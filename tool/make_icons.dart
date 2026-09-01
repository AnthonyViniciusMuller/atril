// Atril's application icon, drawn rather than committed as artwork.
//
// Six targets want the same mark at twenty-nine sizes, in three container
// formats, and two of them care about the alpha channel: the App Store refuses
// a marketing icon that carries one, and an Android adaptive foreground is
// nothing but one. A directory of exported PNGs would answer that with
// twenty-nine files nobody can regenerate — the next size is a design tool
// somebody no longer has, and a colour change is twenty-nine re-exports.
//
// So the mark is geometry, this program is the renderer, and `make icons`
// rewrites every file from it. The PNGs are still committed, because a build
// must not depend on a generator having been run, and CI checks them the way
// it checks every other generated artefact in this repository.
//
// The mark is a lectern: the two leaves of an open book above the post and the
// foot that hold it at reading height. It is what an *atril* is, and it is
// drawn as four convex polygons so that the whole thing survives being 16
// pixels wide — a top mass, a gap, a stem, a bar.

import 'dart:io';
import 'dart:typed_data';

/// The ink the mark sits on, and the parchment it is drawn in.
///
/// They are the two colours `web/manifest.json` names as well, so a browser
/// painting the splash before the app has loaded paints the icon's own ground
/// rather than the template's blue.
const List<int> _ink = <int>[0x1B, 0x24, 0x30];
const List<int> _parchment = <int>[0xE9, 0xD8, 0xB4];

/// The corner of a rounded square, as a fraction of its side.
const double _cornerRadius = 0.22;

/// How much of the icon the mark is allowed, in the three framings that exist.
///
/// A plain icon is drawn inside its own rounded square and can use most of it.
/// A maskable one is cropped by whatever shape the launcher chooses, so its
/// content has to sit inside the central 80% circle the specification
/// guarantees; an Android adaptive foreground is cropped harder still, since
/// the outer ring is what the system parallaxes.
const double _framedScale = 0.64;
const double _appleScale = 0.64;
const double _maskableScale = 0.52;
const double _adaptiveScale = 0.50;

void main(List<String> arguments) {
  final root = Directory.current;
  var written = 0;

  void write(String path, List<int> bytes) {
    final file = File('${root.path}/$path');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes);
    written++;
  }

  // The browser. `favicon.png` is 32 rather than the template's 16 because a
  // tab on a hidpi display asks for the larger one and upscales when it is
  // absent.
  write('web/favicon.png', encodePng(framedIcon(32)));
  write('web/icons/Icon-192.png', encodePng(framedIcon(192)));
  write('web/icons/Icon-512.png', encodePng(framedIcon(512)));
  write(
    'web/icons/Icon-maskable-192.png',
    encodePng(squareIcon(192, _maskableScale)),
  );
  write(
    'web/icons/Icon-maskable-512.png',
    encodePng(squareIcon(512, _maskableScale)),
  );

  // Android, twice over. The legacy bitmap is what API 24 and 25 show — this
  // app's `minSdk` — and the adaptive pair is what everything since API 26
  // masks into the launcher's own shape.
  const legacyDensities = <String, int>{
    'mdpi': 48,
    'hdpi': 72,
    'xhdpi': 96,
    'xxhdpi': 144,
    'xxxhdpi': 192,
  };
  const adaptiveDensities = <String, int>{
    'mdpi': 108,
    'hdpi': 162,
    'xhdpi': 216,
    'xxhdpi': 324,
    'xxxhdpi': 432,
  };
  legacyDensities.forEach((density, size) {
    write(
      'android/app/src/main/res/mipmap-$density/ic_launcher.png',
      encodePng(framedIcon(size)),
    );
  });
  adaptiveDensities.forEach((density, size) {
    write(
      'android/app/src/main/res/mipmap-$density/ic_launcher_foreground.png',
      encodePng(adaptiveForeground(size)),
    );
  });

  // iOS. Every one of these is written without an alpha channel: App Store
  // Connect rejects a marketing icon that carries one, and there is no reason
  // for the rest of the set to differ from it.
  const appleSizes = <String, int>{
    'Icon-App-20x20@1x': 20,
    'Icon-App-20x20@2x': 40,
    'Icon-App-20x20@3x': 60,
    'Icon-App-29x29@1x': 29,
    'Icon-App-29x29@2x': 58,
    'Icon-App-29x29@3x': 87,
    'Icon-App-40x40@1x': 40,
    'Icon-App-40x40@2x': 80,
    'Icon-App-40x40@3x': 120,
    'Icon-App-60x60@2x': 120,
    'Icon-App-60x60@3x': 180,
    'Icon-App-76x76@1x': 76,
    'Icon-App-76x76@2x': 152,
    'Icon-App-83.5x83.5@2x': 167,
    'Icon-App-1024x1024@1x': 1024,
  };
  appleSizes.forEach((name, size) {
    // iOS applies its own corner, so the icon it is handed is a full square.
    write(
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/$name.png',
      encodePng(squareIcon(size, _appleScale), opaque: true),
    );
  });

  // macOS rounds its own corner too, but the asset it is handed is inset:
  // the system draws the app icon at about 80% of the tile.
  const macSizes = <int>[16, 32, 64, 128, 256, 512, 1024];
  for (final size in macSizes) {
    write(
      'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_$size.png',
      encodePng(framedIcon(size)),
    );
  }

  // Windows wants one container holding every size the shell might ask for.
  write(
    'windows/runner/resources/app_icon.ico',
    encodeIco(<Bitmap>[
      for (final size in <int>[16, 24, 32, 48, 64, 128, 256]) framedIcon(size),
    ]),
  );

  // The two desktop packages want the icon as a file of their own rather than
  // inside the bundle: the Flatpak manifest installs one into the icon theme,
  // and `msix` derives every Windows tile size from the other.
  write('packaging/linux/dev.quire.atril.png', encodePng(framedIcon(512)));
  write('packaging/windows/dev.quire.atril.png', encodePng(framedIcon(512)));

  stdout.writeln('wrote $written icon files');
}

/// The mark on its own rounded square, for a platform that does not mask.
Bitmap framedIcon(int size) {
  final bitmap = Bitmap(size, size)
    ..fillShape(_scale(roundedSquare(_cornerRadius), size), _ink)
    ..fillShape(_scale(lectern(_framedScale), size), _parchment);
  return bitmap;
}

/// The mark on a full-bleed square, for a platform that applies its own shape.
///
/// [scale] is what the platform's own crop leaves usable: Apple rounds a
/// corner and nothing more, while a maskable web icon has to survive a
/// launcher choosing a circle, which is the central 80% of the square.
Bitmap squareIcon(int size, double scale) {
  final bitmap = Bitmap(size, size)
    ..fillShape(_scale(roundedSquare(0), size), _ink)
    ..fillShape(_scale(lectern(scale), size), _parchment);
  return bitmap;
}

/// The mark alone, for an Android adaptive icon's foreground layer.
///
/// The background is a colour resource rather than a second bitmap, so this
/// layer is the mark and the transparency around it — which is also what makes
/// it usable as the monochrome layer a themed launcher tints.
Bitmap adaptiveForeground(int size) =>
    Bitmap(size, size)
      ..fillShape(_scale(lectern(_adaptiveScale), size), _parchment);

/// A point in the unit square the mark is described in, y downwards.
class Point {
  const Point(this.x, this.y);

  final double x;
  final double y;
}

/// The lectern, as polygons in the unit square, occupying [scale] of it.
///
/// A slab in perspective — narrower at the far edge — over the ledge a book
/// rests against, on a post and a foot. The spine down the middle is a hole
/// rather than a second colour: it is wound against the slab, so the shape
/// carries it whether what shows through is the ink behind the mark or the
/// transparency of an Android foreground layer.
List<List<Point>> lectern(double scale) {
  const shape = <List<Point>>[
    // The desk, seen from the side it is read from: a board tilted towards
    // the reader rather than a panel facing them. A symmetric trapezoid on a
    // post is a lamp; the tilt is the whole difference.
    <Point>[
      Point(0.100, 0.355),
      Point(0.680, 0.095),
      Point(0.900, 0.245),
      Point(0.320, 0.505),
    ],
    // The ledge across the low end, which is what stops a book sliding off.
    <Point>[
      Point(0.320, 0.505),
      Point(0.100, 0.355),
      Point(0.055, 0.425),
      Point(0.275, 0.575),
    ],
    // The post. Its top is above the board's near edge at both of its own
    // sides, so the join is hidden rather than showing a step where the
    // rectangle crosses the slope.
    <Point>[
      Point(0.440, 0.380),
      Point(0.560, 0.380),
      Point(0.560, 0.865),
      Point(0.440, 0.865),
    ],
    // The foot.
    <Point>[
      Point(0.195, 0.865),
      Point(0.805, 0.865),
      Point(0.805, 1.000),
      Point(0.195, 1.000),
    ],
  ];

  // The drawing occupies y 0.095 to 1.0 of its own box, so centring the box
  // would hang the mark low. The offset below centres what is actually drawn.
  const drawnCentre = (0.095 + 1.000) / 2;
  final left = (1 - scale) / 2;
  final top = 0.5 - drawnCentre * scale;
  return <List<Point>>[
    for (final polygon in shape)
      <Point>[
        for (final point in polygon)
          Point(left + point.x * scale, top + point.y * scale),
      ],
  ];
}

/// The unit square, with a corner of [radius] side-fractions.
List<List<Point>> roundedSquare(double radius) {
  if (radius <= 0) {
    return const <List<Point>>[
      <Point>[Point(0, 0), Point(1, 0), Point(1, 1), Point(0, 1)],
    ];
  }
  const segments = 16;
  final points = <Point>[];
  // The four corner centres, walked clockwise from the top left.
  const centres = <Point>[Point(0, 0), Point(1, 0), Point(1, 1), Point(0, 1)];
  const startAngles = <double>[
    3.141592653589793,
    -1.5707963267948966,
    0,
    1.5707963267948966,
  ];
  for (var corner = 0; corner < 4; corner++) {
    final centre = centres[corner];
    final cx = centre.x == 0 ? radius : 1 - radius;
    final cy = centre.y == 0 ? radius : 1 - radius;
    for (var step = 0; step <= segments; step++) {
      final angle =
          startAngles[corner] + (step / segments) * 1.5707963267948966;
      points.add(Point(cx + radius * _cos(angle), cy + radius * _sin(angle)));
    }
  }
  return <List<Point>>[points];
}

List<List<Point>> _scale(List<List<Point>> polygons, int size) => <List<Point>>[
  for (final polygon in polygons)
    <Point>[for (final point in polygon) Point(point.x * size, point.y * size)],
];

double _cos(double radians) => _sin(radians + 1.5707963267948966);

/// Enough of a sine to place sixty-four points on four arcs.
double _sin(double radians) {
  const twoPi = 6.283185307179586;
  var x = radians % twoPi;
  if (x > 3.141592653589793) {
    x -= twoPi;
  } else if (x < -3.141592653589793) {
    x += twoPi;
  }
  final x2 = x * x;
  // Taylor series to the ninth power, which is exact to about 1e-9 over the
  // range above and is what keeps this file free of a dependency on dart:math
  // for two functions.
  return x *
      (1 -
          x2 /
              6 *
              (1 - x2 / 20 * (1 - x2 / 42 * (1 - x2 / 72 * (1 - x2 / 110)))));
}

/// A non-premultiplied RGBA raster the shapes are composited into.
class Bitmap {
  Bitmap(this.width, this.height) : pixels = Uint8List(width * height * 4);

  final int width;
  final int height;
  final Uint8List pixels;

  /// Vertical subsamples per output row.
  ///
  /// The horizontal coverage of a span is computed exactly, so the only
  /// direction that needs sampling is the one the scanline moves in. Eight is
  /// where a 16-pixel icon's diagonals stop showing steps.
  static const int _subSamples = 8;

  /// Fills the union of [polygons] with [colour], antialiased.
  ///
  /// The winding is non-zero rather than even-odd, so the four overlapping
  /// pieces of the mark are one shape and the seams between them do not show
  /// as half-covered pixels.
  void fillShape(List<List<Point>> polygons, List<int> colour) {
    final edges = <Float64List>[];
    for (final polygon in polygons) {
      for (var i = 0; i < polygon.length; i++) {
        final a = polygon[i];
        final b = polygon[(i + 1) % polygon.length];
        if (a.y != b.y) {
          edges.add(Float64List.fromList(<double>[a.x, a.y, b.x, b.y]));
        }
      }
    }

    final coverage = Float64List(width);
    final crossings = <_Crossing>[];
    for (var row = 0; row < height; row++) {
      coverage.fillRange(0, width, 0);
      for (var sub = 0; sub < _subSamples; sub++) {
        final y = row + (sub + 0.5) / _subSamples;
        crossings.clear();
        for (final edge in edges) {
          final y0 = edge[1];
          final y1 = edge[3];
          final lower = y0 < y1 ? y0 : y1;
          final upper = y0 < y1 ? y1 : y0;
          if (y < lower || y >= upper) {
            continue;
          }
          crossings.add(
            _Crossing(
              edge[0] + (y - y0) * (edge[2] - edge[0]) / (y1 - y0),
              y1 > y0 ? 1 : -1,
            ),
          );
        }
        if (crossings.length < 2) {
          continue;
        }
        crossings.sort((a, b) => a.x.compareTo(b.x));
        var winding = 0;
        for (var i = 0; i < crossings.length - 1; i++) {
          winding += crossings[i].direction;
          if (winding != 0) {
            _addSpan(coverage, crossings[i].x, crossings[i + 1].x);
          }
        }
      }
      _composite(row, coverage, colour);
    }
  }

  void _addSpan(Float64List coverage, double from, double to) {
    final start = from < 0 ? 0.0 : from;
    final end = to > width ? width.toDouble() : to;
    if (end <= start) {
      return;
    }
    for (var x = start.floor(); x < end.ceil(); x++) {
      final left = x > start ? x.toDouble() : start;
      final right = x + 1 < end ? (x + 1).toDouble() : end;
      if (right > left) {
        coverage[x] += (right - left) / _subSamples;
      }
    }
  }

  void _composite(int row, Float64List coverage, List<int> colour) {
    for (var x = 0; x < width; x++) {
      final alpha = coverage[x].clamp(0.0, 1.0);
      if (alpha <= 0) {
        continue;
      }
      final i = (row * width + x) * 4;
      final destination = pixels[i + 3] / 255;
      final out = alpha + destination * (1 - alpha);
      final keep = destination * (1 - alpha);
      for (var channel = 0; channel < 3; channel++) {
        pixels[i + channel] =
            ((colour[channel] * alpha + pixels[i + channel] * keep) / out)
                .round()
                .clamp(0, 255);
      }
      pixels[i + 3] = (out * 255).round().clamp(0, 255);
    }
  }
}

class _Crossing {
  const _Crossing(this.x, this.direction);

  final double x;
  final int direction;
}

/// Encodes [bitmap] as a PNG.
///
/// [opaque] drops the alpha channel rather than setting it to 255: an iOS icon
/// carrying one is rejected on upload, and a channel that is present and
/// constant is still present.
List<int> encodePng(Bitmap bitmap, {bool opaque = false}) {
  final channels = opaque ? 3 : 4;
  final raw = Uint8List(bitmap.height * (1 + bitmap.width * channels));
  var offset = 0;
  for (var y = 0; y < bitmap.height; y++) {
    raw[offset++] = 0; // filter: none
    for (var x = 0; x < bitmap.width; x++) {
      final i = (y * bitmap.width + x) * 4;
      raw[offset++] = bitmap.pixels[i];
      raw[offset++] = bitmap.pixels[i + 1];
      raw[offset++] = bitmap.pixels[i + 2];
      if (!opaque) {
        raw[offset++] = bitmap.pixels[i + 3];
      }
    }
  }

  final header = BytesBuilder()
    ..add(_be32(bitmap.width))
    ..add(_be32(bitmap.height))
    ..addByte(8)
    ..addByte(opaque ? 2 : 6)
    ..addByte(0)
    ..addByte(0)
    ..addByte(0);

  final png = BytesBuilder()
    ..add(const <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
    ..add(_chunk('IHDR', header.takeBytes()))
    ..add(_chunk('IDAT', ZLibCodec(level: 9).encode(raw)))
    ..add(_chunk('IEND', const <int>[]));
  return png.takeBytes();
}

/// Encodes [bitmaps] as a Windows icon.
///
/// Each entry is a bottom-up 32-bit DIB rather than an embedded PNG. Both are
/// legal since Vista and the PNG form is smaller, but the shell's smallest
/// caches still read the DIB form on every Windows this app targets, and an
/// icon that renders on one surface and not another is worse than a few
/// hundred kilobytes.
List<int> encodeIco(List<Bitmap> bitmaps) {
  final images = <Uint8List>[];
  for (final bitmap in bitmaps) {
    final maskStride = ((bitmap.width + 31) ~/ 32) * 4;
    final body = BytesBuilder()
      ..add(_le32(40))
      ..add(_le32(bitmap.width))
      ..add(_le32(bitmap.height * 2)) // colour rows plus mask rows
      ..add(_le16(1))
      ..add(_le16(32))
      ..add(_le32(0))
      ..add(
        _le32(bitmap.width * bitmap.height * 4 + maskStride * bitmap.height),
      )
      ..add(_le32(0))
      ..add(_le32(0))
      ..add(_le32(0))
      ..add(_le32(0));
    for (var y = bitmap.height - 1; y >= 0; y--) {
      for (var x = 0; x < bitmap.width; x++) {
        final i = (y * bitmap.width + x) * 4;
        body
          ..addByte(bitmap.pixels[i + 2])
          ..addByte(bitmap.pixels[i + 1])
          ..addByte(bitmap.pixels[i])
          ..addByte(bitmap.pixels[i + 3]);
      }
    }
    // The AND mask is unused by a 32-bit entry and still has to be there.
    body.add(Uint8List(maskStride * bitmap.height));
    images.add(body.takeBytes());
  }

  final directory = BytesBuilder()
    ..add(_le16(0))
    ..add(_le16(1))
    ..add(_le16(bitmaps.length));
  var offset = 6 + 16 * bitmaps.length;
  for (var i = 0; i < bitmaps.length; i++) {
    directory
      ..addByte(bitmaps[i].width >= 256 ? 0 : bitmaps[i].width)
      ..addByte(bitmaps[i].height >= 256 ? 0 : bitmaps[i].height)
      ..addByte(0)
      ..addByte(0)
      ..add(_le16(1))
      ..add(_le16(32))
      ..add(_le32(images[i].length))
      ..add(_le32(offset));
    offset += images[i].length;
  }

  final file = BytesBuilder()..add(directory.takeBytes());
  for (final image in images) {
    file.add(image);
  }
  return file.takeBytes();
}

List<int> _chunk(String type, List<int> data) {
  final body = BytesBuilder()
    ..add(type.codeUnits)
    ..add(data);
  final bytes = body.takeBytes();
  final chunk = BytesBuilder()
    ..add(_be32(data.length))
    ..add(bytes)
    ..add(_be32(_crc32(bytes)));
  return chunk.takeBytes();
}

List<int> _be32(int value) => <int>[
  (value >> 24) & 0xFF,
  (value >> 16) & 0xFF,
  (value >> 8) & 0xFF,
  value & 0xFF,
];

List<int> _le32(int value) => <int>[
  value & 0xFF,
  (value >> 8) & 0xFF,
  (value >> 16) & 0xFF,
  (value >> 24) & 0xFF,
];

List<int> _le16(int value) => <int>[value & 0xFF, (value >> 8) & 0xFF];

final Uint32List _crcTable = () {
  final table = Uint32List(256);
  for (var i = 0; i < 256; i++) {
    var c = i;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
    }
    table[i] = c;
  }
  return table;
}();

int _crc32(List<int> bytes) {
  var crc = 0xFFFFFFFF;
  for (final byte in bytes) {
    crc = _crcTable[(crc ^ byte) & 0xFF] ^ (crc >> 8);
  }
  return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}
