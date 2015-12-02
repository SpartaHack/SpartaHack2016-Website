require 'parse-ruby-client'

Parse.init :application_id => ENV["PARSE_APP_ID"],
    :api_key        => ENV["PARSE_API_KEY"]
