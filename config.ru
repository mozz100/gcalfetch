# by Richard Morrison http://www.rmorrison.net

require 'nokogiri'
require 'net/http'
require 'uri'
require 'json'

run lambda { |env|
  response_code = 500  # assume the worst...
  begin
    # parse out the calendar url and callback params
    params = Rack::Request.new(env).params
    calendar_url = params['cal']
    callback = params['callback']

    # catch gotcha
    raise 'Supply a url-encoded private xml address for a Google calendar as the cal parameter on the querystring' unless calendar_url

    # prepare to GET from the Google API.  Note - https is ok but no verification is done - quick 'n' dirty
    url = URI.parse("#{calendar_url}")
    http = Net::HTTP.new(url.host, url.port)
    if url.scheme == 'https'
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    # assemble request for Google calendar, filtering to results that 
    # started before now and end after now.  i.e. current appointments

    s = http.get(
      url.path + "?" +
        "fields=entry(title)&" +  # Retrieve titles only
        "singleevents=true&" +
        "start-min=#{Time.now.utc.xmlschema}&" + 
        "start-max=#{(Time.now + 1).utc.xmlschema}"
    ).body

    # Use Nokogiri to parse, retrieve just get the titles
    doc = Nokogiri::XML(s)
    titles = doc.css('feed entry title').map(&:text) # returns an array of titles

    data = {'results'=>titles}
    response_code = 200
  rescue
    # catch error and output it
    data = {'error' => $!.to_s}
  end

  # write stuff back to the requester, wrapped in JSONP callback if necessary
  response_body = data.to_json
  response_body = callback + "(#{response_body});" if callback

  return [
    response_code, 
    {'Content-Type'=>'application/json'},
    StringIO.new(response_body)
  ]
}
