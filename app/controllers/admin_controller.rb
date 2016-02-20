class AdminController < ApplicationController
  require 'mailchimp'
  require 'parse_config'
  require 'monkey_patch'
  require 'open-uri'
  require 'digest/sha1'
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

  def notifications
    @notification = Parse::Object.new("Announcements")
    @notification["Description"] = notif_params["notification"]
    @notification["PushNotification"] = true
    @notification["Title"] = notif_params["notification-title"]
    notif_params["pinned"].blank? ? @notification["Pinned"] = false : @notification["Pinned"] = true;
    @notification.save
  end

  def internal_notifications
    @notification = Parse::Object.new("InternalAnnouncements")
    @notification["announcement"] = internal_notif_params["announcement"]
    @notification["role"] = internal_notif_params["role"]
    @notification.save
  end

  def generate_code
    @code = Digest::SHA1.hexdigest( (Time.now.to_f * 1000.0).to_i.to_s + ENV["HASH_CODE"] )

    code = Parse::Object.new("AppCode")
    code["code"] = @code
    code["used"] = false
    code.save

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

  def checkin
    render layout: false
  end

  def checkin_search
    if !checkin_search_params[:barcode].blank?
      @attendance =  Parse::Query.new("Attendance").tap do |q|
        q.eq("user", Parse::Pointer.new({
          "className" => "_User",
          "objectId"  => checkin_search_params[:barcode]
        }))
      end.get.first

      if @attendance.blank?
        @user = Parse::Query.new("RSVP").tap do |q|
          q.eq("user", Parse::Pointer.new({
            "className" => "_User",
            "objectId"  => checkin_search_params[:barcode]
          }))
          q.include = "application,user"
        end.get.first
      end



    elsif !checkin_search_params[:email].blank?
      @user_object = Parse::Query.new("_User").tap do |q|
        q.eq("email", checkin_search_params[:email])
      end.get.first

      if !@user_object.blank?
        @attendance =  Parse::Query.new("Attendance").tap do |q|
          q.eq("user", Parse::Pointer.new({
            "className" => "_User",
            "objectId"  => @user_object["objectId"]
          }))
        end.get.first

        if @attendance.blank?
          @user = Parse::Query.new("RSVP").tap do |q|
            q.eq("user", Parse::Pointer.new({
              "className" => "_User",
              "objectId"  => @user_object["objectId"]
            }))
            q.include = "application,user"
          end.get.first
        end

      end

    end

  end

  def checkin_confirm
      @attendance =  Parse::Query.new("Attendance").tap do |q|
        q.eq("user", Parse::Pointer.new({
          "className" => "_User",
          "objectId"  => checkin_confirm_params[:user]
        }))
      end.get.first

      if @attendance.blank?
        @attendance = Parse::Object.new("Attendance")
        rsvp =  Parse::Query.new("RSVP").tap do |q|
                                q.eq("user", Parse::Pointer.new({
                                  "className" => "_User",
                                  "objectId"  => checkin_confirm_params[:user]
                                }))
                                q.include = "application, user"
                              end.get.first

        @attendance['rsvp'] = rsvp.pointer
        @attendance['user'] = rsvp["user"].pointer
        @attendance['application'] = rsvp["application"].pointer
        @attendance.save

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

end
