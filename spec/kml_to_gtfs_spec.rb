require 'spec_helper'


describe KMLtoGTFS do
  describe "basic shape" do
    let!(:conv) do
      conv = KMLtoGTFS.new
      conv.import_from_kml_file('fixtures/basic.kml', 'Boring Route')
      conv.import_from_gtfs_files('fixtures/gtfs_basic', '1')
      conv
    end

    it "should have coordinates" do
      conv.coordinates.length.should eq 5
    end

    it "should have stops" do
      conv.stops.length.should eq 3
    end

    it "should calculate distance travelled" do
      conv.distance_traveled_by_point.should eq [0, 10, 20, 30, 40]
    end

    it "should calculate distance travelled for stop times" do
      conv.distance_traveled_by_stop.should eq [0, 15, 35]
    end

    it "should create shapes.txt" do
      conv.csv_for_shapes(1).should eq open('fixtures/gtfs_basic/shapes.txt').read.chomp
    end

  end

  describe "looping route" do
    let!(:conv) do
      conv = KMLtoGTFS.new
      conv.import_from_kml_file('fixtures/loop.kml', 'Looping Route')
      conv.import_from_gtfs_files('fixtures/gtfs_loop', '1')
      conv
    end

    it "should determine the last coordinate passed by distance" do
      conv.index_of_last_point_covered_by_distance(45.0).should eq 4
      conv.index_of_last_point_covered_by_distance(105.0).should eq 9
      conv.index_of_last_point_covered_by_distance(100.0).should eq 9
    end

    xit "should determine the last coordinate passed by stop" do
      conv.index_of_last_point_covered_at_stop(3).should eq 4
      conv.index_of_last_point_covered_at_stop(5).should eq 8
    end

    it "should calculate distance travelled for stop times" do
      conv.distance_traveled_by_stop.should eq [5, 25, 45, 75, 95, 115]
    end
  end

  describe "multiple trips on route" do
    let!(:conv) do
      conv = KMLtoGTFS.new
      conv.import_from_kml_file('fixtures/multiple.kml', 'MultiTrip Route')
      conv.import_from_gtfs_files('fixtures/gtfs_multiple', '1')
      conv
    end

    it "should only pick-up stops from trip 1" do
      conv.stops.length.should eq 4
    end

    it "should pick-up the right stops from trip 1" do
      conv.distance_traveled_by_stop.should eq [0, 20, 30, 50]
    end

  end

  pending "validate inputs - stop sequence"
  pending "validate results - dist increases with sequence"
  pending "cope with routes that start and stop in the same point"
  pending "batch implementation for whole gtfs feed"

end
