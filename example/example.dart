import 'package:dart_geohash/dart_geohash.dart';

void main() {
  var geoHasher = GeoHasher();

  // Encoding Example
  // Given a longitude and latitude
  print(geoHasher.encode(-98, 38));
  // Including a specific precision
  print(geoHasher.encode(-98, 38, precision: 6));
  // Default precision is 12 characters
  print(geoHasher.encode(-98.123456789, 38.123456789, precision: 10));
  print(geoHasher.encode(-98.123456789, 38.123456789));
  // Specific precision that is overly precise will produce arbitrary false accuracy
  print(geoHasher.encode(-98, 38, precision: 20));

  // Decode takes a geohash and returns a List[2] with longitude and latitude
  // The results are not automatically adjusted to the accuracy (length) of the
  // given geocode. You will need to decide what degree of accuracy is required
  print(geoHasher.decode('9yf0zhhtj'));
  // Both of these will give the same geohash as shown above accuracy at
  // "human/tree" level. So be careful when determining accuracy
  print(geoHasher.encode(-98.12346696853638, 38.123438358306885, precision: 9));
  print(geoHasher.encode(-98.12346, 38.123438, precision: 9));

  // Neighbors will return the central geohash (the given one) along with the
  // 8 surrounding squares as a map with given directions
  // This will return the other geohash at all the same level of accuracy as the
  // one given
  print(geoHasher.neighbors('9yf0zhhtj'));

  /* longitude and latitude are roughly
  decimal   places 	    rough scale
  0         1.0         country
  1 	      0.1         large city
  2 	      0.01        town or village
  3 	      0.001       neighborhood
  4 	      0.0001      individual street
  5 	      0.00001     individual trees
  6 	      0.000001 	  individual humans
  */

  /* Geohash Scale
  Geohash length 	Cell width 	Cell height
  1 	              multiple countries
  2 	              state - multiple states
  3 	              multiple cities
  4 	              average city
  5 	              small town
  6 	              neighborhood
  7 	              individual street
  8 	              small store
  9 	              individual trees
  10 	              individual humans
  .....
  */


  var myHash = GeoHash('9yf0zhhtj');
  print(myHash.geohash);
  print(myHash.longitude());
  print(myHash.longitude(decimalAccuracy: 4));
  print(myHash.latitude());
  print(myHash.latitude(decimalAccuracy: 4));
  print(myHash.neighbors);
  print(myHash.neighbor(Direction.NORTH));

  var myOtherHash = GeoHash.fromDecimalDegrees(-98.1235, 38.1234);
  print(myOtherHash.geohash);
  print(myOtherHash.longitude());
  print(myOtherHash.longitude(decimalAccuracy: 4));
  print(myOtherHash.latitude());
  print(myOtherHash.latitude(decimalAccuracy: 4));
  print(myOtherHash.neighbors);
  print(myOtherHash.neighbor(Direction.NORTH));

}
