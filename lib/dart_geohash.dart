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

/// A class that can convert a geohash String to [Longitude, Latitude] and back.
class GeoHasher {
  static final String _baseSequence = '0123456789bcdefghjkmnpqrstuvwxyz';

  /// Creates a Map of available characters for a geohash
  final _base32Map = <String, int>{
    for (var value in _baseSequence.split(''))
      value: _baseSequence.indexOf(value),
  };

  /// Creates a reversed Map of available characters for a geohash
  final _base32MapR = <int, String>{
    for (var value in _baseSequence.split(''))
      _baseSequence.indexOf(value): value,
  };

  /// Converts a List<int> of bits into a double for Longitude and Latitude
  double _bitsToDouble({
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
  List<int> _doubleToBits({
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
  String _bitsToGeoHash(List<int> bitValue) {
    final geoHashList = <String>[];

    var remainingBits = List<int>.from(bitValue);
    var subBits = <int>[];
    String subBitsAsString;
    for (var i = 0; i < bitValue.length / 5; i++) {
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
  List<int> _geoHashToBits(String geohash) {
    final bitList = <int>[];

    geohash.split('').forEach((letter) {
      if (_base32Map[letter] != null) {
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
    });

    return bitList;
  }

  /// Encodes a given Longitude and Latitude into a String geohash
  String encode(
    double longitude,
    double latitude, {
    int precision = 12,
  }) {
    if (longitude < -180.0 || longitude > 180.0) {
      throw RangeError.range(longitude, -180, 180, 'Longitude');
    }
    if (latitude < -90.0 || latitude > 90.0) {
      throw RangeError.range(latitude, -180, 180, 'Latitude');
    }

    final originalPrecision = precision + 0;

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

  /// Decodes a given String into a List<double> containing Longitude and
  /// Latitude in decimal degrees.
  List<double> decode(String geohash) {
    if (geohash == '') {
      throw ArgumentError.value(geohash, 'geohash');
    }
    if (!geohash.contains(RegExp(r'^[0123456789bcdefghjkmnpqrstuvwxyz]+$'))) {
      throw ArgumentError('Invalid character in GeoHash');
    }

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
  String _adjacent({
    required String geohash,
    required String direction,
  }) {
    assert(direction.contains(RegExp(r'[nsewNSEW]')) == true,
        'Invalid Direction $direction not in NSEW');
    if (geohash == '') {
      throw ArgumentError.value(geohash, 'geohash');
    }

    final neighbor = <String, List>{
      'n': [
        'p0r21436x8zb9dcf5h7kjnmqesgutwvy',
        'bc01fg45238967deuvhjyznpkmstqrwx'
      ],
      's': [
        '14365h7k9dcfesgujnmqp0r2twvyx8zb',
        '238967debc01fg45kmstqrwxuvhjyznp'
      ],
      'e': [
        'bc01fg45238967deuvhjyznpkmstqrwx',
        'p0r21436x8zb9dcf5h7kjnmqesgutwvy'
      ],
      'w': [
        '238967debc01fg45kmstqrwxuvhjyznp',
        '14365h7k9dcfesgujnmqp0r2twvyx8zb'
      ],
    };
    final border = <String, List>{
      'n': ['prxz', 'bcfguvyz'],
      's': ['028b', '0145hjnp'],
      'e': ['bcfguvyz', 'prxz'],
      'w': ['0145hjnp', '028b'],
    };

    final last = geohash[geohash.length - 1];
    final t = geohash.length % 2;

    var parent = geohash.substring(0, geohash.length - 1);
    if (border[direction]![t].toString().contains(last)) {
      parent = _adjacent(geohash: parent, direction: direction);
    }

    return parent +
        _baseSequence[neighbor[direction]![t].toString().indexOf(last)];
  }

  /// Returns a Map<String, String> containing the `Direction` as the key and
  /// the value being the geohash of the neighboring geohash in that direction.
  Map<String, String> neighbors(String geohash) {
    if (geohash == '') {
      throw ArgumentError.value(geohash, 'geohash');
    }
    if (!geohash.contains(RegExp(r'^[0123456789bcdefghjkmnpqrstuvwxyz]+$'))) {
      throw ArgumentError('Invalid character in GeoHash');
    }

    return {
      Direction.NORTH.toString().split('.')[1]:
          _adjacent(geohash: geohash, direction: 'n'),
      Direction.NORTHEAST.toString().split('.')[1]: _adjacent(
          geohash: _adjacent(geohash: geohash, direction: 'n'), direction: 'e'),
      Direction.EAST.toString().split('.')[1]:
          _adjacent(geohash: geohash, direction: 'e'),
      Direction.SOUTHEAST.toString().split('.')[1]: _adjacent(
          geohash: _adjacent(geohash: geohash, direction: 's'), direction: 'e'),
      Direction.SOUTH.toString().split('.')[1]:
          _adjacent(geohash: geohash, direction: 's'),
      Direction.SOUTHWEST.toString().split('.')[1]: _adjacent(
          geohash: _adjacent(geohash: geohash, direction: 's'), direction: 'w'),
      Direction.WEST.toString().split('.')[1]:
          _adjacent(geohash: geohash, direction: 'w'),
      Direction.NORTHWEST.toString().split('.')[1]: _adjacent(
          geohash: _adjacent(geohash: geohash, direction: 'n'), direction: 'w'),
      Direction.CENTRAL.toString().split('.')[1]: geohash
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
  double longitude({int? decimalAccuracy}) {
    if (decimalAccuracy == null) {
      return _longitude;
    }

    return double.parse(_longitude.toStringAsFixed(decimalAccuracy));
  }

  /// Returns the double latitude with an optional decimal accuracy
  double latitude({int? decimalAccuracy}) {
    if (decimalAccuracy == null) {
      return _latitude;
    }

    return double.parse(_latitude.toStringAsFixed(decimalAccuracy));
  }

  /// Returns a Map<String, String> containing the `Direction` as the key and
  /// the value being the geohash of the neighboring geohash in that direction.
  Map<String, String> get neighbors => _neighbors;

  /// Returns a String geohash of a neighboring geohash in a given direction
  String? neighbor(Direction direction) {
    return _neighbors[direction.toString().split('.')[1]];
  }

  /// Returns true if given geohash is equal to or is a neighbor of this one.
  bool isNeighbor(String geohash) {
    if (geohash.length != _geohash.length) {
      return false;
    }

    return _neighbors.values.contains((final String value) => value == geohash);
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
  GeoHash parent() {
    return GeoHash(_geohash.substring(0, _geohash.length - 1));
  }
}
