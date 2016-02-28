class PagesController < ApplicationController
	require 'mailchimp'
  require 'parse_config'
  require 'monkey_patch'
  require 'pp'
  require 'json'

  def index
    if cookies.signed[:spartaUser]
			if cookies.signed[:spartaUser][1] == "attendee"
	      begin
	        @application = Parse::Query.new("Application").tap do |q|
	          q.eq("user", Parse::Pointer.new({
	            "className" => "_User",
	            "objectId"  => cookies.signed[:spartaUser][0]
	          }))
	        end.get.first

	      rescue
	        redirect_to "/outage" and return
	      end
			end

			@user = Parse::Query.new("_User").tap do |q|
				q.eq("objectId", cookies.signed[:spartaUser][0])
			end.get.first

    end



    begin
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

      @partner= @partner.sort do |a,b|
        a[2] <=> b[2]
      end

      @trainee= @trainee.sort do |a,b|
        a[2] <=> b[2]
      end

      @warrior= @warrior.sort do |a,b|
        a[2] <=> b[2]
      end

      @commander= @commander.sort do |a,b|
        a[2] <=> b[2]
      end

      @team = []

      team_raw = Parse::Query.new("Team").get

      team_raw.each do |t|
        @team.push([t["url"], t["img"].url, t["name"], t["position"], t["order"], t["position2"]])
      end

      @team= @team.sort do |a,b|
        a[4] <=> b[4]
      end

    rescue
      redirect_to "/outage" and return
    end

      @schedule = [
        [ 26, "Friday",[ ] ],
        [ 27, "Saturday",[ ] ],
        [ 28, "Sunday",[ ] ]
      ]

      schedule_raw = Parse::Query.new("Schedule").eq("publicBeforeEvent", true).get

      schedule_raw.each do |s|
        day = s["eventTime"].in_time_zone("Eastern Time (US & Canada)").strftime("%e")
        time = s["eventTime"].in_time_zone("Eastern Time (US & Canada)").strftime("%H:%M")
        time_end = !s["eventTimeEnd"].blank? ? s["eventTimeEnd"].in_time_zone("Eastern Time (US & Canada)").strftime("%H:%M") : nil
        if day.to_i == 26
          @schedule[0][2].push([[time, time_end],s["eventTitle"],s["category"]])
        elsif day.to_i == 27
          @schedule[1][2].push([[time, time_end],s["eventTitle"],s["category"]])
        else
          @schedule[2][2].push([[time, time_end],s["eventTitle"],s["category"]])
        end
      end

      @schedule[0][2]= @schedule[0][2].sort do |a,b|
        a[0] <=> b[0]
      end

      @schedule[1][2]= @schedule[1][2].sort do |a,b|
        a[0] <=> b[0]
      end

      @schedule[2][2]= @schedule[2][2].sort do |a,b|
        a[0] <=> b[0]
      end

    render layout: false
  end

  def map
    map = File.join(Rails.root, "app/assets/pdfs/SpartaHack 2016 Map.pdf")
    send_file(map, :filename => "SpartaHack 2016 Map.pdf", :disposition => 'inline', :type => "application/pdf")
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
      begin
      	mailchimp = Mailchimp::API.new(ENV["MAILCHIMP_API_KEY"])
    		mailchimp.lists.subscribe(ENV["MAILCHIMP_VOL_LIST_ID"],
    		                   { "email" => subscribe_params['emailinput']
    		                   },{'FNAME' => subscribe_params['fname'] , "LNAME" => subscribe_params['lname'] })
        render layout: false
      rescue
        flash[:error] = "You've already signed up with this email."
        redirect_to "/#contact" and return
      end
    end

	end

  def winners2015
    render layout: false
  end

  def outage
    render layout: false
  end

  def tables
    redirect_to 'https://docs.google.com/spreadsheets/d/1PaBMyiiEhUnkGXBcQyvL6wBGM8Tblnx6u826o7J7qXk/edit?usp=sharing'
  end

  def judging
    redirect_to 'https://docs.google.com/forms/d/1HJAPH6-Fy6ynxONi_3-F16TkdINn5oG1F_h5CS4s0Ns/viewform'
  end

  def hangout
    redirect_to 'https://talkgadget.google.com/hangouts/_/xkodgcsi4uolmwx2z3siz7q2yya'
  end

  private

  def subscribe_params
    params.permit(:emailinput, :fname, :lname)
  end

end
