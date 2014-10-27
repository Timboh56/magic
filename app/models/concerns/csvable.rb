module CSVable
  extend ActiveSupport::Concern

  included do
    helper_method :get_csv_data_row
    helper_method :get_csv_header_row
    helper_method :format_to_downloadable_csv
  end


  def get_csv_data_row record_set
    record_set.records.map { |r| r.text }
  end

  def get_csv_header_row parameters
    csv_row = []
    parameters.each do |parameter|
      csv_row.push parameter.name
    end
    csv_row
  end

  def format_to_downloadable_csv

    CSV.generate do |csv|

      if data_sets.present?
        data_sets.each do |data_set|

          # header
          csv << get_csv_header_row(data_set.parameters)

          # data
          data_set.record_sets.order("created_at ASC").each do |record_set|
            csv << get_csv_data_row(record_set)
          end
        end
      else


      end
    end
  end




end