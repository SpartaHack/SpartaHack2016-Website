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

    begin
      @announcements_array = []
      announcements = Parse::Query.new("Announcements").tap do |q|
                        q.order_by = "updatedAt"
                        q.order = :descending
                      end.get

      announcements.each do |a|
        string_array = a["Description"].split(" ")
        announcement_string = ""

        string_array.each do |word|
          if word.include? "http"
            announcement_string += " <a href='#{word}'>#{word}</a>"
          else
            announcement_string += " #{word}"
          end
        end

        time = ( ( Time.now - DateTime.parse(a['updatedAt']) ) / ( 60 * 60) ).to_i
        time_string = ""

        if time < 1
          time = ( ( Time.now - DateTime.parse(a['updatedAt']) ) / 60 ).to_i
          if time > 1
            time_string = "#{time} minutes ago"
          elsif time == 1
            time_string = "1 minute ago"
          else
            time_string = "#{( ( Time.now - DateTime.parse(a['updatedAt']) ) ).to_i} seconds ago"
          end
        else
          if time > 1
            time_string = "#{time} hours ago"
          else
            time_string = "1 hour ago"
          end
        end

        time = "#{} hours ago"
        @announcements_array.push([a['Title'], announcement_string.strip, time_string])
      end

      @prizes_array = []
      prizes = Parse::Query.new("Prizes").tap do |q|
                        q.include = "sponsor"
                        q.order_by = "name"
                        q.order = :ascending
                      end.get

      prizes.each do |prize|
        @prizes_array.push([prize["name"], prize["description"], !prize["sponsor"].blank? ? "<a href='#{prize['sponsor']['url']}' target='_blank'>#{prize['sponsor']['name']}</a>" : "<a href='/' target='_blank'>SpartaHack</a>"])
      end

      @hardware_array = []
      hardware = Parse::Query.new("Hardware").tap do |q|
                        q.order_by = "name"
                        q.order = :ascending
                      end.get

      hardware.each do |hardware|
        @hardware_array.push([hardware['name'], !hardware["inventory"].blank? ? hardware["inventory"] : "Many", !hardware["lender"].blank? ? hardware["lender"] : "SpartaHack"])
      end

      @resources_array = []
      resources = Parse::Query.new("Resources").tap do |q|
                        q.order_by = "name"
                        q.order = :ascending
                        q.include = "sponsor"
                      end.get

      resources.each do |resource|
        @resources_array.push([resource['name'], resource["url"], resource["sponsor"]])
      end

      @faq_array = []
      faq = Parse::Query.new("FAQ").tap do |q|
                        q.order_by = "order"
                        q.order = :ascending
                      end.get

      faq.each do |qa|
        @faq_array.push([qa['question'], qa["answer"]])
      end


    rescue
      redirect_to "/outage" and return
    end

      @schedule = [
        ["Friday",[ ] ],
        ["Saturday",[ ] ],
        ["Sunday",[ ] ]
      ]

      schedule_raw = Parse::Query.new("Schedule").get

      schedule_raw.each do |s|
        day = s["eventTime"].in_time_zone("Eastern Time (US & Canada)").strftime("%e")
        time = s["eventTime"].in_time_zone("Eastern Time (US & Canada)").strftime("%H:%M")
        if day.to_i == 26
          @schedule[0][1].push([time,s["eventTitle"],s["eventDescription"],s["eventLocation"]])
        elsif day.to_i == 27
          @schedule[1][1].push([time,s["eventTitle"],s["eventDescription"],s["eventLocation"]])
        else
          @schedule[2][1].push([time,s["eventTitle"],s["eventDescription"],s["eventLocation"]])
        end
      end

      @schedule[0][1]= @schedule[0][1].sort do |a,b|
        a[0] <=> b[0]
      end

      @schedule[1][1]= @schedule[1][1].sort do |a,b|
        a[0] <=> b[0]
      end

      @schedule[2][1]= @schedule[2][1].sort do |a,b|
        a[0] <=> b[0]
      end
    render layout: false
  end

end
