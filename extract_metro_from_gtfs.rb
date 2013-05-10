require 'csv'

route_match = Regexp.new(/GMN:   [123]:C:/)

# gtfs reducer
routes = CSV.read("tfgm_gtfs/routes.txt", :headers=> :first_row).select do |route|
  route["route_id"] =~ route_match
end
File.open("tfgm_gtfs/met/routes.txt", "w") {|f| f << CSV::Table.new(routes).to_csv }

trips = CSV.read("tfgm_gtfs/trips.txt", :headers=> :first_row).select do |trip|
  trip["route_id"] =~ route_match
end
File.open("tfgm_gtfs/met/trips.txt", "w") {|f| f << CSV::Table.new(trips).to_csv }

trip_ids = CSV::Table.new(trips)["trip_id"].uniq

stop_times = CSV.read("tfgm_gtfs/stop_times.txt", :headers=> :first_row).select do |stop_time|
  trip_ids.include?(stop_time["trip_id"])
end
File.open("tfgm_gtfs/met/stop_times.txt", "w") {|f| f << CSV::Table.new(stop_times).to_csv }

stop_ids = CSV::Table.new(stop_times)["stop_id"].uniq

stops = CSV.read("tfgm_gtfs/stops.txt", :headers=> :first_row).select do |stop|
  stop_ids.include?(stop["stop_id"])
end
File.open("tfgm_gtfs/met/stops.txt", "w") {|f| f << CSV::Table.new(stops).to_csv }

