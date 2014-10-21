class TwitterBlastsController < ApplicationController
	before_action :check_current_user, only: [:create, :destroy, :update]

	def check_current_user
		if current_user.nil?
			raise "You must be signed into twitter!"
		end
	end

	def create
		@twitter_blast = TwitterBlast.new(twitter_blast_params)
		@twitter_blast.save!
		@twitter_blast.blast!(current_user)
	end

	def run
		@twitter_blast = TwitterBlast.find(params[:id])
		@twitter_blast.blast!(current_user)
	end

	def new

	end

	def edit
		@twitter_blast = TwitterBlast.find(params[:id])
	end

	def update
		@twitter_blast = TwitterBlast.find(params[:id])
		@twitter_blast.update_attributes!(params[:twitter_blast])
		redirect_to "/twitter_blaster"
	end

	def get_blasts
		@twitter_blasts = TwitterBlast.all.order("created_at DESC")
		render :partial => "recent_blasts_table"
	end

	def show
		@twitter_blast = TwitterBlast.find(params[:id])
	end

	def destroy
		TwitterBlast.find(params[:id]).destroy
    respond_to do |format|
      format.html { redirect_to "/twitter_blaster", notice: 'Your blast was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

	private

	# Never trust parameters from the scary internet, only allow the white list through.
	def twitter_blast_params
	  params.require(:twitter_blast).permit(
	  	:blast_type, :twitter_handles, :user_handle, :status, :message, :messages_sent
	  )
	end
end