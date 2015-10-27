class PagesController < ApplicationController
	require 'mailchimp'
  require 'parse_config'
  require 'monkey_patch'

  def index
    @partner = []
    @trainee = []
    @warrior = []
    @commander = []

    companies = Parse::Query.new("Company").get

    companies.each do |c|
      if c["level"] == "partner"
        @partner.push([c["url"], c["img"].url, c["name"]])
      elsif c["level"] == "trainee"
        @trainee.push([c["url"], c["img"].url, c["name"]])
      elsif c["level"] == "warrior"
        @warrior.push([c["url"], c["img"].url, c["name"]])
      elsif c["level"] == "commander"
        @commander.push([c["url"], c["img"].url, c["name"]])    
      end
    end

    render layout: false
  end

  def subscribe 
  	render layout: false
  	mailchimp = Mailchimp::API.new(ENV["MAILCHIMP_API_KEY"])
		mailchimp.lists.subscribe(ENV["MAILCHIMP_LIST_ID"], 
		                   { "email" => subscribe_params['emailinput']
		                   },{'FNAME' => subscribe_params['fname'] , "LNAME" => subscribe_params['lname'] })
	end


  private

  def subscribe_params
    params.permit(:emailinput, :fname, :lname)
  end
end