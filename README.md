# dart_geohash

[GeoHash](https://en.wikipedia.org/wiki/Geohash) is a simple way of storing a latitude/longitude
location as a simple string.

Includes a Class for encode/decode and finding neighbors as well as a Class that
can be given a location and will contain all needed information for that GeoHash.

# Example

```
// Create a simple geohash from a given string
GeoHash myHash = GeoHash("9yf0zhhtj");
// Immediately be able to get all other information related to it
myHash.geohash;
myHash.longitude;
myHash.latitude(decimalAccuracy: 4);
myHash.neighbors; // Returns a Map with itself and 8 surrounding neighbors
myHash.neighbor(Direction.NORTH);
// You can also create it from a specific lon/lat
GeoHash myOtherHash = GeoHash.fromDecimalDegrees(-98.1235, 38.1234);
```

```
// Separately you can use only the Geohasher functions
GeoHasher geoHasher = GeoHasher();
geoHasher.encode(-98, 38); // Returns a string geohash
geoHasher.encode(-98, 38, precision: 6) // Returns string geohash with length
geoHasher.decode("9yf0zhhtj"); // Returns decimal longitude/latitude
geoHasher.neighbors("9yf0zhhtj"); // Returns itself and 8 neighbors as a Map
```
## 
##
Based on the Python Package [Mapzen GeoHash](https://github.com/transitland/mapzen-geohash)
