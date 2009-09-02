require File.dirname(__FILE__) + '/../spec_helper'

describe MediaSet, "and create validations" do
  before(:each) do
    @media_set = MediaSet.new(:name => name)
  end

  it "should be valid without a subject tag" do
    @media_set.tag_names = 'bli, bla'
    @media_set.should be_valid
  end

  it "should be valid with a subject tag" do
    @media_set.tag_names = 'bli, Chemie, bla'
    @media_set.should be_valid
  end

  it "should be saveable without validation" do
    lambda{@media_set.save!}.should_not raise_error
  end
end

describe MediaSet, "and update validations" do
  before(:each) do
    @media_set = MediaSet.create!(:name => name)
    @media_set.collectables.stub!(:empty?).and_return(false)
    
  end

  it "should not be valid without a subject tag" do
    @media_set.tag_names = 'bli, bla'
    @media_set.should_not be_valid
  end

  it "should be valid with a subject tag" do
    @media_set.tag_names = 'bli, Chemie, bla'
    @media_set.should be_valid
  end

  it "should be not be updateable without validation" do
    lambda{@media_set.save!}.should raise_error
  end
end
