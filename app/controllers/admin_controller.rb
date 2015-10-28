class AdminController < ApplicationController
  require 'mailchimp'
  require 'parse_config'
  require 'monkey_patch'

  def admin
    if cookies.signed[:spartaUser]
      user = Parse::Query.new("_User").eq("objectId", cookies.signed[:spartaUser]).get.first
      if user['role'] != "admin"
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

end