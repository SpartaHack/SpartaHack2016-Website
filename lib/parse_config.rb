require 'parse-ruby-client'

$client = Parse.create :application_id => ENV["PARSE_APP_ID"],
    :api_key        => ENV["PARSE_API_KEY"],
    :master_key        => ENV["PARSE_APP_M"],
    :host           => 'http://localhost:1337'
