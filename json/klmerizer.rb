#!/usr/bin/env ruby

require 'rgeo/geo_json'
require 'rexml/document'
include REXML   # to avoid prefixing everything with REXML::...

geofactory = RGeo::Geographic.spherical_factory

# Open KML file and set a node for each <Placemark>...</Placemark> pair
# For reference algorithm see
#    http://snippets.dzone.com/posts/show/1765
#
kmlroot = (Document.new File.new "wiki.kml").root
nodes   = kmlroot.elements.to_a("//Placemark")

begin
  id = 1
  nodes.each { |node|
    name        = node.elements["name"].text
    description = node.elements["description"].text
    coords      = node.elements["Point"].elements["coordinates"].text.split(",")
    locale      = geofactory.point(coords[0], coords[1])
    props       = {"name" => name, "description" => description}
    loc_feat    = RGeo::GeoJSON::Feature.new(locale, id, props)
    loc_hash    = RGeo::GeoJSON.encode(loc_feat, :json_parser => :json, :geo_factory => geofactory)
    puts loc_hash
    id += 1
  }
end
