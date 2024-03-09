library dart_geohash;

import 'dart:typed_data';

/// A list of possible directions of neighboring geohash.
enum Direction {
  NORTH,
  NORTHEAST,
  EAST,
  SOUTHEAST,
  SOUTH,
  SOUTHWEST,
  WEST,
  NORTHWEST,
  CENTRAL,
}

enum _Direction4 {
  NORTH,
  SOUTH,
  EAST,
  WEST,
}

/// A class that can convert a geohash String to [Longitude, Latitude] and back.
class GeoHasher {
  static final String _baseSequence = '0123456789bcdefghjkmnpqrstuvwxyz';

  /// Creates a Map of available characters for a geohash
  static final _base32Map = <String, int>{
    for (var value in _baseSequence.split(''))
      value: _baseSequence.indexOf(value),
  };

  /// Creates a reversed Map of available characters for a geohash
  static final _base32MapR = <int, String>{
    for (var value in _baseSequence.split(''))
      _baseSequence.indexOf(value): value,
  };

  static final _neighbor = <_Direction4, List<String>>{
    _Direction4.NORTH: [
      'p0r21436x8zb9dcf5h7kjnmqesgutwvy',
      'bc01fg45238967deuvhjyznpkmstqrwx'
    ],
    _Direction4.SOUTH: [
      '14365h7k9dcfesgujnmqp0r2twvyx8zb',
      '238967debc01fg45kmstqrwxuvhjyznp'
    ],
    _Direction4.EAST: [
      'bc01fg45238967deuvhjyznpkmstqrwx',
      'p0r21436x8zb9dcf5h7kjnmqesgutwvy'
    ],
    _Direction4.WEST: [
      '238967debc01fg45kmstqrwxuvhjyznp',
      '14365h7k9dcfesgujnmqp0r2twvyx8zb'
    ],
  };

  static final _border = <_Direction4, List<String>>{
    _Direction4.NORTH: ['prxz', 'bcfguvyz'],
    _Direction4.SOUTH: ['028b', '0145hjnp'],
    _Direction4.EAST: ['bcfguvyz', 'prxz'],
    _Direction4.WEST: ['0145hjnp', '028b'],
  };

  static final geohashRegExp = RegExp('^[$_baseSequence]+\$');

  /// Converts a List<int> of bits into a double for Longitude and Latitude
  static double _bitsToDouble({
    required List<int> bits,
    double lower = -90.0,
    double middle = 0.0,
    double upper = 90.0,
  }) {
    for (final bit in bits) {
      if (bit == 1) {
        lower = middle;
      } else {
        upper = middle;
      }
      middle = (upper + lower) / 2.0;
    }

    return middle;
  }

  /// Converts a double value Longitude or Latitude to a List<int> of bits
  static List<int> _doubleToBits({
    required double value,
    double lower = -90.0,
    double middle = 0.0,
    double upper = 90.0,
    int length = 15,
  }) {
    final ret = <int>[];

    for (var i = 0; i < length; i++) {
      if (value >= middle) {
        lower = middle;
        ret.add(1);
      } else {
        upper = middle;
        ret.add(0);
      }
      middle = (upper + lower) / 2;
    }

    return ret;
  }

  /// Converts a List<int> bits into a String geohash
  static String _bitsToGeoHash(List<int> bitValue) {
    final geoHashList = <String>[];

    var remainingBits = List<int>.from(bitValue);
    var subBits = <int>[];
    String subBitsAsString;
    for (var i = 0, n = bitValue.length / 5; i < n; i++) {
      subBits = remainingBits.sublist(0, 5);
      remainingBits = remainingBits.sublist(5);

      subBitsAsString = '';
      for (final value in subBits) {
        subBitsAsString += value.toString();
      }

      final value =
          int.parse(int.parse(subBitsAsString, radix: 2).toRadixString(10));
      geoHashList.add(_base32MapR[value]!);
    }

    return geoHashList.join('');
  }

