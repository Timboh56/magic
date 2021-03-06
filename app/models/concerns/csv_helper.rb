module CSVHelper
  extend ActiveSupport::Concern

  class << self
    def hash_to_arr(hash)
      hash.map { |h| sanitize(h[1]) }
    end

    def sanitize(str)
      str.is_a?(String) ? str.gsub("\n", " ") : str
    end

    def collection_to_csv(collection, new_file = false, file_name = nil)
      if new_file
        file_name ||= collection.first.class.name.downcase + "_collection.csv"
        CSV.open(file_name, "wb") { |csv| generate_csv(csv, collection) }
      else
        CSV.generate { |csv| generate_csv(csv, collection) }
      end
    end

    def generate_csv(csv, collection)
      attributes = collection.first.class.attribute_names
      relational_model_names = collection.first.class.relations.collect { |r| r[1].name.to_s } rescue nil
      csv << attributes
      collection.each do |c|
        csv << attributes.inject([]) do |r,attribute|
          r += (val = c.send(attribute)) && val.is_a?(Hash) ? hash_to_arr(val) : [sanitize(val)]
          #r += relational_model_names.inject([]) { |arr, rel| arr += (rel_m = sanitize(c.send(rel))) && (rel_m.present?) ? rel_m.attributes.values : [] }
          r
        end
      end
    end
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
      end
    end
  end
end