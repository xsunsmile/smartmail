require "open-uri"
require "nkf"
require "cgi"
require "rexml/document"

class GoogleMapGeocode
    RequestUrl = "http://maps.google.com/maps/geo"
    Key = "ABQIAAAAxJu5v6zgRPFjW7PwRK47QBQPJSQHxneVf4G9qhFwVHgfK2SfiRSk7coUvi5zVapMQhpNQCZSfkZoHA"

    attr_reader :lat
    attr_reader :lng
    attr_reader :result
    attr_reader :address

    def initialize(address)
        @address = NKF.nkf("-w -m0",address)
        @url = "#{RequestUrl}?&q=#{CGI.escape(NKF.nkf("-w -m0",address))}"+
        "&output=xml&key=#{Key}"
        doc = REXML::Document.new(open(@url))
        if doc.elements["/kml/Response/Status/code"].text != "200"
            @result = false
            return
        end
        point = doc.elements["/kml/Response/Placemark/Point/coordinates"].text.split(/,/)
        @lng = point[0]
        @lat = point[1]
        @result = true
    end

    def to_s
        "#{@address}: lng:#{@lng} lat:#{@lat}"
    end

end

point = GoogleMapGeocode.new("ÅìµþÅÔÄ£")
puts point
