class PagesController < ActionController::Base
  def index
  end

	def sponsor
		prospectus = File.join(Rails.root, "lib/prospectus.pdf")
		#send_file(prospectus, :filename => "prospectus.pdf", :disposition => 'inline', :type => "application/pdf")
	end
end