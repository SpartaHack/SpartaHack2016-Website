class AdminController < ApplicationController
  require 'mailchimp'
  require 'parse_config'
  require 'monkey_patch'
  
  def admin
    if cookies.signed[:spartaUser]
      user = Parse::Query.new("_User").eq("objectId", cookies.signed[:spartaUser]).get.first
      if user['role'] != "admin"
        redirect_to '/login'
      end
    else
      redirect_to '/login'
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
    print photo.save

    company = Parse::Object.new("Company")
    company['name'] = add_sponsor_params['name']
    company['url'] = add_sponsor_params['url']
    company['img'] = photo
    company['level'] = add_sponsor_params['level']

    company.save

    redirect_to '/admin'

  end

  private

  def add_sponsor_params
    params.permit(:picture, :name, :url, :level)
  end   

end