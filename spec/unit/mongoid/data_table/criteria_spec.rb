require 'spec_helper'

describe Mongoid::DataTable::Criteria do

  before do
    Rails.stubs(:logger).returns(LOGGER)
  end

  let(:controller) do
    Class.new(ActionController::Base).new.tap do |c|
      c.stubs(:params).returns({})
    end
  end

  let(:custom_array) { %w(custom) }

  let(:custom_block) do
    lambda { |object| custom_array }
  end

  context "with custom block" do

    let(:bob) do
      Person.find_or_create_by(:name => 'Bob')
    end

    let(:dt) do
      bob
      Person.criteria.to_data_table(controller, {}, &custom_block)
    end

    it "should store it as an @extension" do
      dt.extension.should == custom_block
    end

    describe "#to_hash" do

      it "should run the custom block" do
        dt.to_hash[:aaData].first.should == custom_array
      end

      context "with inline block" do

        it "should run the inline block" do
          a = custom_array.push('inline')
          h = dt.to_hash { |object| a }
          h[:aaData].first.should == a
        end

      end

    end

  end

end