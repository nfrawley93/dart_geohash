library dart_geohash;

import 'dart:typed_data';

enum Direction {
  NORTH,
  NORTHEAST,
  EAST,
  SOUTHEAST,
  SOUTH,
  SOUTHWEST,
  WEST,
  NORTHWEST,
  CENTRAL
}

class GeoHash {
  static String _baseSequence = '0123456789bcdefghjkmnpqrstuvwxyz';

  Map<String, int> _base32Map =
      Map.fromIterable(_baseSequence.split(""), key: (key) {
    return key;
  }, value: (value) {
    return _baseSequence.indexOf(value);
  });

  Map<int, String> _base32MapR =
      Map.fromIterable(_baseSequence.split(""), key: (key) {
    return _baseSequence.indexOf(key);
  }, value: (value) {
    return value;
  });

  double _bitsToDouble(
      {List<int> bits,
      double lower = -90.0,
      double middle = 0.0,
      double upper = 90.0}) {
    bits.forEach((bit) {
      if (bit == 1) {
        lower = middle;
      } else {
        upper = middle;
      }
      middle = (upper + lower) / 2.0;
    });
    return middle;
  }

  List<int> _doubleToBits(
      {double value,
      double lower = -90.0,
      double middle = 0.0,
      double upper = 90.0,
      int length = 15}) {
    List<int> ret = List<int>();

    for (int i = 0; i < length; i++) {
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

  String _bitsToGeoHash(List<int> bitValue) {
    List<int> remainingBits = List<int>.from(bitValue);
    List<int> subBits = List<int>();
    List<String> geoHashList = List<String>();

    String subBitsAsString;
    int value;
    for (int i = 0; i < bitValue.length / 5; i++) {
      subBits = remainingBits.sublist(0, 5);
      remainingBits = remainingBits.sublist(5);
      subBitsAsString = "";
      subBits.forEach((value) {
        subBitsAsString = subBitsAsString + value.toString();
      });
      value = int.parse(int.parse(subBitsAsString, radix: 2).toRadixString(10));

      geoHashList.add(_base32MapR[value]);
    }

    return geoHashList.join("");
  }

  List<int> _geoHashToBits(String geohash) {
    List<int> letterNumValue = List<int>();
    List<int> bitList = List<int>();
    geohash.split("").forEach((letter) {
      if (_base32Map[letter] != null) {
        letterNumValue.add(_base32Map[letter]);

        ByteBuffer buffer = Uint8List(5).buffer;
        ByteData bufferData = ByteData.view(buffer);
        bufferData.setUint32(0, _base32Map[letter]);
        bufferData
            .getUint32(0)
            .toRadixString(2)
            .padLeft(5, "0")
            .split("")
            .forEach((letter) {
          bitList.add(int.parse(letter));
        });
      }
    });

    return bitList;
  }

  String encode(double longitude, double latitude, {int precision = 12}) {
    bool precisionOdd = precision % 2 == 1;
    int originalPrecision = precision + 0;
    if (longitude == null || latitude == null) throw ArgumentError.notNull();
    if (longitude < -180.0 || longitude > 180.0)
      throw RangeError.range(longitude, -180, 180, "Longitude");
    if (latitude < -90.0 || latitude > 90.0)
      throw RangeError.range(latitude, -180, 180, "Latitude");

    if (precision % 2 == 1) {
      precision = precision + 1;
    }
    if (precision != 1) precision ~/= 2;

    List<int> longitudeBits = _doubleToBits(
        value: longitude, lower: -180.0, upper: 180.0, length: precision * 5);
    List<int> latitudeBits = _doubleToBits(
        value: latitude, lower: -90.0, upper: 90.0, length: precision * 5);

    List<int> ret = List<int>();
    for (int i = 0; i < longitudeBits.length; i++) {
      ret.add(longitudeBits[i]);
      ret.add(latitudeBits[i]);
    }

    String geohashString = _bitsToGeoHash(ret);

    return originalPrecision == 1
        ? geohashString.substring(0, 1)
        : (precisionOdd
            ? geohashString.substring(0, geohashString.length - 1)
            : geohashString);
  }

  List<double> decode(String geohash) {
    if (geohash == null)
      throw ArgumentError.notNull(geohash);
    else if (geohash == "")
      throw ArgumentError.value(geohash, "geohash");
    else if (!geohash
        .contains(new RegExp(r'^[0123456789bcdefghjkmnpqrstuvwxyz]+$')))
      throw AssertionError("Invalid character in GeoHash");

    List<int> bits = _geoHashToBits(geohash);
    List<int> longitudeBits = List<int>();
    List<int> latitudeBits = List<int>();

    for (int i = 0; i < bits.length; i++) {
      if (i % 2 == 0 || i == 0) {
        longitudeBits.add(bits[i]);
      } else {
        latitudeBits.add(bits[i]);
      }
    }

    return [
      _bitsToDouble(bits: longitudeBits, lower: -180, upper: 180),
      _bitsToDouble(bits: latitudeBits)
    ];
  }

  String _adjacent({String geohash, String direction}) {
    assert(direction.contains(new RegExp(r'[nsewNSEW]')),
        "Invalid Direction $direction not in NSEW");
    assert(geohash != null, "Invalid GeoHash");

    Map<String, List> neighbor = {
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
      ]
    };

    Map<String, List> border = {
      'n': ['prxz', 'bcfguvyz'],
      's': ['028b', '0145hjnp'],
      'e': ['bcfguvyz', 'prxz'],
      'w': ['0145hjnp', '028b']
    };

    String last = geohash[geohash.length - 1];
    String parent = geohash.substring(0, geohash.length - 1);
    int t = geohash.length % 2;

    if (border[direction][t].toString().contains(last) && parent != null) {
      parent = _adjacent(geohash: parent, direction: direction);
    }

    return parent +
        _baseSequence[neighbor[direction][t].toString().indexOf(last)];
  }

  Map<String, String> neighbors(String geohash) {
    if (geohash == null)
      throw ArgumentError.notNull(geohash);
    else if (geohash == "")
      throw ArgumentError.value(geohash, "geohash");
    else if (!geohash
        .contains(new RegExp(r'^[0123456789bcdefghjkmnpqrstuvwxyz]+$')))
      throw AssertionError("Invalid character in GeoHash");

    return {
      Direction.NORTH.toString().split(".")[1]:
          _adjacent(geohash: geohash, direction: "n"),
      Direction.NORTHEAST.toString().split(".")[1]: _adjacent(
          geohash: _adjacent(geohash: geohash, direction: 'n'), direction: 'e'),
      Direction.EAST.toString().split(".")[1]:
          _adjacent(geohash: geohash, direction: 'e'),
      Direction.SOUTHEAST.toString().split(".")[1]: _adjacent(
          geohash: _adjacent(geohash: geohash, direction: 's'), direction: 'e'),
      Direction.SOUTH.toString().split(".")[1]:
          _adjacent(geohash: geohash, direction: 's'),
      Direction.SOUTHWEST.toString().split(".")[1]: _adjacent(
          geohash: _adjacent(geohash: geohash, direction: 's'), direction: 'w'),
      Direction.WEST.toString().split(".")[1]:
          _adjacent(geohash: geohash, direction: 'w'),
      Direction.NORTHWEST.toString().split(".")[1]: _adjacent(
          geohash: _adjacent(geohash: geohash, direction: 'n'), direction: 'w'),
      Direction.CENTRAL.toString().split(".")[1]: geohash
    };
  }
}
