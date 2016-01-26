require 'rails_helper'

RSpec.describe ApiController, :type => :controller do

  describe "GET school" do
    it "returns http success" do
      get :school
      expect(response).to be_success
    end
  end

end
