class CraigCramsController < ApplicationController

	def index
  	@cram_job = CraigCram.new
  	@cram_jobs = CraigCram.all
	end

	def show
		@cram_job = CraigCram.find(params[:id])
	end

	def edit
		@cram_job = CraigCram.find(params[:id])
	end

	def update
    @craig_cram = CraigCram.find(params[:id])
    @craig_cram.update_attributes(craig_cram_params)
    redirect_to craig_crams_path
	end


  def create
    @craig_cram = CraigCram.new(craig_cram_params)
    @craig_cram.user_id = current_user.id
    @craig_cram.save!
    redirect_to @craig_cram
  end

  private

  def craig_cram_params
  	params.require(:craig_cram).permit(:ad_contact_name, 
  		:ad_email_address, :ad_title, :ad_phone_number, 
  		:cities_a_day, :ad_postal_code, :ad_street, :ad_city, :ad_region,
  		:messages_attributes => [ :text, :id, :_id, :destroy, :_destroy],
  		:emails_attributes => [ :email, :id, :_id, :destroy, :_destroy],
  	)

  end
end