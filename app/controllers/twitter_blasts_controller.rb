class TwitterBlastsController < ApplicationController
  before_action :check_current_user, only: [:create, :destroy, :update]

  def index
    @twitter_blast = TwitterBlast.new

    if current_user.admin?
      @twitter_blasts = TwitterBlast.all
      @handle_lists = HandleList.all
    else
      @twitter_blasts = current_user.twitter_blasts
      @handle_lists = current_user.handle_lists
    end
  rescue Exception => e
    puts e.inspect
  end

  def create
    @twitter_blast = TwitterBlast.new(twitter_blast_params)
    @twitter_blast.user_id = current_user.id
    @twitter_blast.save!
    redirect_to @twitter_blast
  end

  def run
    begin
      @twitter_blast = TwitterBlast.find(params[:id])
      @twitter_blast.run
      render "create"
    rescue Exception => e
      puts e.inspect
      raise e
    end
  end

  def new
  end

  def edit
    @twitter_blast = TwitterBlast.find(params[:id])
    @handle_lists = HandleList.all
  end

  def update
    begin
      @twitter_blast = TwitterBlast.find(params[:id])
      @handle_lists = HandleList.all

      respond_to do |format|
        if @twitter_blast.update(twitter_blast_params)
          format.html { redirect_to @twitter_blast, notice: 'Successfully updated.' }
          format.json { render :show, status: :ok, scrape: @twitter_blast }
        else
          format.html { render :edit }
          format.json { render json: @twitter_blast.errors, status: :unprocessable_entity }
        end
      end
    rescue Exception => e
      p e.inspect
    end
  end

  def get_blasts
    @twitter_blasts = TwitterBlast.all.cache.order("created_at DESC")
    render :partial => "recent_blasts_table"
  end

  def get_handle_list
    @handle_list = HandleList.find(params[:id])
    render json: { name: @handle_list.name, handles: @handle_list.handles.take(50) } 
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
      :name, :user_id, :handles_type, :blast_type, :twitter_handles, :user_handle,
      :handle_list_id, :limit, :status, :message, :messages_sent,
      :messages_attributes => [ :text, :destroy, :_destroy, :id ]
    )
  end
end