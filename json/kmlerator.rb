#!/usr/bin/env ruby

require 'json'
require 'rexml/document'
include REXML   # to avoid prefixing everything with REXML::...

def create_geo_json input_node
  type = input_node.elements['LineString'] != nil ? 'LineString' : 'Point'
  coordstr = input_node.elements[type].elements['coordinates'].text.strip
  if type == 'LineString'
    coordlst = []
    coordstr.split.each{ |triple| coordlst << triple.split(',') }
    coords = coordlst
    for i in 1..coords.length
      for j in 1..coords[i-1].length
        coords[i-1][j-1] = coords[i-1][j-1].to_f
      end
    end
  else
    coords = coordstr.split(',')
    for i in 1..coords.length
      coords[i-1] = coords[i-1].to_f
    end
  end
  {
    :type => 'Feature',
    :geometry => {
      :type => type,
      :coordinates => coords
    },
    :properties => {
      :name => input_node.elements['name'].text,
      #:location_desc => input_node.elements['description'].text,
      :info => input_node.elements.reject { |key, val| key == 'name' || key = 'description' }
    }
  }.to_json
end

# Open KML file and set a node for each <Placemark>...</Placemark> pair
# For reference algorithm see
#    http://snippets.dzone.com/posts/show/1765
#
kmlroot = (Document.new File.new "../tmp/wiki.kml").root
nodes   = kmlroot.elements.to_a("//Placemark")

begin
  id = 1
  ofile = File.open("../tmp/k2j_output.txt", "w")
  nodes.each do |node|
    ofile.puts create_geo_json(node)
    id += 1
  end
ensure
  ofile.close
end

