require File.dirname(__FILE__) + '/../spec_helper'

describe Tag, "validations" do

  it "should be invalid without" do
    tag = Tag.new
    tag.should_not be_valid
  end

  it "should be valid with name" do
    tag = Tag.new :name => 'test'
    tag.should be_valid
  end

  it "should evaluate tag_name_valid? correctly" do
    tag = Tag.new :name => 'test'
    tag.tag_name_valid?.should be_true
  end

  it "should only allow unique names" do
    tag = Tag.create :name => 'test'
    tag.should be_valid
    tag = Tag.create :name => 'Test'
    tag.should_not be_valid
  end

  it "should be valid with some special characters" do
    tag = Tag.new :name => 'azäöüèéàßçAZÄÖÜÈÉÀ09_-"'
    tag.should be_valid
  end

  it "should be invalid with some other special characters" do
    [',', ';', ':', '&', '%', '*', '+', '=', '?', '.'].each { |e|
      tag = Tag.new :name => e
      tag.should_not be_valid
    }
  end

end
