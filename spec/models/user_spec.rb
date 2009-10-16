require File.dirname(__FILE__) + '/../spec_helper'

describe User do
  before(:each) do
    @user = User.new
  end
  
  it "should be invalid without login" do
    @user.should_not be_valid
  end

  it "should be valid with login" do
    @user.login = 'test'
    @user.should be_valid
  end
  
  it "should return singleton instance of media_set with certain state" do
    media_set = @user.send(:singleton_media_set, :owning, 'own!')
    media_set.name.should be_blank
    media_set.caption.should eql('Meine Medien')
    media_set.state.should eql('owning')
  end

end
