class AdminController < ApplicationController
  require 'mailchimp'
  require 'parse_config'
  require 'monkey_patch'
  require 'open-uri'
  require 'pp'

  def admin
    if cookies.signed[:spartaUser]
      if cookies.signed[:spartaUser][1] == "admin" || cookies.signed[:spartaUser][1] == "sponsorship" || cookies.signed[:spartaUser][1] == "statistics"
        @user = Parse::Query.new("_User").eq("objectId", cookies.signed[:spartaUser][0]).get.first
      else
        flash[:error] = "You're not an admin."
        redirect_to '/login' and return
      end
    else
      redirect_to '/login' and return
    end

    # Gets a total count of users
    @users_total = Parse::Query.new("_User").tap do |q|
                      q.limit = 1000
                    end.get.length

    @users_total += Parse::Query.new("_User").tap do |q|
                      q.limit = 1000
                      q.skip = 1000
                    end.get.length

    # Gets a total count of RSVPs
    @rsvp_total = Parse::Query.new("RSVP").tap do |q|
                      q.limit = 1000
                      q.eq("attending", true)
                    end.get.length

    @rsvp_total += Parse::Query.new("RSVP").tap do |q|
                      q.limit = 1000
                      q.skip = 1000
                      q.eq("attending", true)
                    end.get.length

    # Collects all the applications with their user object
    @apps = Parse::Query.new("Application").tap do |q|
                      q.limit = 1000
                      q.include = "user"
                    end.get

    @apps += Parse::Query.new("Application").tap do |q|
                      q.limit = 1000
                      q.include = "user"
                      q.skip = 1000
                    end.get

    @apps_total = @apps.length
  
    render layout: false
  end

  def email
    if cookies.signed[:spartaUser]
      if cookies.signed[:spartaUser][1] == "admin" || cookies.signed[:spartaUser][1] == "sponsorship" || cookies.signed[:spartaUser][1] == "statistics"
        @user = Parse::Query.new("_User").eq("objectId", cookies.signed[:spartaUser][0]).get.first
      else
        flash[:error] = "You're not an admin."
        redirect_to '/login' and return
      end
    else
      redirect_to '/login' and return
    end

    # Collects all the applications with their user object
    @apps = Parse::Query.new("Application").tap do |q|
                      q.limit = 1000
                      q.include = "user"
                    end.get

    @apps += Parse::Query.new("Application").tap do |q|
                      q.limit = 1000
                      q.include = "user"
                      q.skip = 1000
                    end.get

    @apps_total = @apps.length

    @new_decisions = 0

    # Count how many decision emails need to be sent
    @apps.each do |app|
      if app["emailStatus"].blank? && app["status"] == "Accepted"
        @new_decisions += 1
      end
    end

    # Collects users that have been notified of an empty app already
    email_flags = Parse::Query.new("EmailFlags").tap do |q|
                    q.limit = 1000
                    q.include = "user"
                  end.get

    email_flags += Parse::Query.new("EmailFlags").tap do |q|
                      q.limit = 1000
                      q.include = "user"
                      q.skip = 1000
                    end.get

    # Creates an array of empty app users' emails
    flagged_users = []
    email_flags.each do |flag|
      flagged_users.push(flag['user']['email'])
    end

    @new_empty_app_first_notice = 0
    @empty_app_users = get_empty_app_users()

    # Count how many users need to be notified of an empty app.
    @empty_app_users.each do |empty_user|
        if !flagged_users.include? empty_user['email']
          @new_empty_app_first_notice += 1
        elsif flagged_users.include? empty_user['email'] 
          user_flags = Parse::Query.new("EmailFlags").tap do |q|
                            q.eq("user", Parse::Pointer.new({
                              "className" => "_User",
                              "objectId"  => empty_user['objectId']
                            }))
                          end.get.first

          if user_flags["firstEmptyApp"] != true
            @new_empty_app_first_notice += 1
          end
        end
    end

    @new_empty_rsvp_first_notice = 0
    @empty_rsvp_users = get_empty_rsvp_acceptances()

    # Count how many users need to be notified of an empty app.
    @empty_rsvp_users.each do |empty_user|
        if !flagged_users.include? empty_user['email']
          @new_empty_rsvp_first_notice += 1
        elsif flagged_users.include? empty_user['email'] 
          user_flags = Parse::Query.new("EmailFlags").tap do |q|
                            q.eq("user", Parse::Pointer.new({
                              "className" => "_User",
                              "objectId"  => empty_user['objectId']
                            }))
                          end.get.first

          if user_flags["firstRsvpReminder"] != true
            @new_empty_rsvp_first_notice += 1
          end
        end
    end    

    render layout: false
  end

  def send_emails
    if email_params['type'] == 'decision'
      @applications = Parse::Query.new("Application").tap do |q|
        q.limit = 1000
        q.eq("emailStatus", nil)
        q.include = "user"
      end.get

      @applications += Parse::Query.new("Application").tap do |q|
        q.limit = 1000
        q.skip = 1000
        q.eq("emailStatus", nil)
        q.include = "user"
      end.get

      @email_count = 0
      @applications.each do |app|

        if app['status'] == "Accepted"
          UserMailer.notify_of_status(app["firstName"], app["user"]['email']).deliver_now
          app['emailStatus'] = true
          app.save
          @email_count += 1
        end

        if @email_count > 40
          sleep(60)
          @email_count = 0
        end

      end
    elsif email_params['type'] == "rsvp-reminder"

      email_flags = Parse::Query.new("EmailFlags").tap do |q|
                      q.limit = 1000
                      q.include = "user"
                    end.get

      email_flags += Parse::Query.new("EmailFlags").tap do |q|
                        q.limit = 1000
                        q.include = "user"
                        q.skip = 1000
                      end.get

      flagged_users = []
      email_flags.each do |flag|
        flagged_users.push(flag['user']['email'])
      end                      

      @empty_rsvp_users = get_empty_rsvp_acceptances()
      @email_count = 0

      @empty_rsvp_users.each do |empty_user|
          if !flagged_users.include? empty_user['email']
            UserMailer.notify_of_empty_rsvp(empty_user['email']).deliver_now
            emailFlag = Parse::Object.new("EmailFlags")
            emailFlag["firstRsvpReminder"] = true
            emailFlag["user"] = empty_user.pointer
            emailFlag.save
            @email_count += 1
          elsif flagged_users.include? empty_user['email'] 
            user_flags = Parse::Query.new("EmailFlags").tap do |q|
                              q.eq("user", Parse::Pointer.new({
                                "className" => "_User",
                                "objectId"  => empty_user['objectId']
                              }))
                            end.get.first

            if user_flags["firstRsvpReminder"] != true
              UserMailer.notify_of_empty_rsvp(empty_user['email']).deliver_now
              user_flags["firstRsvpReminder"] = true
              user_flags.save
              @email_count += 1
            end
          end

          if @email_count > 40
            sleep(60)
            @email_count = 0
          end
      end

    elsif email_params['type'] == "empty_app"
      

      email_flags = Parse::Query.new("EmailFlags").tap do |q|
                      q.limit = 1000
                      q.eq("firstEmptyApp", true)
                      q.include = "user"
                    end.get

      email_flags += Parse::Query.new("EmailFlags").tap do |q|
                        q.limit = 1000
                        q.eq("firstEmptyApp", true)
                        q.include = "user"
                        q.skip = 1000
                      end.get

      flagged_users = []
      email_flags.each do |flag|
        flagged_users.push(flag['user']['email'])
      end

      @empty_app_users = get_empty_app_users()

      @email_count = 0
      @empty_app_users.each do |empty_user|
 
          if !flagged_users.include? empty_user['email']
            UserMailer.notify_of_empty_app(empty_user['email']).deliver_now
            emailFlag = Parse::Object.new("EmailFlags")
            emailFlag["firstEmptyApp"] = true
            emailFlag["user"] = empty_user.pointer
            emailFlag.save

            @email_count +=1

            if @email_count > 40
              break
              sleep(60)
              @email_count = 0
            end
          elsif flagged_users.include? empty_user['email']
            user_flags = Parse::Query.new("EmailFlags").tap do |q|
                              q.eq("user", Parse::Pointer.new({
                                "className" => "_User",
                                "objectId"  => empty_user['objectId']
                              }))
                            end.get.first

            

            if user_flags["firstEmptyApp"] != true
              UserMailer.notify_of_empty_app(empty_user['email']).deliver_now
              user_flags["firstEmptyApp"] = true
              user_flags.save
              @email_count += 1
            end

            if @email_count > 40
              sleep(60)
              @email_count = 0
            end
          end
      end

    end

  end

  def sponsorship
    if cookies.signed[:spartaUser]
      if cookies.signed[:spartaUser][1] == "admin" || cookies.signed[:spartaUser][1] == "sponsorship"
        user = Parse::Query.new("_User").eq("objectId", cookies.signed[:spartaUser][0]).get.first
      else
        flash[:error] = "You're not an admin."
        redirect_to '/login' and return
      end
    else
      redirect_to '/login' and return
    end

    # Used to populate Edit Sponsors section.
    @sponsors = []

    companies = Parse::Query.new("Company").get

    companies.each do |c|
        @sponsors.push([c["objectId"], c["name"]])

        # saves a png version of svg else if png uses the png
        if c["png"].blank?
          if c['img'].url.include? ".svg"
            svg = open(c['img'].url) {|f| f.read }

            # creates a parse File using the private svg_to_png function
            photo = Parse::File.new({
              :body => svg_to_png(svg),
              :local_filename => c["img"].parse_filename.split(".")[0]+".png",
              :content_type => "image/png",
            })

            photo.save

            c["png"] = photo
            c.save
          else
            c["png"] = c['img']
            c.save
          end

        end
    end

    render layout: false
  end

  def addsponsor
    # Adds a sponsor to parse to be displayed on the website.

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
    if cookies.signed[:spartaUser]
      if cookies.signed[:spartaUser][1] == "admin" || cookies.signed[:spartaUser][1] == "sponsorship"
        user = Parse::Query.new("_User").eq("objectId", cookies.signed[:spartaUser][0]).get.first
      else
        flash[:error] = "You're not an admin."
        redirect_to '/login' and return
      end
    else
      redirect_to '/login' and return
    end

    # Populates form with sponsor info to be edited.
    object = view_sponsor_params['object']
    @sponsor = Parse::Query.new("Company").eq("objectId", object).get[0]

    render layout: false

  end

  def editsponsor 
    # Deletes or updates a sponsor 

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
    if cookies.signed[:spartaUser]
      if cookies.signed[:spartaUser][1] == "admin"
        user = Parse::Query.new("_User").eq("objectId", cookies.signed[:spartaUser][0]).get.first
      else
        flash[:error] = "You're not an admin."
        redirect_to '/login' and return
      end
    else
      redirect_to '/login' and return
    end
    
    @apps = Parse::Query.new("Application").tap do |q|
      q.limit = 1000
      q.include = "user"
    end.get

    @apps += Parse::Query.new("Application").tap do |q|
      q.skip = 1000
      q.include = "user"
      q.limit = 1000
    end.get

    render layout: false
  end

  def rsvps
    if cookies.signed[:spartaUser]
      if cookies.signed[:spartaUser][1] == "admin"
        user = Parse::Query.new("_User").eq("objectId", cookies.signed[:spartaUser][0]).get.first
      else
        flash[:error] = "You're not an admin."
        redirect_to '/login' and return
      end
    else
      redirect_to '/login' and return
    end
    
    @rsvps = Parse::Query.new("RSVP").tap do |q|
      q.include = "user,application"
      q.limit = 1000
    end.get

    @rsvps += Parse::Query.new("RSVP").tap do |q|
      q.skip = 1000
      q.include = "user,application"
      q.limit = 1000
    end.get

    render layout: false
  end

  def app_status 
      app = Parse::Query.new("Application").eq("objectId", status_params["object"]).get.first
      if !status_params["status-select"].blank?
        app['status'] = status_params["status-select"]
      else
        app['status'] = nil
      end
      app.save
  end

  def stats
    # Only allow admins to view
    if cookies.signed[:spartaUser]
      if cookies.signed[:spartaUser][1] == "admin" || cookies.signed[:spartaUser][1] == "sponsorship" || cookies.signed[:spartaUser][1] == "statistics"
        user = Parse::Query.new("_User").eq("objectId", cookies.signed[:spartaUser][0]).get.first
      else
        flash[:error] = "You're not an admin."
        redirect_to '/login' and return
      end
    else
      redirect_to '/login' and return
    end

    def age(dob,diq)
      diq = diq.to_date
      diq.year - dob.year - ((diq.month > dob.month || (diq.month == dob.month && diq.day >= dob.day)) ? 0 : 1)
    end

    # Count number of acceptances
    @apps_accepted_total = 0

    # Get all applications
    @apps = Parse::Query.new("Application").tap do |q|
      q.limit = 1000
    end.get
    @apps += Parse::Query.new("Application").tap do |q|
      q.skip = 1000
      q.limit = 1000
    end.get

    # Calculate stats for applications
    @apps = get_stats(@apps,{},"")

    # RSVP setup
    # Gets all rsvps
    @rsvps = Parse::Query.new("RSVP").tap do |q|
      # q.order_by = "createdAt"
      # q.order    = :descending
      q.include = "user,application"
      q.limit = 1000
    end.get

    @rsvps += Parse::Query.new("RSVP").tap do |q|
      q.skip = 1000
      # q.order_by = "createdAt"
      # q.order    = :descending
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
        @rsvpd_applications << rsvp["application"]
      end
    end

    # Calculate stats for rsvps
    @actual_rsvps = @rsvps
    @rsvps = get_stats(@rsvpd_applications, @rsvps, "rsvp")

    render layout: false
  end

  def checkin
    render layout: false
  end

  private

    def svg_to_png(svg)
      scalar = 4
      svg = RSVG::Handle.new_from_data(svg)
      p svg.width
      surface = Cairo::ImageSurface.new(Cairo::FORMAT_ARGB32, svg.width * scalar, svg.height * scalar)
      context = Cairo::Context.new(surface).scale(scalar,scalar)
      context.render_rsvg_handle(svg)
      b = StringIO.new
      surface.write_to_png(b)
      return b.string
    end

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

    def email_params
      params.permit(:object, :"type")
    end 

    def get_empty_app_users
      users_with_apps = []
      
      applications = Parse::Query.new("Application").tap do |q|
        q.limit = 1000
        q.include = "user"
      end.get

      applications += Parse::Query.new("Application").tap do |q|
        q.limit = 1000
        q.include = "user"
        q.skip = 1000
      end.get

      applications.each do |app|
        users_with_apps.push(app["user"]['email'])
      end

      users = Parse::Query.new("_User").tap do |q|
        q.value_not_in("email", users_with_apps)
        q.limit = 1000
      end.get

      users += Parse::Query.new("_User").tap do |q|
        q.value_not_in("email", users_with_apps)
        q.limit = 1000
        q.skip = 1000
      end.get
    end

    def get_empty_rsvp_acceptances
      users_with_rsvps = []
      
      rsvps = Parse::Query.new("RSVP").tap do |q|
        q.limit = 1000
        q.include = "user"
      end.get

      rsvps += Parse::Query.new("RSVP").tap do |q|
        q.limit = 1000
        q.include = "user"
        q.skip = 1000
      end.get

      rsvps.each do |rsvp|
        users_with_rsvps.push(rsvp["user"]['email'])
      end

      applications = Parse::Query.new("Application").tap do |q|
        q.limit = 1000
        q.include = "user"
      end.get

      applications += Parse::Query.new("Application").tap do |q|
        q.limit = 1000
        q.include = "user"
        q.skip = 1000
      end.get

      users = [] 
      applications.each do |app|
        if app["status"] == "Accepted" && app["emailStatus"] == true && users_with_rsvps.include?(app['user']["email"]) == false
          users.push(app["user"])
        end
      end

      return users

    end    

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

        if !app['hackathons'].blank?
          app['hackathons'].each do |hackathon|
            if !@hackathons_attended[hackathon].blank?
              @hackathons_attended[hackathon] += 1
            else
              @hackathons_attended[hackathon] = 1
            end
          end
        end

        if flag != "rsvp"
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
      if flag == "rsvp"
        rsvps.each do |rsvp|
          current_day = ( Time.parse(rsvp['createdAt']) - 9*3600).strftime("%d-%b-%y")
          if !@submission_dates[ current_day ].blank?
            @submission_dates[ current_day ] += 1
          else
            @submission_dates[ current_day ] = 1
          end

          # Closest School (rsvp only)
          if flag == "rsvp"
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
          while ( @input[@random_num]["whyAttend"].blank? && !(@random_reason.include? [@input[@random_num]["whyAttend"],@input[@random_num]["firstName"],@input[@random_num]["lastName"]]) )
            @random_num = rand(0..( @input.length-1 ))
          end
          @random_reason[i][0] = @input[@random_num]["whyAttend"]
          @random_reason[i][1] = @input[@random_num]["firstName"]
          @random_reason[i][2] = @input[@random_num]["lastName"]
        end
      else

      end

      @submission_array = []

      @submission_dates.each do |submission|
        @submission_array.push({"date" => submission[0], "close" => submission[1]})
      end

      # Check if using test database
      if @hackathons_attended.length < 2
        @hackathons_attended = {"test"=>1, "test hi"=>2}
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

      most_common_words = ["the", "be", "to", "of", "and", "a", "in", "that", "have", "i", "it", "for", "not", "on", "with", "he", "as", "you", "do", "at", "this", "but", "his", "by", "from", "they", "we", "say", "her", "she", "or", "an", "will", "my", "one", "all", "would", "there", "their", "what", "so", "up", "out", "if", "about", "who", "get", "which", "go", "me", "when", "make", "can", "like", "time", "no", "just", "him", "know", "take", "person", "into", "year", "your", "good", "some", "could", "them", "see", "other", "than", "then", "now", "look", "only", "come", "its", "over", "think", "also", "back", "after", "use", "two", "how", "our", "work", "first", "well", "way", "even", "new", "want", "because", "any", "these", "give", "day", "most", "us", "im", "ive", "id", "am"]

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