class CraigCramsController < ApplicationController

  def index
    @cram_job = CraigCram.new
    @cram_jobs = CraigCram.all
  end

  def show
    @cram_job = CraigCram.find(params[:id])
  end

  def edit
    @cram_job = CraigCram.includes(:messages).find(params[:id])
  end

  def update
    @craig_cram = CraigCram.find(params[:id])
    create_or_update_emails
    @craig_cram.update_attributes!(craig_cram_params)
    redirect_to craig_crams_path
  end

  def create
    @craig_cram = CraigCram.new(craig_cram_params)
    create_or_update_emails
    @craig_cram.user_id = current_user.id
    @craig_cram.save!
    redirect_to @craig_cram
  end

  def create_or_update_emails
    if params[:craig_cram][:textarea_or_db] == "textarea"
      params[:emails].split("\n").each do |e|
        email_address = e.split(",")[0].strip
        email_pwd = e.split(",")[1].strip
        @craig_cram.emails = []

        unless (email = Email.where(email: email_address, password: email_pwd).first).present?
          email = Email.create!(craig_cram_id: params[:id] ,email: email_address, password: email_pwd)
        else
          email.craig_cram_id = params[:id]
          email.save!
        end
      end
      @craig_cram.save!
    end
  end

  def destroy
    CraigCram.find(params[:id]).destroy
    respond_to do |format|
      format.html { redirect_to "/craig_crammer", notice: 'Your cramjob was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  def craig_cram_params
    params.require(:craig_cram).permit(:ad_contact_name, 
      :ad_email_address, :ad_title, :ad_phone_number, 
      :category, :textarea_or_db, :posting_type, :cities_a_day, :ad_postal_code, :ad_street, :ad_city, :ad_region,
      :messages_attributes => [ :randomized_text, :title, :text, :id, :_id, :destroy, :_destroy],
      :emails_attributes => [ :email, :id, :_id, :destroy, :_destroy],
    )

  end
end