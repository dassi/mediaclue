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

describe MediaController, "GET 'index'" do

  integrate_views
  
  before :each do
    logged_in_user
    @current_user.stub!(:uploading_media_set).and_return(mock_media_set)
  end
  
  it "should be successful" do
    get :index
    response.should be_success
  end

  it "should render 'application' layout file" do
     get :index
     response.should render_layout('application')
  end
  
end

describe MediaController, "POST 'search'" do

  integrate_views
  
  before :each do
    @current_user = logged_in_user
    @medium = mock_medium(:id => 1)
    @current_user.stub!(:search_result_media_set).and_return(MediaSet.create)
    @current_user.stub!(:composing_media_set).and_return(MediaSet.create)
    @current_user.stub!(:uploading_media_set).and_return(MediaSet.create)
  end
  
  it "should redirect to search result media set, if found media" do
    Medium.should_receive(:find_with_ferret_for_user).and_return([@medium])
    MediaSet.should_receive(:find_media_with_ferret_for_user).and_return([@medium])
    assigns[:query] = mock_search_query
    search_result_media_set = mock_media_set
    @current_user.should_receive(:search_result_media_set).and_return(search_result_media_set)
    post :search, :search_fulltext => 'something with hits', :media_types => {:images => '1', :audio_clips => '1', :video_clips => '1', :documents => '1'}
    response.should redirect_to(media_set_path(search_result_media_set))
  end

  it "should stay on search page, if nothing found" do
    Medium.should_receive(:find_with_ferret_for_user).and_return([])
    MediaSet.should_receive(:find_media_with_ferret_for_user).and_return([])
    assigns[:query] = mock_search_query
    post :search, :search_fulltext => 'something with no hits', :media_types => {:images => '1', :audio_clips => '1', :video_clips => '1', :documents => '1'}
    response.should redirect_to(media_path)
  end

  # it "should render 'application' layout file" do
  #   Medium.stub!(:find_by_search_conditions_for_user).and_return(@medium)
  #   get :search, :search_fulltext => '', :search_tags => ''
  #   response.should render_layout('application')
  # end
  
end
