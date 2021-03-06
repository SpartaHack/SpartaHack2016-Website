class AdminController < ApplicationController
  require 'mailchimp'
  require 'parse_config'
  require 'monkey_patch'
  require 'open-uri'
  require 'net/http'
  require 'net/https'
  require 'rubygems'
  require 'rest-client'
  require 'json'
  require 'digest/sha1'
  require 'pp'


  def admin
    if cookies.signed[:spartaUser]
      if cookies.signed[:spartaUser][1] == "admin" || cookies.signed[:spartaUser][1] == "volunteer" || cookies.signed[:spartaUser][1] == "sponsorship" || cookies.signed[:spartaUser][1] == "statistics"
        @user = $client.query("_User").eq("objectId", cookies.signed[:spartaUser][0]).get.first
      else
        flash[:error] = "You're not an admin."
        redirect_to '/login' and return
      end
    else
      redirect_to '/login' and return
    end

    # Gets a total count of users
    @users_total = $client.query("_User").tap do |q|
                      q.limit = 1000
                    end.get.length

    @users_total += $client.query("_User").tap do |q|
                      q.limit = 1000
                      q.skip = 1000
                    end.get.length

    @users_total += $client.query("_User").tap do |q|
                      q.limit = 1000
                      q.skip = 2000
                    end.get.length

    # Gets a total count of RSVPs
    @rsvp_total = $client.query("RSVP").tap do |q|
                      q.limit = 1000
                      q.eq("attending", true)
                    end.get.length

    @rsvp_total += $client.query("RSVP").tap do |q|
                      q.limit = 1000
                      q.skip = 1000
                      q.eq("attending", true)
                    end.get.length

    # Collects all the applications with their user object
    @apps = $client.query("Application").tap do |q|
                      q.limit = 1000
                      q.include = "user"
                    end.get

    @apps += $client.query("Application").tap do |q|
                      q.limit = 1000
                      q.include = "user"
                      q.skip = 1000
                    end.get

    @apps_total = @apps.length

    render layout: false
  end

  def notifications
    @notification = $client.object("Announcements")
    @notification["Description"] = notif_params["notification"]
    @notification["PushNotification"] = true
    @notification["Title"] = notif_params["notification-title"]
    notif_params["pinned"].blank? ? @notification["Pinned"] = false : @notification["Pinned"] = true;
    @notification.save
  end

  def internal_notifications
    @notification = $client.object("InternalAnnouncements")
    @notification["announcement"] = internal_notif_params["announcement"]
    @notification["role"] = internal_notif_params["role"]
    @notification.save
  end

  def generate_code
    @code = Digest::SHA1.hexdigest( (Time.now.to_f * 1000.0).to_i.to_s + ENV["HASH_CODE"] )

    code = $client.object("AppCode")
    code["code"] = @code
    code["used"] = false
    code.save
  end

  def email
    if cookies.signed[:spartaUser]
      if cookies.signed[:spartaUser][1] == "admin"
        @user = $client.query("_User").eq("objectId", cookies.signed[:spartaUser][0]).get.first
      else
        flash[:error] = "You're not an admin."
        redirect_to '/login' and return
      end
    else
      redirect_to '/login' and return
    end

    # Collects all the applications with their user object
    @apps = $client.query("Application").tap do |q|
                      q.limit = 1000
                      q.include = "user"
                    end.get

    @apps += $client.query("Application").tap do |q|
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
    email_flags = $client.query("EmailFlags").tap do |q|
                    q.limit = 1000
                    q.include = "user"
                  end.get

    email_flags += $client.query("EmailFlags").tap do |q|
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
          user_flags = $client.query("EmailFlags").tap do |q|
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
          user_flags = $client.query("EmailFlags").tap do |q|
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
      @applications = $client.query("Application").tap do |q|
        q.limit = 1000
        q.eq("emailStatus", nil)
        q.include = "user"
      end.get

      @applications += $client.query("Application").tap do |q|
        q.limit = 1000
        q.skip = 1000
        q.eq("emailStatus", nil)
        q.include = "user"
      end.get

      @email_count = 0
      @applications.each do |app|

        if app['status'] == "Accepted"
          UserMailer.notify_of_status(app["user"]["firstName"], app["user"]['email']).deliver_now
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

      email_flags = $client.query("EmailFlags").tap do |q|
                      q.limit = 1000
                      q.include = "user"
                    end.get

      email_flags += $client.query("EmailFlags").tap do |q|
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
            emailFlag = $client.object("EmailFlags")
            emailFlag["firstRsvpReminder"] = true
            emailFlag["user"] = empty_user.pointer
            emailFlag.save
            @email_count += 1
          elsif flagged_users.include? empty_user['email']
            user_flags = $client.query("EmailFlags").tap do |q|
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


      email_flags = $client.query("EmailFlags").tap do |q|
                      q.limit = 1000
                      q.eq("firstEmptyApp", true)
                      q.include = "user"
                    end.get

      email_flags += $client.query("EmailFlags").tap do |q|
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
            emailFlag = $client.object("EmailFlags")
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
            user_flags = $client.query("EmailFlags").tap do |q|
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
        user = $client.query("_User").eq("objectId", cookies.signed[:spartaUser][0]).get.first
      else
        flash[:error] = "You're not an admin."
        redirect_to '/login' and return
      end
    else
      redirect_to '/login' and return
    end

    # Used to populate Edit Sponsors section.
    @sponsors = []

    companies = $client.query("Company").get

    companies.each do |c|
        c["img"].url.slice! ":1337"
        @sponsors.push([c["objectId"], c["name"]])

        # saves a png version of svg else if png uses the png
        if c["png"].blank?
          if c['img'].url.include? ".svg"
            svg = open(c['img'].url) {|f| f.read }

            # creates a parse File using the private svg_to_png function
            photo = $client.file({
              :body => svg_to_png(svg),
              :local_filename => "logo.png",
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

    photo = $client.file({
      :body => logo.read,
      :local_filename => logo.original_filename,
      :content_type => logo.content_type,
      :content_length => logo.tempfile().size().to_s
    })
    photo.save

    company = $client.object("Company")
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
        user = $client.query("_User").eq("objectId", cookies.signed[:spartaUser][0]).get.first
      else
        flash[:error] = "You're not an admin."
        redirect_to '/login' and return
      end
    else
      redirect_to '/login' and return
    end

    # Populates form with sponsor info to be edited.
    object = view_sponsor_params['object']
    @sponsor = $client.query("Company").eq("objectId", object).get[0]
    @sponsor["img"].url.slice! ":1337"

    render layout: false
  end

  def editsponsor
    # Deletes or updates a sponsor

    company = $client.query("Company").eq("objectId", edit_sponsor_params['object']).get.first

    if edit_sponsor_params["commit"] == "Delete"
      company.parse_delete
    else

      if edit_sponsor_params["picture"]
        logo = edit_sponsor_params['picture']
        photo = $client.file({
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
        user = $client.query("_User").eq("objectId", cookies.signed[:spartaUser][0]).get.first
      else
        flash[:error] = "You're not an admin."
        redirect_to '/login' and return
      end
    else
      redirect_to '/login' and return
    end

    @apps = $client.query("Application").tap do |q|
      q.limit = 1000
      q.include = "user"
    end.get

    @apps += $client.query("Application").tap do |q|
      q.skip = 1000
      q.include = "user"
      q.limit = 1000
    end.get

    render layout: false
  end

  def rsvps
    if cookies.signed[:spartaUser]
      if cookies.signed[:spartaUser][1] == "admin"
        user = $client.query("_User").eq("objectId", cookies.signed[:spartaUser][0]).get.first
      else
        flash[:error] = "You're not an admin."
        redirect_to '/login' and return
      end
    else
      redirect_to '/login' and return
    end

    @rsvps = $client.query("RSVP").tap do |q|
      q.include = "user,application"
      q.limit = 1000
    end.get

    @rsvps += $client.query("RSVP").tap do |q|
      q.skip = 1000
      q.include = "user,application"
      q.limit = 1000
    end.get

    render layout: false
  end

  def app_status
      app = $client.query("Application").eq("objectId", status_params["object"]).get.first
      if !status_params["status-select"].blank?
        app['status'] = status_params["status-select"]
      else
        app['status'] = nil
      end
      app.save
  end

  def checkin
    if cookies.signed[:spartaUser]
      if cookies.signed[:spartaUser][1] == "admin" || cookies.signed[:spartaUser][1] == "volunteer"
        user = $client.query("_User").eq("objectId", cookies.signed[:spartaUser][0]).get.first
      else
        flash[:error] = "You're not an admin."
        redirect_to '/login' and return
      end
    else
      redirect_to '/login' and return
    end
    render layout: false
  end

  def checkin_search
    if !checkin_search_params[:barcode].blank?
      @attendance =  $client.query("Attendance").tap do |q|
        q.eq("user", Parse::Pointer.new({
          "className" => "_User",
          "objectId"  => checkin_search_params[:barcode]
        }))
      end.get.first

      if @attendance.blank?
        @user = $client.query("RSVP").tap do |q|
          q.eq("user", Parse::Pointer.new({
            "className" => "_User",
            "objectId"  => checkin_search_params[:barcode]
          }))
          q.include = "application,user"
        end.get.first

        curr_bday = Time.zone.local(@user['application']['birthyear'].to_i, Date::MONTHNAMES.index(@user['application']['birthmonth']), @user['application']['birthday'].to_i, 0, 0)
        if age(curr_bday, Date.new(2016, 2, 26)) < 18
          @minor = true
        else
          @minor = false
        end

      end

    elsif !checkin_search_params[:email].blank?
      @user_object = $client.query("_User").tap do |q|
        q.eq("email", checkin_search_params[:email])
      end.get.first

      if !@user_object.blank?
        @attendance =  $client.query("Attendance").tap do |q|
          q.eq("user", Parse::Pointer.new({
            "className" => "_User",
            "objectId"  => @user_object["objectId"]
          }))
        end.get.first

        if @attendance.blank?
          @user = $client.query("RSVP").tap do |q|
            q.eq("user", Parse::Pointer.new({
              "className" => "_User",
              "objectId"  => @user_object["objectId"]
            }))
            q.include = "application,user"
          end.get.first

          curr_bday = Time.zone.local(@user['application']['birthyear'].to_i, Date::MONTHNAMES.index(@user['application']['birthmonth']), @user['application']['birthday'].to_i, 0, 0)
          if age(curr_bday, Date.new(2016, 2, 26)) < 18
            @minor = true
          else
            @minor = false
          end
        end

      end

    end
  end

  def checkin_confirm
      @attendance =  $client.query("Attendance").tap do |q|
        q.eq("user", Parse::Pointer.new({
          "className" => "_User",
          "objectId"  => checkin_confirm_params[:user]
        }))
      end.get.first

      if @attendance.blank?
        @attendance = $client.object("Attendance")
        rsvp =  $client.query("RSVP").tap do |q|
                                q.eq("user", Parse::Pointer.new({
                                  "className" => "_User",
                                  "objectId"  => checkin_confirm_params[:user]
                                }))
                                q.include = "application, user"
                              end.get.first

        @attendance['rsvp'] = rsvp.pointer
        @attendance['user'] = rsvp["user"].pointer
        @attendance['application'] = rsvp["application"].pointer
        @attendance["onsiteRegistration"] = false
        @attendance.save

      end
  end

  def onsite
    if cookies.signed[:spartaUser]
      if cookies.signed[:spartaUser][1] == "admin" || cookies.signed[:spartaUser][1] == "volunteer"
        user = $client.query("_User").eq("objectId", cookies.signed[:spartaUser][0]).get.first
      else
        flash[:error] = "You're not an admin."
        redirect_to '/login' and return
      end
    else
      redirect_to '/login' and return
    end
    render layout: false
  end

  def onsite_search
    @email = onsite_search_params["email-search"]

    @user = $client.query("_User").tap do |q|
      q.eq("email", onsite_search_params["email-search"] )
    end.get.first

    if !@user.blank?
      @rsvp = $client.query("RSVP").tap do |q|
                q.eq("user", @user.pointer)
                q.include = "application"
              end.get.first
      if !@rsvp.blank?
        @attendance = $client.query("Attendance").tap do |q|
                  q.eq("user", @user.pointer)
                end.get.first
        if @attendance.blank?
          @attendance = $client.object("Attendance")
          @attendance['rsvp'] = @rsvp.pointer
          @attendance['user'] = @user.pointer
          @attendance['application'] = @rsvp["application"].pointer
          @attendance["onsiteRegistration"] = false
          @attendance.save
        else
          @attendance = false
        end
      else
        @application = $client.query("Application").tap do |q|
                  q.eq("user", @user.pointer)
                end.get.first
      end

    end
  end

  def onsite_submit
    if user_app_params['email'].blank? || user_app_params["firstName"].blank? || user_app_params["lastName"].blank? ||
      user_app_params["gender"].blank? || user_app_params["birthday"].blank? || user_app_params["birthmonth"].blank? ||
      user_app_params["birthyear"].blank? || user_app_params["universityStudent"].blank? || user_app_params["mlh"].blank?

      flash[:popup] = "You must fill in all the required fields."
      flash[:params] = user_app_params
      redirect_to '/admin/users/onsite-registration' and return
    elsif params.has_key?(:password) && params.has_key?(:password_confirmation) && user_app_params['password'] != user_app_params['password_confirmation']
      flash[:popup] = "Passwords do not match"
      flash[:params] = user_app_params
      redirect_to '/admin/users/onsite-registration' and return

    else
      if user_app_params['email'].downcase !~ /\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i
        flash[:popup] = "You must use a valid email."
        flash[:params] = user_app_params
        redirect_to '/admin/users/onsite-registration' and return
      end
      begin
        if params.has_key?(:password)
          apply = $client.user({
            :username => user_app_params['email'].downcase,
            :firstName => user_app_params["firstName"].capitalize,
            :lastName => user_app_params["lastName"].capitalize,
            :email => user_app_params['email'].downcase,
            :password => user_app_params['password'],
            :role => "attendee"
          })
          @user = apply.save
        else
          @user = $client.query("_User").tap do |q|
            q.eq("email", user_app_params['email'].downcase )
          end.get.first

          jdata = JSON.generate({"firstName" => user_app_params["firstName"].capitalize, "lastName" => user_app_params["lastName"].capitalize})
          RestClient.put 'https://api.parse.com/1/users/'+@user["objectId"],
            jdata,
            { :content_type => :json,
              "X-Parse-Application-Id" => ENV["PARSE_APP_ID"],
              "X-Parse-Master-Key" => ENV["PARSE_APP_M"]
            }
        end
      rescue Parse::ParseProtocolError => e
        if e.to_s.split(":").first == '202' || e.to_s.split(":").first == "203"
          flash[:popup] = "Email is taken"
          flash[:params] = user_app_params
          redirect_to '/admin/users/onsite-registration' and return
        else
          redirect_to "/outage" and return
        end

      end
    end

    begin
      fields = ["gender", "birthday", "birthmonth", "birthyear",
                                "major", "gradeLevel", "hackathons",
                                "github", "linkedIn", "website", "devPost",
                                "universityStudent", "mlh"]

      application = $client.query("Application").tap do |q|
                      q.eq("user", Parse::Pointer.new({
                        "className" => "_User",
                        "objectId"  => @user["objectId"]
                      }))
                    end.get.first
      if !application
        application = $client.object("Application")
      end

      fields.each do |field|
        if field == "universityStudent" && user_app_params["universityStudent"].to_bool == true
          application["universityStudent"] = "true"
          if user_app_params["otherUniversityConfirm"].to_bool == true
            application["otherUniversityConfirm"] = "true"
            application["otherUniversity"] = user_app_params["otherUniversity"]
            application["university"] = nil
          else
            application["otherUniversityConfirm"] = "false"
            application["university"] = user_app_params["university"]
            application["otherUniversity"] = nil
          end
        elsif field == "universityStudent" && user_app_params["universityStudent"].to_bool == false
          application["universityStudent"] = "false"
          application["otherUniversityConfirm"] = "false"
          application["university"] = nil
          application["otherUniversity"] = nil
        else
          application[field] = user_app_params[field]
        end

      end
      response = application.save

      application = $client.query("Application").eq("objectId", response["objectId"]).get.first
      application["user"] = @user.pointer
      application["exception"] = true
      application["status"] = "Accepted"
      application["emailStatus"] = true
      application.save

      @application = application

    rescue Parse::ParseProtocolError => e
      flash[:popup] =  e.message
      flash[:params] = user_app_params
      redirect_to "/outage" and return
    end

    begin
      fields = ["university", "restrictions", "otherRestrictions", "tshirt"]

      @rsvp = $client.query("RSVP").tap do |q|
                      q.eq("user", Parse::Pointer.new({
                        "className" => "_User",
                        "objectId"  => @user["objectId"]
                      }))
            end.get.first

      if !@rsvp
        @rsvp = $client.object("RSVP")
      end

      fields.each do |field|
        @rsvp[field] = user_app_params[field]
      end
      @rsvp['attending'] = true

      response = @rsvp.save

      @rsvp = $client.query("RSVP").eq("objectId", response["objectId"]).get.first
      @rsvp["user"] = @user.pointer

      if @rsvp["application"].blank?
        @rsvp["application"] = @application.pointer
      end

      @rsvp.save

      @attendance = $client.object("Attendance")
      @attendance['rsvp'] = @rsvp.pointer
      @attendance['user'] = @user.pointer
      @attendance['application'] = @application.pointer
      @attendance["onsiteRegistration"] = true
      @attendance.save


      curr_bday = Time.zone.local(@application['birthyear'].to_i, Date::MONTHNAMES.index(@application['birthmonth']), @application['birthday'].to_i, 0, 0)
      if age(curr_bday, Date.new(2016, 2, 26)) < 18
        flash[:popup] = "We've noticed you're a minor, there are a few things we need from you before we can let you in."
        flash[:sub] = ""
      else
        flash[:popup] = "Thanks for registering!"
        flash[:sub] = nil
      end

      redirect_to '/admin/users/onsite-registration' and return
    rescue Parse::ParseProtocolError => e
      flash[:error] =  e.message
      puts e.message
      redirect_to '/rsvp' and return
    end
  end

  def internal_register
    if cookies.signed[:spartaUser]
      if cookies.signed[:spartaUser][1] == "admin" || cookies.signed[:spartaUser][1] == "volunteer"
        user = $client.query("_User").eq("objectId", cookies.signed[:spartaUser][0]).get.first
      else
        flash[:error] = "You're not an admin."
        redirect_to '/login' and return
      end
    else
      redirect_to '/login' and return
    end
    @companies = $client.query("Company").get
    @companies.each do |c|
      c["img"].url.slice! ":1337"
    end

    @companies = @companies.sort do |a, b|
      a["name"].downcase <=> b["name"].downcase
    end

    render layout: false

  end

  def internal_register_submit
    if internal_register_params['email'].blank? || internal_register_params["firstName"].blank? || internal_register_params["lastName"].blank? ||
      internal_register_params["company"].blank? || internal_register_params["restrictions"].blank? || internal_register_params["phone"].blank?

      flash[:popup] = "You must fill in all the required fields."
      flash[:params] = internal_register_params
      redirect_to '/admin/internal/register' and return
    elsif params.has_key?(:password) && params.has_key?(:password_confirmation) && internal_register_params['password'] != internal_register_params['password_confirmation']
      flash[:popup] = "Passwords do not match"
      flash[:params] = internal_register_params
      redirect_to '/admin/internal/register' and return

    else
      if internal_register_params['email'].downcase !~ /\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i
        flash[:popup] = "You must use a valid email."
        flash[:params] = internal_register_params
        redirect_to '/admin/internal/register' and return
      end
      begin
        if params.has_key?(:password)
          if internal_register_params["company"] == "volunteer" || internal_register_params["company"] == "none"
            @role = "volunteer"
          else
            @role = "sponsor"
          end

          apply = $client.user({
            :username => internal_register_params['email'].downcase,
            :firstName => internal_register_params["firstName"].capitalize,
            :lastName => internal_register_params["lastName"].capitalize,
            :email => internal_register_params['email'].downcase,
            :password => internal_register_params['password'],
            :role => @role
          })
          @user = apply.save
        else
          @user = $client.query("_User").tap do |q|
            q.eq("email", internal_register_params['email'].downcase )
          end.get.first

          jdata = JSON.generate({"firstName" => internal_register_params["firstName"].capitalize, "lastName" => internal_register_params["lastName"].capitalize})
          RestClient.put 'https://api.parse.com/1/users/'+@user["objectId"],
            jdata,
            { :content_type => :json,
              "X-Parse-Application-Id" => ENV["PARSE_APP_ID"],
              "X-Parse-Master-Key" => ENV["PARSE_APP_M"]
            }
        end
      rescue Parse::ParseProtocolError => e
        if e.to_s.split(":").first == '202' || e.to_s.split(":").first == "203"
          flash[:popup] = "Email is taken"
          flash[:params] = internal_register_params
          redirect_to '/admin/internal/register' and return
        else
          redirect_to "/outage" and return
        end

      end
    end

    @internal = $client.object("InternalRegistrations")
    @internal["phone"] = internal_register_params["phone"]
    @internal["restrictions"] = internal_register_params["restrictions"]
    @internal["otherRestrictions"] = internal_register_params["otherRestrictions"]
    @internal["user"] = @user.pointer
    if internal_register_params["company"] != 'none' || internal_register_params["company"] != 'volunteer'
      company = $client.query("Company").tap do |q|
                              q.eq("objectId", internal_register_params["company"])
                            end.get.first
      if !company.blank?
        @internal["company"] = company.pointer
      end
    end


    @internal.save
    redirect_to '/admin/internal/register' and return
  end

  def judging_register
    if cookies.signed[:spartaUser]
      if cookies.signed[:spartaUser][1] == "admin" || cookies.signed[:spartaUser][1] == "volunteer"
        user = $client.query("_User").eq("objectId", cookies.signed[:spartaUser][0]).get.first
      else
        flash[:error] = "You're not an admin."
        redirect_to '/login' and return
      end
    else
      redirect_to '/login' and return
    end
    render layout: false
  end

  def judging_register_confirm
    if !judge_register_confirm_params[:barcode].blank?
      @judging =  $client.query("InternalRegistrations").tap do |q|
        q.eq("user", Parse::Pointer.new({
          "className" => "_User",
          "objectId"  => judge_register_confirm_params[:barcode]
        }))
      end.get.first

      if !@judging.blank?
        @judging["judge"] = true
        @judging.save
      else
        @internal = $client.object("InternalRegistrations")

        @user = $client.query("_User").eq("objectId", judge_register_confirm_params[:barcode]).get.first
        pp @user

        @internal["user"] = @user.pointer
        @internal["judging"] = true
        @internal.save
      end
    end
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

    def email_params
      params.permit(:object, :"type")
    end

    def notif_params
      params.permit(:"notification-title", :notification, :pinned)
    end

    def internal_notif_params
      params.permit(:"announcement", :role)
    end

    def checkin_search_params
      params.permit(:barcode, :email)
    end

    def checkin_confirm_params
      params.permit(:user)
    end

    def judge_register_confirm_params
      params.permit(:barcode)
    end


    def onsite_search_params
      params.permit(:"email-search")
    end

    def internal_register_params
      params.permit(:email, :password, :password_confirmation, :firstName, :lastName, :tshirt, :company,
                                  {:restrictions => []}, :otherRestrictions, :phone)
    end

    def user_app_params
      params.permit(:email, :password, :password_confirmation, :firstName, :lastName, :gender, :birthday,
                                  :birthmonth, :birthyear, :university, :otherUniversityConfirm,
                                  :otherUniversity, {:major => []}, :gradeLevel,
                                  {:hackathons => []}, :github, :linkedIn,
                                  :website, :devPost, :universityStudent, {:restrictions => []}, :otherRestrictions, :tshirt, :mlh)
    end

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

    def get_empty_app_users
      users_with_apps = []

      applications = $client.query("Application").tap do |q|
        q.limit = 1000
        q.include = "user"
      end.get

      applications += $client.query("Application").tap do |q|
        q.limit = 1000
        q.include = "user"
        q.skip = 1000
      end.get

      applications.each do |app|
        users_with_apps.push(app["user"]['email'])
      end

      users = $client.query("_User").tap do |q|
        q.value_not_in("email", users_with_apps)
        q.limit = 1000
      end.get

      users += $client.query("_User").tap do |q|
        q.value_not_in("email", users_with_apps)
        q.limit = 1000
        q.skip = 1000
      end.get
    end

    def get_empty_rsvp_acceptances
      users_with_rsvps = []

      rsvps = $client.query("RSVP").tap do |q|
        q.limit = 1000
        q.include = "user"
      end.get

      rsvps += $client.query("RSVP").tap do |q|
        q.limit = 1000
        q.include = "user"
        q.skip = 1000
      end.get

      rsvps.each do |rsvp|
        users_with_rsvps.push(rsvp["user"]['email'])
      end

      applications = $client.query("Application").tap do |q|
        q.limit = 1000
        q.include = "user"
      end.get

      applications += $client.query("Application").tap do |q|
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

    def age(dob,diq)
      diq = diq.to_date
      diq.year - dob.year - ((diq.month > dob.month || (diq.month == dob.month && diq.day >= dob.day)) ? 0 : 1)
    end

end
