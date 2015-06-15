Spree::TaxRate.class_eval do

  def self.match(order_tax_zone)
    return [] unless order_tax_zone

    potential_rates = potential_rates_for_zone(order_tax_zone)
    rates = potential_rates.includes(zone: { zone_members: :zoneable }).load.select do |rate|
      rate.potentially_applicable?(order_tax_zone)
    end

    puts "********** HERE I AM *************"
    puts "order tax zone: #{order_tax_zone}"
    puts "rate: #{rates.inspect}"

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
    puts "********** HERE I AM *************"
    puts "rate: #{rates.inspect}"

  end

  def potentially_applicable?(order_tax_zone)
    # If the rate's zone matches the order's tax zone, then it's applicable.
    self.zone == order_tax_zone ||
        # If the rate's zone *contains* the order's tax zone, then it's applicable.
        self.zone.contains?(order_tax_zone) ||
        # 1) The rate's zone is the default zone, then it's always applicable.
        (self.included_in_price? && self.zone.default_tax)
  end




end