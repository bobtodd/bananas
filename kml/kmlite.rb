# kmlite.rb
#
# Classes for handling a KML file a little
# more easily.

require 'json'

class Point
  attr_accessor :x, :y, :z

  # Pass the Point a string and have it find the coordinates
  def initialize(str)
    @x, @y, @z = coords(str)
  end

  def to_s
    '[' + @x.to_s + ', ' + @y.to_s + ', ' + @z.to_s + ']'
  end

  def coords(str)
    # get everything between <coordinates>...</coordinates> pairs
    # and split over commas
    data = str.match(/<coordinates>(.+)<\/coordinates>/)
    triple = []
    if data[1] != nil
      coords = data[1].split(',')
      triple << coords[0].to_f
      triple << coords[1].to_f
      triple << coords[2] != nil ? coords[2].to_f : 0.0
    else
      puts "No coordinates for Point"
      3.times do
        triple << nil
      end
    end
    return triple
  end
end

class LineString
  attr_accessor :points

  def initialize(str)
    @points = scour(str)
  end

  def to_s
    str = '['
    @points.each { |point| str += point.to_s + ', ' }
    str = str.chomp(', ')
    str += ']'
    return str
  end

  def scour(str)
    # get everything between <coordinates>...</coordinates> pairs
    # different points are separated by spaces: use string#split
    # coordinates of each point are separated by commas: split(',')
    points = []
    pt_str = str.match(/<coordinates>(.+?)<\/coordinates>/m)[1].split
    pt_str.each{ |item| points << Point.new("<coordinates>" + item + "<\/coordinates>") }
    return points
  end
end

class LinearRing < LineString
  # a LineString that closes on itself
  # ... since there's no point saving a point twice,
  # this is formally identical to a LineString
end

class Polygon
  # a shape contained between inner and outer LinearRings
  # the inner LinearRing may be nil
  attr_accessor :outer, :inner

  def initialize(str)
    @outer, @inner = scour(str)
  end

  def to_s
    str  = '[' + @outer.to_s
    str += (@inner != nil) ? ', ' + @inner.to_s : ''
    str += ']'
    return str
  end

  def scour(str)
    if data = str.match(/<outerBoundaryIs>(.+?)<\/outerBoundaryIs>/m)
      outer = LinearRing.new(data[1])
    else
      outer = nil
    end
    if data = str.match(/<innerBoundaryIs>(.+?)<\/innerBoundaryIs>/m)
      inner = LinearRing.new(data[1])
    else
      inner = nil
    end
    return outer, inner
  end
end

class Placemark
  attr_accessor :name, :description, :geo_type, :geo_object

  def initialize(str)
    @name, @description, @geo_type, @geo_object = scour(str)
  end

  def to_json
    {
      :type => 'Feature',
      :geometry => {
        :type => @geo_type,
        :coordinates => @geo_object.to_s
      },
      :properties => {
        :name => @name,
        :description => (@description == nil) ? "" : @description
      }
    }.to_json
  end

  def scour(str)
    name        = (nm = str.match(/<name>(.+?)<\/name>/)) ? nm[1] : nil
    description = (descr = str.match(/<description>(.+?)<\/description>/)) ? descr[1] : nil

    if data = str.match(/<Polygon>(.+?)<\/Polygon>/m)
      # for <Polygon>...</Polygon> pairs, create a LinearRing
      geo_type   = "Polygon"
      geo_object = Polygon.new(data[1])
    elsif data = str.match(/<LinearRing>(.+?)<\/LinearRing>/m)
      # for <LinearRing>...</LinearRing> pairs, create a LinearRing
      geo_type   = "LinearRing"
      geo_object = LinearRing.new(data[1])
    elsif data = str.match(/<LineString>(.+?)<\/LineString>/m)
      # for <LineString>...</LineString> pairs, create a LineString
      geo_type   = "LineString"
      geo_object = LineString.new(data[1])
    elsif data = str.match(/<Point>(.+?)<\/Point>/m)
      # for <Point>...</Point> pairs, create a Point
      # by passing Point.new the string contained in between
      geo_type   = "Point"
      geo_object = Point.new(data[1])
    else
      geo_type   = nil
      geo_object = nil
    end

    return name, description, geo_type, geo_object
  end
end

class KMLdoc
  # open a file, search for <Document>...</Document>
  # Find all the Placemarks in between
  # For each, create a Placemark and
  # add the resulting object to an Array

  attr_accessor :placemarks

  def initialize(filename)
    str         = File.open(filename, "r") { |ifile| ifile.read }
    result      = str.match(/<Document>(.*)<\/Document>/m)[1] # use 'm' for multiple lines
    @placemarks = scour(result)
  end

  def to_json(filename=nil)
    if filename
      ofile = File.open(filename, "w")
      @placemarks.each{ |place| ofile.puts place.to_json }
      ofile.close
    else
      @placemarks.each{ |place| puts place.to_json }
    end
  end

  def scour(str)
    # for <Placemark>...</Placemark> pairs, create a Placemark
    placemarks = []
    str.scan(/<Placemark>(.+?)<\/Placemark>/m).each{ |place| placemarks << Placemark.new(place[0]) }
    return placemarks
  end
end