  /// Converts a String geohash into List<int> bits
  static List<int> _geoHashToBits(String geohash) {
    final bitList = <int>[];

    for (final letter in geohash.split('')) {
      if (_base32Map[letter] == null) {
        continue;
      }

      final buffer = Uint8List(5).buffer;
      final bufferData = ByteData.view(buffer);

      bufferData.setUint32(0, _base32Map[letter]!);
      for (final letter in bufferData
          .getUint32(0)
          .toRadixString(2)
          .padLeft(5, '0')
          .split('')) {
        bitList.add(int.parse(letter));
      }
    }

    return bitList;
  }

  /// Encodes a given Longitude and Latitude into a String geohash
  String encode(double longitude, double latitude, {int precision = 12}) {
    var originalPrecision = precision + 0;
    if (longitude < -180.0 || longitude > 180.0) {
      throw RangeError.range(longitude, -180, 180, 'Longitude');
    }
    if (latitude < -90.0 || latitude > 90.0) {
      throw RangeError.range(latitude, -90, 90, 'Latitude');
    }

    if (precision % 2 == 1) {
      precision = precision + 1;
    }
    if (precision != 1) {
      precision ~/= 2;
    }

    final longitudeBits = _doubleToBits(
      value: longitude,
      lower: -180.0,
      upper: 180.0,
      length: precision * 5,
    );
    final latitudeBits = _doubleToBits(
      value: latitude,
      lower: -90.0,
      upper: 90.0,
      length: precision * 5,
    );

    final ret = <int>[];
    for (var i = 0; i < longitudeBits.length; i++) {
      ret.add(longitudeBits[i]);
      ret.add(latitudeBits[i]);
    }
    final geohashString = _bitsToGeoHash(ret);

    if (originalPrecision == 1) {
      return geohashString.substring(0, 1);
    }
    if (originalPrecision % 2 == 1) {
      return geohashString.substring(0, geohashString.length - 1);
    }
    return geohashString;
  }

  /// Checks if a given String geohash is valid, and throws an exception if not.
  static void _ensureValid(String geohash) {
    if (geohash.isEmpty) {
      throw ArgumentError.value(geohash, 'geohash', 'GeoHash is empty');
    }
    if (!geohash.contains(geohashRegExp)) {
      throw ArgumentError.value(
          geohash, 'geohash', 'Invalid character in GeoHash');
    }
  }

  /// Decodes a given String into a List<double> containing Longitude and
  /// Latitude in decimal degrees.
  List<double> decode(String geohash) {
    _ensureValid(geohash);
    final bits = _geoHashToBits(geohash);
    final longitudeBits = <int>[];
    final latitudeBits = <int>[];

    for (var i = 0; i < bits.length; i++) {
      if (i % 2 == 0 || i == 0) {
        longitudeBits.add(bits[i]);
      } else {
        latitudeBits.add(bits[i]);
      }
    }

    return [
      _bitsToDouble(bits: longitudeBits, lower: -180, upper: 180),
      _bitsToDouble(bits: latitudeBits),
    ];
  }

  /// Returns a String geohash of the neighbor of the given String in the given
  /// direction.
  static String _adjacent({
    required String geohash,
    required _Direction4 direction,
  }) {
    if (geohash == '') {
      throw ArgumentError.value(geohash, 'geohash');
    }

    final last = geohash[geohash.length - 1];
    final t = geohash.length % 2;

    var parent = geohash.substring(0, geohash.length - 1);
    if (_border[direction]![t].contains(last) && parent != '') {
      parent = _adjacent(geohash: parent, direction: direction);
    }

    return parent + _baseSequence[_neighbor[direction]![t].indexOf(last)];
  }

