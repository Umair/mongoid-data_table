require 'spec_helper'

describe Mongoid::DataTable::Proxy do

  let(:controller) do
    Class.new(ActionController::Base).new.tap do |c|
      c.stubs(:params).returns({})
    end
  end

  describe "#new" do

    it "creates a new Mongoid::DataTable::Proxy object" do
      proxy = Mongoid::DataTable::Proxy.new(Person, controller)
      proxy.__metaclass__.superclass.should == Mongoid::DataTable::Proxy
    end

  end

  context "with default settings" do

    let(:proxy) do
      bob
      Mongoid::DataTable::Proxy.new(Person, controller)
    end

    let(:bob) do
      Person.find_or_create_by(:name => 'Bob')
    end

    let(:sam) do
      Person.find_or_initialize_by(:name => 'Sam')
    end

    describe "#collection" do

      it "should return WillPaginate::Collection" do
        proxy.collection.should be_a(WillPaginate::Collection)
      end

      it "should reload when passed true" do
        proxy.collection.should include(bob)
        proxy.collection.should_not include(sam)
        sam.save
        proxy.collection(true).should include(sam)
        sam.destroy
      end

    end

    describe "#current_page" do

      it "should default to 1" do
        proxy.current_page.should be(1)
      end

    end

    describe "#per_page" do

      it "should default to 10" do
        proxy.per_page.should be(10)
      end

    end

  end

end