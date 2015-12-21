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

    # gender count [male, female, nonbinary]
    @gender_count = {"male"=>0, "female"=>0, "nonbinary"=>0, "total"=>0}

    # Hash of university => attendee count
    @uni_applicants = {"High School"=>0}

    # Gender
    @apps.each do |app|
      if !app['gender'].blank? && !@gender_count[app['gender']].blank?
        @gender_count[app['gender']]+=1;
        @gender_count["total"] +=1;
      end
    end



    #fills uni_applicants hash
    @apps.each do |app|
      if !app['university'].blank?
        if @uni_applicants[ app['university'] ]
          @uni_applicants[ app['university'] ] += 1
        else
          @uni_applicants[ app['university'] ] = 1
        end
      else
        @uni_applicants["High School"] += 1
      end
    end

    #creates an array of arrays sorted with highest value first. 
    @uni_applicants = @uni_applicants.sort_by {|_key, value| value}.reverse





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