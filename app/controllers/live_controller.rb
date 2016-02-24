class LiveController < ApplicationController
  require 'mailchimp'
  require 'parse_config'
  require 'monkey_patch'
  require 'pp'
  require 'json'

  def live
    if cookies.signed[:spartaUser] && cookies.signed[:spartaUser][1] == "attendee"
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

      # user = Parse::Query.new("_User").eq("objectId", cookies.signed[:spartaUser][0]).get.first
      # data = { :alert => "This is a notification, dm Bogdan if you got it" }
      # push = Parse::Push.new(data, cookies.signed[:spartaUser][0])
      # push.save


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

end
