require 'spec_helper'

describe Spree::TaxRate, :type => :model do
  context "match" do
    let(:order) { create(:order) }
    let(:country) { create(:country) }
    let(:tax_category) { create(:tax_category) }
    let(:calculator) { Spree::Calculator::FlatRate.new }

    it "should return an empty array when tax_zone is nil" do
      allow(order).to receive_messages :tax_zone => nil
      expect(Spree::TaxRate.match(order.tax_zone)).to eq([])
    end

    context "when no rate zones match the tax zone" do
      before do
        Spree::TaxRate.create(:amount => 1, :zone => create(:zone))
      end

      context "when there is no default tax zone" do
        before do
          @zone = create(:zone, :name => "Country Zone", :default_tax => false, :zone_members => [])
          @zone.zone_members.create(:zoneable => country)
        end

        it "should return an empty array" do
          allow(order).to receive_messages :tax_zone => @zone
          expect(Spree::TaxRate.match(order.tax_zone)).to eq([])
        end

        it "should return the rate that matches the rate zone" do
          rate = Spree::TaxRate.create(
              :amount => 1,
              :zone => @zone,
              :tax_category => tax_category,
              :calculator => calculator
          )

          allow(order).to receive_messages :tax_zone => @zone
          expect(Spree::TaxRate.match(order.tax_zone)).to eq([rate])
        end

        it "should return all rates that match the rate zone" do
          rate1 = Spree::TaxRate.create(
              :amount => 1,
              :zone => @zone,
              :tax_category => tax_category,
              :calculator => calculator
          )

          rate2 = Spree::TaxRate.create(
              :amount => 2,
              :zone => @zone,
              :tax_category => tax_category,
              :calculator => Spree::Calculator::FlatRate.new
          )

          allow(order).to receive_messages :tax_zone => @zone
          expect(Spree::TaxRate.match(order.tax_zone)).to match_array([rate1, rate2])
        end

        it "should filter out rates that dont match the zip" do
          rate1 = Spree::TaxRate.create(
              :amount => 1,
              :zone => @zone,
              :tax_category => tax_category,
              :calculator => calculator,
              :zip_codes => '12345,34567,09876,34567'
          )

          rate2 = Spree::TaxRate.create(
              :amount => 2,
              :zone => @zone,
              :tax_category => tax_category,
              :calculator => Spree::Calculator::FlatRate.new
          )

          expect(Spree::TaxRate.filter_on_tax_rate_zip_if_applicable('88888',[rate1,rate2])).to match_array([rate2])
        end

        it "should NOT filter out rates that match the zip" do
          rate1 = Spree::TaxRate.create(
              :amount => 1,
              :zone => @zone,
              :tax_category => tax_category,
              :calculator => calculator,
              :zip_codes => '12345,34567,09876,34567'
          )

          rate2 = Spree::TaxRate.create(
              :amount => 2,
              :zone => @zone,
              :tax_category => tax_category,
              :calculator => Spree::Calculator::FlatRate.new
          )

          expect(Spree::TaxRate.filter_on_tax_rate_zip_if_applicable('34567',[rate1,rate2])).to match_array([rate1,rate2])
        end

        it "should return all rates that match the zone and the zip" do
          @myaddress = FactoryGirl.create(:address,:zipcode => '88888')
          @myorder = FactoryGirl.create(:order,:shipping_address => @myaddress)

          rate1 = Spree::TaxRate.create(
              :amount => 1,
              :zone => @zone,
              :tax_category => tax_category,
              :calculator => calculator,
              :zip_codes => '12345,34567,09876,34567'
          )

          rate2 = Spree::TaxRate.create(
              :amount => 2,
              :zone => @zone,
              :tax_category => tax_category,
              :calculator => Spree::Calculator::FlatRate.new
          )
          allow(@myorder).to receive_messages :tax_zone => @zone
          pre_filtered_rates = Spree::TaxRate.match(@myorder.tax_zone)
          expect(Spree::TaxRate.filter_on_tax_rate_zip_if_applicable(@myorder.tax_address.zipcode,pre_filtered_rates)).to match_array([rate2])

        end

        context "when the tax_zone is contained within a rate zone" do
          before do
            sub_zone = create(:zone, :name => "State Zone", :zone_members => [])
            sub_zone.zone_members.create(:zoneable => create(:state, :country => country))
            allow(order).to receive_messages :tax_zone => sub_zone
            @rate = Spree::TaxRate.create(
                :amount => 1,
                :zone => @zone,
                :tax_category => tax_category,
                :calculator => calculator
            )
          end

          it "should return the rate zone" do
            expect(Spree::TaxRate.match(order.tax_zone)).to eq([@rate])
          end
        end
      end

    end
  end
end
