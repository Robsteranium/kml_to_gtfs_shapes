require 'nokogiri'
require 'rgeo'
require 'csv'

class KMLtoGTFS
  
  attr_accessor :coordinates, :geo, :points, :stops, :stop_points, :distance_traveled_by_point, :distance_traveled_by_stop

  def initialize
    super
    @geo = RGeo::Geos.factory(:native_interface => :ffi)
  end

  def import_from_kml_file(file_path, placemark_name)
    kml = Nokogiri::XML(open file_path)
    kml.remove_namespaces!
    route = kml.xpath("//Placemark[name='#{placemark_name}']")
    coordinate_strings = route.xpath('LineString/coordinates').text.split("\n")
    self.coordinates = coordinate_strings[1..-2].map{|cs| cs.lstrip.split(",")[0..1].map(&:to_f) }
  end

  def import_from_gtfs_files(file_path, trip_id)
    stop_times = CSV.read(file_path + "/stop_times.txt", :headers=> :first_row)
    relevant_st= stop_times.select{|stop_time| stop_time["trip_id"] == trip_id }
    uniq_st    = relevant_st.uniq {|stop_time| stop_time["stop_id"] }
    ordered_st = uniq_st.sort_by{|stop_time| stop_time["stop_sequence"].to_i }
    stop_ids   = ordered_st.map{|stop_time| stop_time["stop_id"]}
    #stop_ids   = stop_times.select{|stop_time| trip_ids.include?( stop_time["trip_id"] ) }.map{|stop_time| stop_time["stop_id"]}.uniq
    stops      = CSV.read(file_path + "/stops.txt", :headers=> :first_row)
    
    self.stops = stop_ids.map{|stop_id| stops.detect{|stop| stop_id == stop["stop_id"] }}
  end

  def distance_traveled_by_point
    line_string = self.geo.line_string(self.points)
    @distance_traveled_by_point ||= [0] + 1.upto(self.coordinates.length-1).map do |end_point|
      self.geo.line_string( line_string.fg_geom[0..end_point].map{ |p| self.geo.wrap_fg_geom(p) } ).length
    end
  end

  def points
    @points ||=  self.coordinates.map{|crd| self.geo.point(*crd.map(&:to_f))}
  end

  def stop_points
    @stop_points ||= self.stops.map{|stop| self.geo.point(stop["stop_lat"].to_f, stop["stop_lon"].to_f).fg_geom }
  end

  def distance_traveled_by_stop
    last_point_covered = 0
    distance_covered = 0
    @stop_distance_traveled_by_stop ||= self.stop_points.map do |stop_point|
      remaining_route = self.geo.line_string(self.points[last_point_covered..-1]).fg_geom
      projected_point_on_remaining_route = remaining_route.project(stop_point)
      distance_covered = self.distance_traveled_by_point[last_point_covered] + projected_point_on_remaining_route
      last_point_covered = self.index_of_last_point_covered_by_distance(distance_covered)
      distance_covered
    end
  end

  def txt_for_shapes(shape_id)
    distances = distance_traveled_by_point
    rows = self.coordinates.each_with_index.map do |crd, index| 
      [shape_id, crd[0], crd[1], index+1, distances[index]].join(",")
    end
    rows.join("\n")
  end

  def csv_for_shapes(shape_id)
    csv = "shape_id,shape_pt_lon,shape_pt_lat,shape_pt_sequence,shape_dist_traveled\n"
    csv += txt_for_shapes(shape_id)
  end

  def index_of_last_point_covered_by_distance(distance_traveled)
    last_point_covered = 0
    0.upto(self.coordinates.length-1).each do |index|
      if self.distance_traveled_by_point[index] <= distance_traveled
        last_point_covered = index
      end
    end
    last_point_covered
  end

end



