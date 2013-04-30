# KML to GTFS Shapes.txt Converter


## Description
This library converts `KML` routes into the [`shapes.txt` format](https://developers.google.com/transit/gtfs/reference#shapes_fields) compatible with the `General Transit Feed Specification`.

Associating kml coordinates to stops by euclidian distance is trivial. The reason this is an interesting problem is that routes can overlap (e.g. as the vehicle comes back down the street in the opposite direction) making the distance traveled by stop ambiguous.

![Looping Route/ Shape Example from Fixtures](/Rplot001.png)

This algorithm resolves the stop to a point on the route by ignoring that part of the route that has already been covered.


## Requirements
Naturally you'll need a GTFS directory and a KML file with the route polygons. You can find examples in the `fixtures` and `metroshuttle_example` directories. 

To run the converter you'll need to have Ruby and the [Geos](http://geos.osgeo.org) lib installed. You can get the necessary ruby gems by running `bundle` in the root of the project directory.

To generate visualisations (as per the above diagram showing the looping route used for testing) you'll need `R` (and several packages installed: `rgeos`, `rgdal`, and `ggplot2`) to run the `visualise.r` script. This isn't necessary for the conversion itself but it has been include to aid with debugging.


## Usage

The converter needs both the KML and GTFS:

    converter = KMLtoGTFS.new
    converter.import_kml_file('path/to/my_route.kml', route_name)
    converter.import_gtfs('path/to/gtfs_dir', route_id)

Where `route_name` is the Name of the Placemark in the KML file and `route_id` is the corresponding value from the GTFS.

You can create `shapes.txt` i.e `shaped_id`, `shape_pt_lat`, `shape_pt_lon`, `shape_pt_sequence` and the (optional) `shape_dist_traveled`:

    converter.csv_for_shapes

Or use `txt_for_shapes` if you don't want the csv headers.

The `shape_dist_traveled` field used in `stop_times.txt` is also provided.

    converter.distance_traveled_by_stop


## Example

An example has been included for the Manchester's Metroshuttle along with the GTFS and KML files needed to recreate this. You can run the script as follows

    $ ruby update_gtfs_with_shapes_etc.rb

This will use the contents of the `metroshuttle_example/gtfs_original` directory and the `metroshuttle_example/kml/MetroshuttleRoutes.fixed.KML` (which fixes the reversed lat/lons from the original TFGM release) to produce `shapes.txt` and update `trips.txt` and `stop_times.txt` in the `metroshuttle_example/gtfs_update` directory.


## Next Steps - Implementation across Multiple Trips

The converter currently makes the assumption that a route only involves one set of stops. In reality GTFS provides for multiple sets of stops for different trips (as defined in stop_times). The GTFS is currently simplified in a naive manner - the route is mapped to all unique stops across all trips on that route. These are arranged by sequence which means two different trips on the same route will overlap and confuse the converter.

This problems mean that the Metroshuttle 2 route in the example cannot be parsed. The arrangement of stops in the different trips on this route move in opposite directions and the converter thinks it has covered the whole distance by the second stop.

To resolve this problem the converter needs to be modified to generate shape_dist_traveled for each trip.

The converter must also be modified to account for the fact that the last stop is often the same as the first stop (currently this means the distance traveled at the last stop is mistakenly set to 0).

Parallel work is also ongoing into a conversion between arbitrary vehicle GPS locations and GTFS-RT. This hasn't been released yet.




Copyright (c) 2012 Robin Gower. Released under Affero General Public License.
