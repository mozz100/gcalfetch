# Copyright 2011 by Richard Morrison http://www.rmorrison.net
# licensed under a Creative Commons Attribution-ShareAlike 2.0 UK: England & Wales License.
# http://creativecommons.org/licenses/by-sa/2.0/uk/

require 'nokogiri'
require 'net/http'
require 'uri'
require 'json'

run lambda { |env|
  response_code = 500  # assume the worst...
  begin
    # parse out the calendar url, callback, max_results and format params
    params = Rack::Request.new(env).params
    calendar_url = params['cal']
    callback = params['callback']
    max_results = params['max_results'] ? params['max_results'].to_i : nil
    format = params['format'] || 'json'

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

    if max_results and max_results > 0
      data = {'results'=>titles[0..max_results-1]}
    else
      data = {'results'=>titles}
    end

    response_code = 200
  rescue
    # catch error and output it
    data = {'error'=> $!.to_s, 'results' => []}
  end

  # write stuff back to the requester, wrapped in JSONP callback if necessary
  if format == 'json'
    response_body = data.to_json
    response_body = callback + "(#{response_body});" if callback
  elsif format == 'txt'
    response_body = data['results'].join("\n")
    response_body = "(no results)" if response_body == ""
  end

  return [
    response_code, 
    {'Content-Type'=>'application/json'},
    StringIO.new(response_body)
  ]
}
