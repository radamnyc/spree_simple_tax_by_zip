Spree::TaxRate.class_eval do

  def self.adjust(order, items)
    Rails.logger.debug "********************* HERE I AM *************************"
    Rails.logger.debug "caller for adjust: #{caller[0]}"
    Rails.logger.debug "submitted items are: #{items}"
    pre_filtered_rates = match(order.tax_zone)
    Rails.logger.debug "we have the rates: #{pre_filtered_rates.inspect}"
    rates = filter_on_tax_rate_zip_if_applicable(order.tax_address.zipcode,pre_filtered_rates)
    Rails.logger.debug "we have the FILTERED rates: #{rates.inspect}"
    tax_categories = rates.map(&:tax_category)
    relevant_items, non_relevant_items = items.partition { |item| tax_categories.include?(item.tax_category) }
    Spree::Adjustment.where(adjustable: relevant_items).tax.destroy_all # using destroy_all to ensure adjustment destroy callback fires.
    relevant_items.each do |item|
      relevant_rates = rates.select { |rate| rate.tax_category == item.tax_category }
      store_pre_tax_amount(item, relevant_rates)
      relevant_rates.each do |rate|
        rate.adjust(order, item)
      end
    end
    non_relevant_items.each do |item|
      if item.adjustments.tax.present?
        item.adjustments.tax.destroy_all # using destroy_all to ensure adjustment destroy callback fires.
        item.update_columns pre_tax_amount: 0
      end
    end
  end


  def self.filter_on_tax_rate_zip_if_applicable(order_zip,rates)
    Rails.logger.debug "submitted zipcode is: #{order_zip}"
    Rails.logger.debug "submitted rates are: #{rates.inspect}"
    zip_filtered_rates = Array.new
    rates.each do |rate|
      Rails.logger.debug "examining rate: #{rate.inspect}"
      if rate.zip_codes.blank?
        zip_filtered_rates.push(rate)
      elsif does_zip_match?(order_zip,rate.zip_codes)
        zip_filtered_rates.push(rate)
      else
        Rails.logger.debug "we are skipping adding because the zip doesn't match"
      end
    end
    zip_filtered_rates
  end


  def self.does_zip_match?(order_zip,rate_zip_list)
    rate_zip_list.include? order_zip
  end

end