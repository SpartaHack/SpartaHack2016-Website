class AdminController < ApplicationController
  require 'mailchimp'
  require 'parse_config'
  require 'monkey_patch'

  def admin
    if cookies.signed[:spartaUser] && cookies.signed[:spartaUser][1] == "admin"
      user = Parse::Query.new("_User").eq("objectId", cookies.signed[:spartaUser][0]).get.first
      if user['role'] != "admin"
        flash[:error] = "You're not an admin."
        redirect_to '/login' and return
      end
    else
      redirect_to '/login' and return
    end

    @users_total = Parse::Query.new("_User").tap do |q|
      q.limit = 1000
    end.get.length
    
    @apps_total = Parse::Query.new("Application").tap do |q|
      q.limit = 1000
    end.get.length

    render layout: false
  end

  def sponsorship
    if cookies.signed[:spartaUser] && cookies.signed[:spartaUser][1] == "admin"
      user = Parse::Query.new("_User").eq("objectId", cookies.signed[:spartaUser][0]).get.first
      if user['role'] != "admin"
        flash[:error] = "You're not an admin."
        redirect_to '/login' and return
      end
    else
      redirect_to '/login' and return
    end

    @sponsors = []

    companies = Parse::Query.new("Company").get

    companies.each do |c|
        @sponsors.push([c["objectId"], c["name"]])
    end

    render layout: false
  end

  def addsponsor
    logo = add_sponsor_params['picture']

    photo = Parse::File.new({
      :body => logo.read,
      :local_filename => logo.original_filename,
      :content_type => logo.content_type,
      :content_length => logo.tempfile().size().to_s
    })
    photo.save

    company = Parse::Object.new("Company")
    company['name'] = add_sponsor_params['name']
    company['url'] = add_sponsor_params['url']
    company['img'] = photo
    company['level'] = add_sponsor_params['level']

    company.save

    redirect_to '/admin'

  end

  def viewsponsor
    if cookies.signed[:spartaUser] && cookies.signed[:spartaUser][1] == "admin"
      user = Parse::Query.new("_User").eq("objectId", cookies.signed[:spartaUser][0]).get.first
      if user['role'] != "admin"
        flash[:error] = "You're not an admin."
        redirect_to '/login' and return
      end
    else
      redirect_to '/login' and return
    end

    object = view_sponsor_params['object']
    @sponsor = Parse::Query.new("Company").eq("objectId", object).get[0]

    render layout: false

  end

  def editsponsor 
    company = Parse::Query.new("Company").eq("objectId", edit_sponsor_params['object']).get.first
    
    if edit_sponsor_params["commit"] == "Delete"
      company.parse_delete
    else

      if edit_sponsor_params["picture"]
        logo = edit_sponsor_params['picture']
        photo = Parse::File.new({
          :body => logo.read,
          :local_filename => logo.original_filename,
          :content_type => logo.content_type,
          :content_length => logo.tempfile().size().to_s
        })
        photo.save
        company['img'] = photo
      end

      company['name'] = edit_sponsor_params['name']
      company['url'] = edit_sponsor_params['url']
      company['level'] = edit_sponsor_params['level']

      company.save
    end

    redirect_to '/admin'

  end

  def applications
    if cookies.signed[:spartaUser] && cookies.signed[:spartaUser][1] == "admin"
      user = Parse::Query.new("_User").eq("objectId", cookies.signed[:spartaUser][0]).get.first
      if user['role'] != "admin"
        flash[:error] = "You're not an admin."
        redirect_to '/login' and return
      end
    else
      redirect_to '/login' and return
    end
    
    @apps = Parse::Query.new("Application").tap do |q|
      q.limit = 1000
    end.get

    render layout: false
  end

  def status 
      app = Parse::Query.new("Application").eq("objectId", status_params["object"]).get.first
      app['status'] = status_params["status-select"]
      app.save
  end

  def stats
    # Only allow admins to view
    if cookies.signed[:spartaUser] && cookies.signed[:spartaUser][1] == "admin"
      user = Parse::Query.new("_User").eq("objectId", cookies.signed[:spartaUser][0]).get.first
      if user['role'] != "admin"
        flash[:error] = "You're not an admin."
        redirect_to '/login' and return
      end
    else
      redirect_to '/login' and return
    end

    # Gets all applications
    @apps = Parse::Query.new("Application").tap do |q|
      q.limit = 1000
    end.get

    def age(dob,diq)
      diq = diq.to_date
      diq.year - dob.year - ((diq.month > dob.month || (diq.month == dob.month && diq.day >= dob.day)) ? 0 : 1)
    end


    # gender count [male, female, nonbinary]
    @gender_count = {"male"=>0, "female"=>0, "non-binary"=>0, "prefer-not"=>0}

    # Hash of university => attendee count
    @uni_applicants = {"High School"=>0};
    @international_count=0;

    # Age
    @age_count = { };
    @minor_count = 0;
    @adult_count = 0;

    # Get date of hackathon: feb 26
    @start_date = Date.new(2016, 2, 26)

    @total_apps = @apps.length

    # First Year, Second Year, Third Year, Fourth Year, Fifth Year, Graduate Student, Not a Student
    @uni_grade_count = {"First Year"=>0,"Second Year"=>0,"Third Year"=>0,"Fourth Year"=>0,"Fifth Year +"=>0,"Graduate Student"=>0,"High School Student"=>0, "Not a Student"=>0};

    # Majors
    @major_count = {};


    # Number Hackathons attended
    # { number => frequency }
    @hackathons_count = {0=>0,1=>0,2=>0,3=>0,4=>0,5=>0,6=>0,7=>0,8=>0,9=>0,10=>0,11=>0,12=>0,13=>0,14=>0,15=>0}

    @submission_dates = {}

    # Start huge loop
    @apps.each do |app|
      # Gender
      if !app['gender'].blank? && !@gender_count[app['gender']].blank?
        @gender_count[app['gender']]+=1;
      else
        @gender_count["nonbinary"]+=1;
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
        curr_bday = Time.zone.local(app['birthyear'].to_i, Date::MONTHNAMES.index(app['birthmonth'].to_i), app['birthday'].to_i, 0, 0)
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

      # Applications per day
      current_day = ( Time.parse(app['createdAt']) - 9*3600).strftime("%d-%B-%Y")
      if !@submission_dates[ current_day ].blank?
        @submission_dates[ current_day ] += 1
      else
        @submission_dates[ current_day ] = 1
      end

    # End huge loop
    end

    # Sorting
    @age_count = @age_count.sort_by {|value, _key| value}
    @uni_applicants = @uni_applicants.sort_by {|_key, value| value}.reverse
    @major_count = @major_count.sort_by {|_key, value| value}.reverse
    @hackathons_count = @hackathons_count.sort_by {|value,_key| value}

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

    @apps.each do |app|
      if !app['whyAttend'].blank?
        @master_string += " " + app['whyAttend']
      end
    end
    @common_words = most_common(@master_string)
    @common_words = @common_words.sort_by {|_key, value| value}.reverse
  end

  private

  def add_sponsor_params
    params.permit(:picture, :name, :url, :level)
  end   

  def edit_sponsor_params
    params.permit(:picture, :name, :url, :level, :commit, :object)
  end   

  def view_sponsor_params
    params.permit(:object)
  end   

  def status_params
    params.permit(:object, :"status-select")
  end 

end