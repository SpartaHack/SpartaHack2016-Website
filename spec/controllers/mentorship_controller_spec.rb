require 'rails_helper'

RSpec.describe MentorshipController, :type => :controller do

  describe "GET register" do
    it "returns http success" do
      get :register
      expect(response).to be_success
    end
  end

end
