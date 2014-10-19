class TwitterBlastsController < ApplicationController
	def create
		@twitter_blast = TwitterBlast.new(twitter_blast_params)
		@twitter_blast.save!

		@twitter_blast.blast
	end

	def new

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
	  	:user_handle, :status, :message, :messages_sent
	  )
	end
end