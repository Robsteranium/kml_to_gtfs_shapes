# encoding: utf-8
require './lib/kml_to_gtfs_shapes'


#shape_to_route = {"Metroshuttle 1" => "GMN:   1:C:", "Metroshuttle 2" => "GMN:   2:C:", "Metroshuttle 3" => "GMN:   3:C:", "Metroshuttle 1A" => "GMN:   1:C:"}
shape_to_route = {"Metroshuttle 1" => "GMN:   1:C:", "Metroshuttle 3" => "GMN:   3:C:" }


trips_txt = CSV.read("metroshuttle_example/gtfs_original/trips.txt", :headers => :first_row)
stop_times_txt = CSV.read("metroshuttle_example/gtfs_original/stop_times.txt", :headers => :first_row)


shape_rows = []
shape_id_for_trip_id = {}
shape_id   = 1

dist_for_stop_id = {}

shape_to_route.each do |route_name, route_id|
  converter = KMLtoGTFS.new
  converter.import_from_kml_file("metroshuttle_example/kml/MetroshuttleRoutes.fixed.KML", route_name)
  
  shape = CSV.parse(converter.csv_for_shapes(shape_id), :headers=>:first_row)
  shape_rows.push *shape.entries

  trips = trips_txt.select do |trip|
    trip["route_id"] == route_id
  end
  
  trip_ids = trips.map do |trip|
    trip["trip_id"]
  end

  trip_ids.each do |trip_id|
    shape_id_for_trip_id[trip_id] = shape_id
    converter.import_from_gtfs_files("metroshuttle_example/gtfs_original", trip_id)
    
    stop_ids   = stop_times_txt.select{|stop_time| trip_ids.include?( stop_time["trip_id"] ) }.map{|stop_time| stop_time["stop_id"]}#.uniq
    dist_by_stop = converter.distance_traveled_by_stop
    stop_ids.each_with_index do |stop_id,index|
      dist_for_stop_id[stop_id] = dist_by_stop[index]
    end

    shape_id+=1
  end
  
end

#shape_rows.flatten!(1)

trips_txt["shape_id"] = shape_id_for_trip_id.values_at( *trips_txt["trip_id"] )
stop_times_txt["shape_dist_traveled"] = dist_for_stop_id.values_at( *stop_times_txt["stop_id"] )


File.open("metroshuttle_example/gtfs_update/shapes.txt", "w") {|f| f << CSV::Table.new(shape_rows).to_csv }
File.open("metroshuttle_example/gtfs_update/trips.txt", "w") {|f| f << CSV::Table.new(trips_txt).to_csv }
File.open("metroshuttle_example/gtfs_update/stop_times.txt", "w") {|f| f << CSV::Table.new(stop_times_txt).to_csv }
