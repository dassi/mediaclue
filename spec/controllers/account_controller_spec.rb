require File.dirname(__FILE__) + '/../spec_helper'


describe AccountController, "GET login" do

  before :each do
    @user = mock_user(:id => 1)
    User.stub!(:authenticate).and_return(@user)
  end

  it "login should redirect to root-page" do
    post :login, :login => 'user_login', :password => 'user_password'
    response.should redirect_to(root_path)
    assigns[:current_user].should_not be_nil
    flash[:notice].should eql('Anmeldung erfolgreich.')
  end

end

describe AccountController, "GET logout" do
  
  integrate_views
  
  before :each do
    @user = mock_user(:id => 1)
    User.stub!(:authenticate).and_return(@user)
  end

  it "logout should redirect to root-page" do
    post :logout
    response.should redirect_to(:action => :login)
    @current_user.should be_nil
    # flash[:notice].should eql('Sie wurden abgemeldet.')
  end

end
