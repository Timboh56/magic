class ScrapesController < ApplicationController
  before_action :set_scrape, only: [:show, :edit, :update, :destroy]
  respond_to :html, :js, :csv

  # GET /scrapes
  # GET /scrapes.json
  def index
    @scrapes = Scrape.all
  end

  def run
    begin
      scrape = Scrape.find(params[:id])
      scrape.run
    rescue Exception => e
      @errors = "Error(s): " + e.message
      render :partial => "shared/errors", status: :unprocessable_entity
    end
  end

  def restart
    scrape = Scrape.find(params[:id])
    scrape.restart
  end

  # GET /scrapes/1
  # GET /scrapes/1.json
  def show
    begin
      scrape = Scrape.find(params[:id])
      puts "Scrape found"
      respond_to do |format|
        format.csv do
          send_data scrape.format_to_downloadable_csv
        end
        format.xls
        format.html
      end
    rescue Exception => e
      puts e.inspect
    end
  end

  # GET /scrapes/new
  def new
    @scrape = Scrape.new
  end

  # GET /scrapes/1/edit
  def edit
  end

  # POST /scrapes
  # POST /scrapes.json
  def create
    begin
      @scrape = Scrape.new(scrape_params)
      
      respond_to do |format|
        if @scrape.save!
          @scrape.run

          #format.csv { render text: @products.to_csv }
          #format.html { redirect_to @scrape, notice: 'Scrape was successfully created.' }
          format.json { render :show, status: :created, location: @scrape }
        else
          #format.html { render :new }
          format.json { render json: @scrape.errors, status: :unprocessable_entity }
        end
      end
    rescue Exception => e
      puts e.inspect
      @errors = "Error(s): " + e.message
      render :partial => "shared/errors", status: :unprocessable_entity
    end
  end

  # PATCH/PUT /scrapes/1
  # PATCH/PUT /scrapes/1.json
  def update
    respond_to do |format|
      if @scrape.update(scrape_params)
        format.html { redirect_to @scrape, notice: 'Scrape was successfully updated.' }
        format.json { render :show, status: :ok, location: @scrape }
      else
        format.html { render :edit }
        format.json { render json: @scrape.errors, status: :unprocessable_entity }
      end
    end
  end

  def get_scrapes_table_info
    @scrapes = Scrape.all
    render :partial => "scrapes/recent_scrapes_table"
  end

  def stop_all_scrapes
    Resque.workers.each {|w| w.unregister_worker}
    Scrape.all.each do |scrape|
      scrape.status = "Stopped"
      scrape.save!
    end
  end

  # DELETE /scrapes/1
  # DELETE /scrapes/1.json
  def destroy
    @scrape.destroy
    respond_to do |format|
      format.html { redirect_to "/scrape_ape", notice: 'Scrape was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_scrape
      @scrape = Scrape.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def scrape_params
      params.require(:scrape).permit(
        :URL, :page_parameterized_url, :page_interval, :filename, :next_selector, :use_proxies, :_destroy,
        :data_sets_attributes => [
          :link_selector, :_destroy, :parameters_attributes => [
            :name, :text_to_remove, :include_whitespace, :selector, :_destroy
          ]
        ]
      )
    end
end
