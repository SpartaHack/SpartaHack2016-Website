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
    
    if subscribe_params[:emailinput] == "" && subscribe_params[:fname] == "" && subscribe_params[:lname] == ""
      flash[:error] = "You cannot submit an empty form."
      redirect_to "/#contact" and return
    elsif subscribe_params[:fname] == "" || subscribe_params[:lname] == ""
      flash[:error] = "You must include your full name."
      flash[:fname] = subscribe_params[:fname]
      flash[:lname] = subscribe_params[:lname]
      flash[:emailinput] = subscribe_params[:emailinput]
      redirect_to "/#contact" and return
    elsif subscribe_params[:emailinput] == ""
      flash[:error] = "You must include your email."
      flash[:fname] = subscribe_params[:fname]
      flash[:lname] = subscribe_params[:lname]
      redirect_to "/#contact" and return
    elsif subscribe_params[:emailinput].downcase !~ /\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i
      flash[:error] = "You must include a valid email."
      flash[:fname] = subscribe_params[:fname]
      flash[:lname] = subscribe_params[:lname]
      redirect_to "/#contact" and return
    else
    	render layout: false
    	mailchimp = Mailchimp::API.new(ENV["MAILCHIMP_API_KEY"])
  		mailchimp.lists.subscribe(ENV["MAILCHIMP_VOL_LIST_ID"], 
  		                   { "email" => subscribe_params['emailinput']
  		                   },{'FNAME' => subscribe_params['fname'] , "LNAME" => subscribe_params['lname'] })
    end
    
	end


  private

  def subscribe_params
    params.permit(:emailinput, :fname, :lname)
  end
  
end