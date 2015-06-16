Spree::TaxRate.class_eval do

  def self.match(order_tax_zone)
    puts "******* about to get caller *************"
    puts "caller for match: #{caller[0]}"
    puts "******* end getting caller *************"
    return [] unless order_tax_zone

    potential_rates = potential_rates_for_zone(order_tax_zone)
    rates = potential_rates.includes(zone: { zone_members: :zoneable }).load.select do |rate|
      # Why "potentially"?
      # Go see the documentation for that method.
      rate.potentially_applicable?(order_tax_zone)
    end

    # Imagine with me this scenario:
    # You are living in Spain and you have a store which ships to France.
    # Spain is therefore your default tax rate.
    # When you ship to Spain, you want the Spanish rate to apply.
    # When you ship to France, you want the French rate to apply.
    #
    # Normally, Spree would notice that you have two potentially applicable
    # tax rates for one particular item.
    # When you ship to Spain, only the Spanish one will apply.
    # When you ship to France, you'll see a Spanish refund AND a French tax.
    # This little bit of code at the end stops the Spanish refund from appearing.
    #
    # For further discussion, see #4397 and #4327.
    rates.delete_if do |rate|
      rate.included_in_price? &&
          (rates - [rate]).map(&:tax_category).include?(rate.tax_category)
    end
  end

  def self.adjust(order, items)
    puts "********************* HERE I AM *************************"
    puts "caller for adjust: #{caller[0]}"
    pre_filtered_rates = match(order.tax_zone)
    rates = filter_on_tax_rate_zip_if_applicable(order.tax_address.zipcode,pre_filtered_rates)
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
    #puts "submitted rates are: #{rates.inspect}"
    zip_filtered_rates = Array.new
    rates.each do |rate|
      #puts "examining rate: #{rate.inspect}"
      if rate.zip_codes.blank?
        zip_filtered_rates.push(rate)
      elsif does_zip_match?(order_zip,rate.zip_codes)
        zip_filtered_rates.push(rate)
      else
        #puts "we are skipping adding because the zip doesn't match"
      end
    end
    zip_filtered_rates
  end


  def self.does_zip_match?(order_zip,rate_zip_list)
    rate_zip_list.include? order_zip
  end

end