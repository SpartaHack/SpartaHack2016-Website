require 'rails_helper'

RSpec.describe JavascriptController, :type => :controller do

  describe "GET confirm" do
    it "returns http success" do
      get :confirm
      expect(response).to be_success
    end
  end

end
