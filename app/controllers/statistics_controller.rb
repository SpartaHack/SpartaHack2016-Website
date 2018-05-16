class StatisticsController < ApplicationController
  require 'mailchimp'
  require 'parse_config'
  require 'monkey_patch'
  require 'pp'

  def stats
    # Only allow admins to view
    if cookies.signed[:spartaUser]
        @user = $client.query("_User").eq("objectId", cookies.signed[:spartaUser][0]).get.first
    end

    def age(dob,diq)
      diq = diq.to_date
      diq.year - dob.year - ((diq.month > dob.month || (diq.month == dob.month && diq.day >= dob.day)) ? 0 : 1)
    end

    # Count number of acceptances
    @apps_accepted_total = 0

    # Get all applications
    @apps = $client.query("Application").tap do |q|
      q.limit = 1000
      q.include = "user"
    end.get
    @apps += $client.query("Application").tap do |q|
      q.skip = 1000
      q.limit = 1000
      q.include = "user"
    end.get

    # Calculate stats for applications
    @apps = get_stats(@apps,{},"")

    # RSVP setup
    # Gets all rsvps
    @rsvps = $client.query("RSVP").tap do |q|
      q.include = "user,application"
      q.limit = 1000
    end.get

    @rsvps += $client.query("RSVP").tap do |q|
      q.skip = 1000
      q.include = "user,application"
      q.limit = 1000
    end.get

    @rsvpd_applications = []
    @rsvp_attending_count = 0
    @rsvps_total=0

    @rsvps.each do |rsvp|
      @rsvps_total+=1
      if rsvp["attending"]==true
        @rsvp_attending_count += 1

        if !rsvp["application"].blank?
          rsvp["application"]["user"] = rsvp["user"]
          @rsvpd_applications << rsvp["application"]
        end
      end
    end

    # Calculate stats for rsvps
    @actual_rsvps = @rsvps
    @rsvps = get_stats(@rsvpd_applications, @rsvps, "rsvp")



    @attending_total = 0
    @attending_applications = []
    # Attending stats setup
    # Gets all attendees
    @attendees = $client.query("Attendance").tap do |q|
      q.include = "user,rsvp,application"
      q.limit = 1000
    end.get

    @attendees.each do |attendee|
      @attending_total+=1
      if !attendee["application"].blank?
        attendee["application"]["user"] = attendee["user"]

        # setup the rsvp specific info
        if !attendee['rsvp'].blank?
          attendee["restrictions"] = attendee["rsvp"]["restrictions"]
          attendee["tshirt"] = attendee["rsvp"]["tshirt"]
          attendee["university"] = attendee["rsvp"]["university"]
          attendee["whyAttend"] = attendee["rsvp"]["whyAttend"]
        end

        @attending_applications << attendee["application"]
      end
    end
    @actual_attendees = @attendees
    @attendees = get_stats(@attending_applications, @attendees, "attending")

    render layout: false
  end

  private

  # stats on users
  def get_stats(users, rsvps, flag) # flag used to check for user pointers in rsvp table
    @input = {}

    @input = users
    if flag == ""
      @total_apps = @input.length
    end

    # gender count [male, female, nonbinary]
    @gender_count = {"male"=>0, "female"=>0, "non-binary"=>0, "prefer-not"=>0}

    # Hash of university => attendee count
    @uni_applicants = {"High School"=>0};
    @international_count=0;

    @closest_school = {}

    # Age
    @age_count = { };
    @minor_count = 0;
    @adult_count = 0;

    # Get date of hackathon: feb 26
    @start_date = Date.new(2016, 2, 26)

    # First Year, Second Year, Third Year, Fourth Year, Fifth Year, Graduate Student, Not a Student
    @uni_grade_count = {"First Year"=>0,"Second Year"=>0,"Third Year"=>0,"Fourth Year"=>0,"Fifth Year +"=>0,"Graduate Student"=>0,"High School Student"=>0, "Not a Student"=>0};

    # Majors
    @major_count = {};

    # Dietary Restrictions
    @restriction_count = {}
    @other_restrictions = {}

    # T-shirt sizes
    @tshirt_count = {"Unisex XS"=>0, "Unisex Small"=>0, "Unisex Medium"=>0, "Unisex Large"=>0, "Unisex XL"=>0, "Unisex XXL"=>0, "Women's XS"=>0, "Women's Small"=>0, "Women's Medium"=>0, "Women's Large"=>0, "Women's XL"=>0, "Women's XXL"=>0 }

    # Number Hackathons attended
    # { number => frequency }
    @hackathons_count = {0=>0,1=>0,2=>0,3=>0,4=>0,5=>0,6=>0,7=>0,8=>0,9=>0,10=>0,11=>0,12=>0,13=>0,14=>0,15=>0}

    @hackathons_attended = {}

    @submission_dates = {}

    # Start huge loop
    @input.each do |app|
      # Gender
      if !app['gender'].blank?
        @gender_count[app['gender']] +=1 ;
      end

      if app['status'] == "Accepted" && flag == ""
        @apps_accepted_total += 1
      end

      # Universities
      if !app['university'].blank?
        if !(app["university"][0..2] =="USA")
          @international_count += 1
        end
        if @uni_applicants[ app['university'] ]
          @uni_applicants[ app['university'] ] += 1
        else
          @uni_applicants[ app['university'] ] = 1
        end
      else
        if !app['otherUniversity'].blank?
          if @uni_applicants[ app['otherUniversity'] ]
            @uni_applicants[ app['otherUniversity'] ] += 1
          else
            @uni_applicants[ app['otherUniversity'] ] = 1
          end
        else
          @uni_applicants['High School'] += 1
        end
      end

      # Ages
      if !app['birthyear'].blank?
        curr_bday = Time.zone.local(app['birthyear'].to_i, Date::MONTHNAMES.index(app['birthmonth']), app['birthday'].to_i, 0, 0)
        if age(curr_bday, @start_date) < 18
          @minor_count+=1
        else
          @adult_count+=1
        end
        if !@age_count[age(curr_bday, @start_date)].blank?
          @age_count[ age(curr_bday, @start_date) ] += 1
        else
          @age_count[ age(curr_bday, @start_date) ] = 1
        end
      end

      # Grade level
      if app['universityStudent'] == 'true'
        if !app['gradeLevel'].blank?
          if !@uni_grade_count[app['gradeLevel']].blank?
            @uni_grade_count[ app['gradeLevel'] ] += 1
          else
            @uni_grade_count[ app['gradeLevel'] ] = 1
          end
        end
      else
        @uni_grade_count['High School Student'] += 1
      end

      # Majors
      if !app['major'].blank?
        app['major'].each do |major|
          if !@major_count[major].blank?
            @major_count[major] += 1
          else
            @major_count[major] = 1
          end
        end
      end

      # Hackathons
      if !app['hackathons'].blank?
        if !@hackathons_count[app['hackathons'].length].blank?
          @hackathons_count[ app['hackathons'].length ] += 1
        else
          @hackathons_count[ app['hackathons'].length ] = 1
        end
      else
        @hackathons_count[ 0 ] += 1
      end

      if !app['hackathons'].blank?
        app['hackathons'].each do |hackathon|
          if !@hackathons_attended[hackathon].blank?
            @hackathons_attended[hackathon] += 1
          else
            @hackathons_attended[hackathon] = 1
          end
        end
      end

      if flag == ""
        # Applications per day
        current_day = ( Time.parse(app['createdAt']) - 9*3600).strftime("%d-%b-%y")
        if !@submission_dates[ current_day ].blank?
          @submission_dates[ current_day ] += 1
        else
          @submission_dates[ current_day ] = 1
        end
      end

    end

    # Loop through actual RSVPs
    if flag != ""
      rsvps.each do |rsvp|
        if flag == "attending"
          current_day = (Time.parse(rsvp['createdAt']).in_time_zone("Eastern Time (US & Canada)")).strftime("%d-%b-%y-%H-%M")
          minute = current_day[-2..-1].to_i

          if minute <= 7
            current_day = current_day[0..-3] + "00"
          elsif minute > 7 && minute <= 22
            current_day = current_day[0..-3] + "15"
          elsif minute > 22 && minute <= 37
            current_day = current_day[0..-3] + "30"
          elsif minute > 37 && minute <= 52
            current_day = current_day[0..-3] + "45"
          elsif minute > 52 && minute <= 59
            hour = current_day[-5..-4]

            if hour.to_i == 23
              current_day = (current_day[0..1].to_i + 1).to_s + current_day[2..-6] + "00-00"
            else
              if hour.to_i < 9
                current_day = current_day[0..-5] + (current_day[-4..-4].to_i + 1).to_s + "-00"
              else
                current_day = current_day[0..-6] + (hour.to_i + 1).to_s + "-00"
              end
            end
          end

        else
          current_day = ( Time.parse(rsvp['createdAt'])).strftime("%d-%b-%y")
        end

        if !@submission_dates[ current_day ].blank?

          @submission_dates[ current_day ] += 1
        else
          @submission_dates[ current_day ] = 1
        end

        # Closest School (rsvp only)
        if flag != ""
          if !rsvp['university'].blank?
            if @closest_school[ rsvp['university'] ]
              @closest_school[ rsvp['university'] ] += 1
            else
              @closest_school[ rsvp['university'] ] = 1
            end
          end

          # Dietary Restrictions!
          if !rsvp['restrictions'].blank?
            rsvp['restrictions'].each do |restriction|
              if restriction == "other"
                @other_restrictions[rsvp['otherRestrictions']] = rsvp['otherRestrictions']
              end
              if !@restriction_count[restriction].blank?
                @restriction_count[restriction] += 1
              else
                @restriction_count[restriction] = 1
              end
            end
          end

          # T-shirt sizes
          if !rsvp['tshirt'].blank?

            if @tshirt_count[ rsvp['tshirt'] ]
              @tshirt_count[ rsvp['tshirt'] ] += 1
            else
              @tshirt_count[ rsvp['tshirt'] ] = 1
            end
          end

        end
      end
    end

    # Random reason for wanting to attend SpartaHack
    # [reason, first name, last name]
    @random_reason = [[""],[""],[""],[""],[""],[""],[""],[""],[""]]
    if @input.length-1 > 20
      for i in 0..3 # three random reasons :)
        @random_num = rand(0..( @input.length-1 ))
        while ( @input[@random_num]["whyAttend"].blank? && !(@random_reason.include? [@input[@random_num]["whyAttend"],@input[@random_num]["user"]["firstName"],@input[@random_num]["user"]["lastName"]]) )
          @random_num = rand(0..( @input.length-1 ))
        end
        @random_reason[i][0] = @input[@random_num]["whyAttend"]
        @random_reason[i][1] = @input[@random_num]["user"]["firstName"]
        @random_reason[i][2] = @input[@random_num]["user"]["lastName"]
      end
    else

    end

    @submission_array = []

    @submission_dates.each do |submission|
      @submission_array.push({"date" => submission[0], "close" => submission[1]})
    end

    # Populate the hackathons_attended list if empty
    if @hackathons_attended.length < 1
      @hackathons_attended = {"MHacks VI F15"=>1}
    end

    # Sorting
    @age_count = @age_count.sort_by {|value, _key| value}
    @uni_applicants = @uni_applicants.sort_by {|_key, value| value}.reverse
    @major_count = @major_count.sort_by {|_key, value| value}.reverse
    @hackathons_count = @hackathons_count.sort_by {|value,_key| value}
    @hackathons_attended = @hackathons_attended.sort_by {|_key, value| value}.reverse

    @closest_school = @closest_school.sort_by {|_key, value| value}.reverse
    @restriction_count = @restriction_count.sort_by {|_key, value| value}.reverse

    if flag == ""
      @uni_count = @uni_applicants.length
    end

    # Find most common words for word map
    def most_common(str)
      str.gsub(/./) do |c|
        case c
        when /\w/ then c.downcase
        when /\s/ then c
        else ''
        end
      end.split
         .group_by {|w| w}
         .map {|k,v| [k,v.size]}
         .sort_by(&:last)
         .reverse
         .to_h
    end

    @master_string = ""

    @input.each do |app|
      if !app['whyAttend'].blank?
        @master_string += " " + app['whyAttend']
      end
    end
    @common_words = most_common(@master_string)

    most_common_words = ["the", "be", "to", "of", "and", "a", "in", "that",
      "have", "i", "it", "for", "not", "on", "with", "he", "as", "you", "do",
      "at", "this", "but", "his", "by", "from", "they", "we", "say", "her",
      "she", "or", "an", "will", "my", "one", "all", "would", "there",
      "their", "what", "so", "up", "out", "if", "about", "who", "get",
      "which", "go", "me", "when", "make", "can", "like", "time", "no",
      "just", "him", "know", "take", "person", "into", "year", "your", "good",
      "some", "could", "them", "see", "other", "than", "then", "now", "look",
      "only", "come", "its", "over", "think", "also", "back", "after", "use",
      "two", "how", "our", "work", "first", "well", "way", "even", "new",
      "want", "because", "any", "these", "give", "day", "most", "us", "im",
      "ive", "id", "am"]

    most_common_words.each do |word|
      @common_words.delete(word)
    end

    @common_words = @common_words.sort_by {|_key, value| value}.reverse

    @output = {}
    @output["gender_count"] = @gender_count
    @output["age_count"] = @age_count
    @output["minor_count"] = @minor_count
    @output["adult_count"] = @adult_count
    @output["uni_applicants"] = @uni_applicants
    @output["international_count"] = @international_count
    @output["major_count"] = @major_count
    @output["hackathons_count"] = @hackathons_count
    @output["hackathons_attended"] = @hackathons_attended
    @output["random_reason"] = @random_reason
    @output["submission_array"] = @submission_array
    @output["uni_grade_count"] = @uni_grade_count
    @output["common_words"] = @common_words
    @output["closest_school"] = @closest_school
    @output["dietary_restrictions"] = @restriction_count
    @output["other_restrictions"] = @other_restrictions
    @output["tshirt_count"] = @tshirt_count

    return @output
  end

end
