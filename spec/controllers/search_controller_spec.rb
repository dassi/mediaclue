require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SearchController do

  # integrate_views

  before :each do
    @current_user = logged_in_user
    @search_query = mock_search_query
    @current_user.stub!(:get_or_create_last_search_query).and_return(@search_query)
  end

  it "should redirect to search result media set, if found media" do
    non_empty_search_result = mock_search_result(:empty? => false, :search_query => @search_query)
    @search_query.should_receive(:execute).and_return(non_empty_search_result)

    post :result, :search_fulltext => 'something with hits', :media_types => {:images => '1', :audio_clips => '1', :video_clips => '1', :documents => '1'}
    response.should_not be_redirect
  end

  it "should stay on search page, if nothing found" do
    empty_search_result = mock_search_result(:empty? => true, :search_query => @search_query)
    @search_query.should_receive(:execute).and_return(empty_search_result)

    post :result, :search_fulltext => 'something with no hits', :media_types => {:images => '1', :audio_clips => '1', :video_clips => '1', :documents => '1'}
    response.should redirect_to(search_path)
  end

end
