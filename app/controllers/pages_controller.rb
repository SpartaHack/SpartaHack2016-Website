class PagesController < ApplicationController
	require 'mailchimp'

  def index
  	render layout: false
  end

  def subscribe 
    begin
    	mailchimp = Mailchimp::API.new(ENV["MAILCHIMP_API_KEY"])
  		mailchimp.lists.subscribe(ENV["MAILCHIMP_LIST_ID"], 
  		                   { "email" => subscribe_params['emailinput']
  		                   },{'FNAME' => subscribe_params['fname'] , "LNAME" => subscribe_params['lname'] })
      render layout: false
      rescue Mailchimp::ListAlreadySubscribedError => e
        redirect_to '/subscribed'
      end
	end

  private

  def subscribe_params
    params.permit(:emailinput, :fname, :lname)
  end		
end