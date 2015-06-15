class AddZipCodesToSpreeTaxRates < ActiveRecord::Migration
  def change
    add_column :spree_tax_rates, :zip_codes, :string
  end
end
