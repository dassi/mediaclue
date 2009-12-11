require File.dirname(__FILE__) + '/../spec_helper'

describe MediaController, "POST 'update'" do
  
  before :each do
    logged_in_user
    permit_everything
    @medium = mock_medium(:id => 1)
    @medium.stub!(:tag_with)
    # @medium.stub!(:permit?).and_return(true)
    Medium.stub!(:find).and_return(@medium)
  end
  
  it "should redirect at success" do
    @medium.stub!(:update_attributes).and_return(true)
    post 'update', :media_set =>{ :media_attributes =>{ @medium.id => {} } }
    response.should be_redirect
    response.should redirect_to(medium_url(@medium))
  end

  it "should render :edit again if validation failed" do
    @medium.stub!(:update_attributes).and_return(false)
    post 'update', :media_set =>{ :media_attributes =>{ @medium.id => {} } }
    response.should_not be_redirect
    response.should render_template(:edit)
  end

end
