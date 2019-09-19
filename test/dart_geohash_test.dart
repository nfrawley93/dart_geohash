import 'package:flutter_test/flutter_test.dart';

import 'package:dart_geohash/dart_geohash.dart';

void main() {

  test('Test decoding geohash', (){
    final geohash = GeoHash();

    // region Test Decode
    expect(geohash.decode("0"), [-157.5, -67.5]);
    // Standard example with 9 character accuracy
    expect(geohash.decode("9v6kn87zg"), [-97.79499292373657, 30.23710012435913]);
    // Arbitrary accuracy. Only up to 12 characters accuracy can be achieved
    expect(geohash.decode("9v6kn87zgbbbbbbbbbb"), [-97.7949811566264, 30.237082819785357]);

    // Multiple ones that should throw an Exception
    expect(() => geohash.decode("a"), throwsAssertionError);
    expect(() => geohash.decode("-0"), throwsAssertionError);
    expect(() => geohash.decode(""), throwsArgumentError);
    expect(() => geohash.decode(null), throwsArgumentError);
    //endregion

    // region Test Encode
    expect(geohash.encode(-157.5, -67.5, precision: 0), "");
    expect(geohash.encode(-97.79499292373657, 30.23710012435913, precision: 1), "9");
    expect(geohash.encode(-97.79499292373657, 30.23710012435913, precision: 9), "9v6kn87zg");
    expect(geohash.encode(-97.79499292373657, 30.23710012435913, precision: 10), "9v6kn87zgs");
    expect(geohash.encode(-97.79499292373657, 30.23710012435913, precision: 20), "9v6kn87zgs0000000000");
    expect(geohash.encode(-97.79499292373657, 30.23710012435913), "9v6kn87zgs00");

    // Multiple ones that should throw an Exception
    expect(() => geohash.encode(null, null), throwsArgumentError);
    expect(() => geohash.encode(-181, 45), throwsArgumentError);
    expect(() => geohash.encode(45, 95), throwsArgumentError);
    //endregion

    //region Test neighbors
    expect(geohash.neighbors("9v6kn87zg"), {
      'NORTH': '9v6kn8eb5',
      'NORTHEAST': '9v6kn8ebh',
      'EAST': '9v6kn87zu',
      'SOUTHEAST': '9v6kn87zs',
      'SOUTH': '9v6kn87ze',
      'SOUTHWEST': '9v6kn87zd',
      'WEST': '9v6kn87zf',
      'NORTHWEST': '9v6kn8eb4',
      'CENTRAL': '9v6kn87zg'
    });

    // Multiple ones that should throw an Exception
    expect(() => geohash.neighbors("a"), throwsAssertionError);
    expect(() => geohash.neighbors("-0"), throwsAssertionError);
    expect(() => geohash.neighbors(""), throwsArgumentError);
    expect(() => geohash.neighbors(null), throwsArgumentError);
    //endregion
  });
}
