#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'json'

BASE_URL = 'http://localhost:3000'
USER_NAME = 'testuser123'

def make_request(endpoint, params = {})
  uri = URI("#{BASE_URL}#{endpoint}")
  http = Net::HTTP.new(uri.host, uri.port)
  
  request = Net::HTTP::Post.new(uri)
  request['Content-Type'] = 'application/json'
  request.body = params.to_json
  
  response = http.request(request)
  
  puts "Request #{@request_count}: #{response.code} #{response.message}"
  if response.code == '429'
    body = JSON.parse(response.body)
    puts "  Rate Limited: #{body['message']}"
    puts "  Retry After: #{response['Retry-After']} seconds"
  elsif response.code.start_with?('2')
    body = JSON.parse(response.body)
    puts "  Success: #{body['message'] || body['status']}"
  else
    puts "  Error: #{response.body}"
  end
  
  response
rescue => e
  puts "Error making request: #{e.message}"
end

puts "Testing Rate Limiting - Making 7 requests to trigger rate limit"
puts "Rate limit: 5 requests per minute"
puts "-" * 60

@request_count = 0

7.times do |i|
  @request_count = i + 1
  response = make_request('/api/clock_in', { user: USER_NAME })
  
  sleep(0.5)
end

puts "\nTest completed. The last 2 requests should have been rate-limited and return with 429 status."
puts "Wait 60 seconds and run again to see rate limit reset."
