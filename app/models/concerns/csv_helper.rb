module CSVHelper
  extend ActiveSupport::Concern

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

  def collection_to_csv(collection)
    CSV.generate do |csv|
      csv << collection.first.attributes.keys
      collection.each do |c|
        csv << c.attributes.values
      end
    end
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
      end
    end
  end




end