  /// Returns a Map<String, String> containing the `Direction` as the key and
  /// the value being the geohash of the neighboring geohash in that direction.
  Map<String, String> neighbors(String geohash) {
    _ensureValid(geohash);
    var adjacentN = _adjacent(geohash: geohash, direction: _Direction4.NORTH);
    var adjacentS = _adjacent(geohash: geohash, direction: _Direction4.SOUTH);
    return {
      Direction.NORTH.name: adjacentN,
      Direction.NORTHEAST.name:
          _adjacent(geohash: adjacentN, direction: _Direction4.EAST),
      Direction.EAST.name:
          _adjacent(geohash: geohash, direction: _Direction4.EAST),
      Direction.SOUTHEAST.name:
          _adjacent(geohash: adjacentS, direction: _Direction4.EAST),
      Direction.SOUTH.name: adjacentS,
      Direction.SOUTHWEST.name:
          _adjacent(geohash: adjacentS, direction: _Direction4.WEST),
      Direction.WEST.name:
          _adjacent(geohash: geohash, direction: _Direction4.WEST),
      Direction.NORTHWEST.name:
          _adjacent(geohash: adjacentN, direction: _Direction4.WEST),
      Direction.CENTRAL.name: geohash
    };
  }
}

/// A containing class for a geohash
class GeoHash {
  /// Constructor given a String geohash
  GeoHash(String geohash) {
    _geohash = geohash;
    _neighbors = GeoHasher().neighbors(geohash);
    _longitude = GeoHasher().decode(geohash)[0];
    _latitude = GeoHasher().decode(geohash)[1];
  }

  /// Constructor given Longitude and Latitude
  GeoHash.fromDecimalDegrees(
    double longitude,
    double latitude, {
    int precision = 9,
  }) {
    _geohash = GeoHasher().encode(longitude, latitude, precision: precision);
    _neighbors = GeoHasher().neighbors(_geohash);
    _longitude = longitude;
    _latitude = latitude;
  }

  late String _geohash;
  late double _longitude;
  late double _latitude;
  late Map<String, String> _neighbors;

  /// Returns the String geohash
  String get geohash => _geohash;

  /// Returns the double longitude with an optional decimal accuracy
  double longitude({int decimalAccuracy = 20}) {
    if (decimalAccuracy > 20) {
      throw RangeError('Decimal Accuracy must be between 0..20');
    }
    return double.parse(_longitude.toStringAsFixed(decimalAccuracy));
  }

  /// Returns the double latitude with an optional decimal accuracy
  double latitude({int decimalAccuracy = 20}) {
    if (decimalAccuracy > 20 || decimalAccuracy < 0) {
      throw RangeError('Decimal Accuracy must be between 0..20');
    }
    return double.parse(_latitude.toStringAsFixed(decimalAccuracy));
  }

  /// Returns a Map<String, String> containing the `Direction` as the key and
  /// the value being the geohash of the neighboring geohash in that direction.
  Map<String, String> get neighbors => _neighbors;

  /// Returns a String geohash of a neighboring geohash in a given direction
  String? neighbor(Direction direction) => _neighbors[direction.name];

  /// Returns true if given geohash is equal to or is a neighbor of this one.
  bool isNeighbor(String geohash) {
    if (geohash.length != _geohash.length) {
      return false;
    }
    return _neighbors.values.toList().contains(geohash);
  }

  /// Returns true if the given geohash contains this one within it.
  bool isInside(String geohash) {
    if (geohash.length > _geohash.length) {
      return false;
    }
    if (_geohash.substring(0, geohash.length) == geohash) {
      return true;
    }
    return false;
  }

  /// Returns true if the given geohash is contained within this geohash
  bool contains(String geohash) {
    if (geohash.length < _geohash.length) {
      return false;
    }
    if (geohash.substring(0, _geohash.length) == _geohash) {
      return true;
    }
    return false;
  }

  /// Returns a new Geohash for the parent of this one.
  GeoHash parent() => GeoHash(_geohash.substring(0, _geohash.length - 1));
}
