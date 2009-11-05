require File.dirname(__FILE__) + '/../spec_helper'

describe MediaSetsController, "GET 'update'" do

  integrate_views

  before :each do
    logged_in_user
    permit_everything
    @media_set = MediaSet.create
    MediaSet.stub!(:find).and_return(@media_set)
    @medium = Image.new
    @media_set.stub!(:media_for_user_as_owner).and_return([@medium])
    @medium.stub!(:public_filename).and_return('Bild1')
  end

  def do_update
    put 'update', :id => @media_set.id,
      :media_set => { :name => "meinset163", :tag_names => "qqqq", 
                      :desc => "asdlkfj2", 
                      # :media_attributes => { 
                      #   :1 => { 
                      #     :name => "Klassenfoto_GGS.jpg", 
                      #     :tag_names => '', 
                      #     :desc => ''}
                      # }
                    }
  end

  it "should redirect at success" do
    @media_set.stub!(:update_attributes).and_return(true)
    do_update
    response.should be_redirect
    response.should redirect_to(media_set_url(@media_set))
  end

  it "should render :edit again if validation failed" do
    @media_set.stub!(:update_attributes).and_return(false)
    @current_user.stub!(:uploading_media_set).and_return(mock_media_set)
    do_update
    response.should_not be_redirect
    response.should render_template(:edit)
  end

end

describe MediaSetsController, "GET 'index'" do

  integrate_views

  before :each do
    logged_in_user
    # permit_everything
    @media_set = MediaSet.create
    MediaSet.stub!(:find).and_return(@media_set)

    @current_user.stub!(:defined_media_sets).and_return([@media_set])
    @current_user.stub!(:media_sets_to_define).and_return([@media_set])

    @current_user.stub!(:owner_media_set).and_return(@media_set)
    @current_user.stub!(:search_result_media_set).and_return(@media_set)
    @current_user.stub!(:composing_media_set).and_return(@media_set)
    @current_user.stub!(:uploading_media_set).and_return(@media_set)
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

describe MediaSetsController, "GET 'edit'" do

  integrate_views

  before :each do
    logged_in_user
    permit_everything
    @media_set = MediaSet.create
    MediaSet.stub!(:find).and_return(@media_set)
    @current_user.stub!(:uploading_media_set).and_return(@media_set)
  end

  it "should be successful" do
    get :edit
    response.should be_success
  end

  it "should render 'application' layout file" do
    get :edit
    response.should render_layout('application')
  end
  
end


describe MediaSetsController, "GET 'show'" do

  integrate_views

  before :each do
    logged_in_user
    permit_everything
    @media_set = MediaSet.create
    MediaSet.stub!(:find).and_return(@media_set)
    @current_user.stub!(:composing_media_set).and_return(@media_set)
    @current_user.stub!(:uploading_media_set).and_return(@media_set)
  end

  it "should be successful" do
    get :show, :id => 4711
    response.should be_success
  end

  # Führt zu einer Deprecation-Warning von Rspec! Keine Ahnung warum!?
  # it "should render 'application' layout file" do
  #   get :show, :id => 4711
  #   response.should render_layout('application')
  # end
  
end

describe MediaSetsController, "parameter inheritance" do
  
  before(:each) do
    @params = { :media_set => { :source => "dummy", 
                                :media_attributes => { :'1' => { :source => nil, :permission_type => nil },
                                                       :'2' => { :source => nil, :permission_type => nil },
                                                     }
                              }
              }
    controller.params = @params
  end
  
  it "should replace source params on medias if nil" do
    @params[:media_set][:source] = "inherited value"
    inherited_params = controller.send(:inherit_media_params_from_media_set)
    inherited_params[:media_set][:media_attributes][:'1'][:source].should eql("inherited value")
    inherited_params[:media_set][:media_attributes][:'2'][:source].should eql("inherited value")
  end

  it "should replace undefined source params on medias" do
    @params[:media_set][:source] = "inherited value"
    @params[:media_set][:media_attributes][:'1'][:source] = ''
    @params[:media_set][:media_attributes][:'2'][:source] = ''
    inherited_params = controller.send(:inherit_media_params_from_media_set)
    inherited_params[:media_set][:media_attributes][:'1'][:source].should eql("inherited value")
    inherited_params[:media_set][:media_attributes][:'2'][:source].should eql("inherited value")
  end

  # it "should _NOT_ overwrite already defined source params on medias" do
  #   @params[:media_set][:source] = "inherited value"
  #   @params[:media_set][:media_attributes][:'1'][:source] = "old value 1"
  #   @params[:media_set][:media_attributes][:'2'][:source] = "old value 2"
  #   inherited_params = controller.send(:inherit_media_params_from_media_set)
  #   inherited_params[:media_set][:media_attributes][:'1'][:source].should eql("old value 1")
  #   inherited_params[:media_set][:media_attributes][:'2'][:source].should eql("old value 2")
  # end
  # 
  it "should overwrite already defined source params on medias" do
    @params[:media_set][:source] = "inherited value"
    @params[:media_set][:media_attributes][:'1'][:source] = "old value 1"
    @params[:media_set][:media_attributes][:'2'][:source] = "old value 2"
    inherited_params = controller.send(:inherit_media_params_from_media_set)
    inherited_params[:media_set][:media_attributes][:'1'][:source].should eql("inherited value")
    inherited_params[:media_set][:media_attributes][:'2'][:source].should eql("inherited value")
  end

  it "should replace permission_type params on medias if nil" do
    @params[:media_set][:permission_type] = "inherited value"
    inherited_params = controller.send(:inherit_media_params_from_media_set)
    inherited_params[:media_set][:media_attributes][:'1'][:permission_type].should eql("inherited value")
    inherited_params[:media_set][:media_attributes][:'2'][:permission_type].should eql("inherited value")
  end

  it "should replace undefined permission_type params on medias" do
    @params[:media_set][:permission_type] = "inherited value"
    @params[:media_set][:media_attributes][:'1'][:permission_type] = ''
    @params[:media_set][:media_attributes][:'2'][:permission_type] = ''
    inherited_params = controller.send(:inherit_media_params_from_media_set)
    inherited_params[:media_set][:media_attributes][:'1'][:permission_type].should eql("inherited value")
    inherited_params[:media_set][:media_attributes][:'2'][:permission_type].should eql("inherited value")
  end

  # it "should _NOT_ overwrite already defined viewers params on medias" do
  #   @params[:media_set][:viewers] = "inherited value"
  #   @params[:media_set][:media_attributes][:'1'][:viewers] = "old value 1"
  #   @params[:media_set][:media_attributes][:'2'][:viewers] = "old value 2"
  #   inherited_params = controller.send(:inherit_media_params_from_media_set)
  #   inherited_params[:media_set][:media_attributes][:'1'][:viewers].should eql("old value 1")
  #   inherited_params[:media_set][:media_attributes][:'2'][:viewers].should eql("old value 2")
  # end

  it "should overwrite already defined permission_type params on medias" do
    @params[:media_set][:permission_type] = "inherited value"
    @params[:media_set][:media_attributes][:'1'][:permission_type] = "old value 1"
    @params[:media_set][:media_attributes][:'2'][:permission_type] = "old value 2"
    inherited_params = controller.send(:inherit_media_params_from_media_set)
    inherited_params[:media_set][:media_attributes][:'1'][:permission_type].should eql("inherited value")
    inherited_params[:media_set][:media_attributes][:'2'][:permission_type].should eql("inherited value")
  end


  it "should replace read_permitted_user_group_ids params on medias if nil" do
    inherited_value = [1,2]
    @params[:media_set][:read_permitted_user_group_ids] = inherited_value
    inherited_params = controller.send(:inherit_media_params_from_media_set)
    inherited_params[:media_set][:media_attributes][:'1'][:read_permitted_user_group_ids].should eql(inherited_value)
    inherited_params[:media_set][:media_attributes][:'2'][:read_permitted_user_group_ids].should eql(inherited_value)
  end




  it "should inherit subject tags from media_set to medias, if option is set to 'subjects'" do
    tags_from_media_set =  'tags for, media_set; "Bildnerisches Gestalten" Chemie'
    @params[:media_set][:tag_names] = tags_from_media_set

    @params[:inherit_tags] = 'subjects'

    tags_for_media_one =  'tags for media one'
    tags_for_media_two =  'tags for media two'
    @params[:media_set][:media_attributes][:'1'][:tag_names] = tags_for_media_one
    @params[:media_set][:media_attributes][:'2'][:tag_names] = tags_for_media_two
    inherited_params = controller.send(:inherit_media_params_from_media_set)

    inherited_params[:media_set][:media_attributes][:'1'][:tag_names].should include(tags_for_media_one)
    inherited_params[:media_set][:media_attributes][:'1'][:tag_names].should include('Bildnerisches Gestalten')
    inherited_params[:media_set][:media_attributes][:'1'][:tag_names].should include('Chemie')
    inherited_params[:media_set][:media_attributes][:'2'][:tag_names].should include(tags_for_media_two)
    inherited_params[:media_set][:media_attributes][:'2'][:tag_names].should include('Bildnerisches Gestalten')
    inherited_params[:media_set][:media_attributes][:'2'][:tag_names].should include('Chemie')
  end

  it "should inherit all tags from media_set to medias, if option is set to 'all'" do
    tags_from_media_set =  'tags for, media_set; "Bildnerisches Gestalten" Chemie'
    @params[:media_set][:tag_names] = tags_from_media_set

    @params[:inherit_tags] = 'all'

    tags_for_media_one =  'tags for media one'
    tags_for_media_two =  'tags for media two'
    @params[:media_set][:media_attributes][:'1'][:tag_names] = tags_for_media_one
    @params[:media_set][:media_attributes][:'2'][:tag_names] = tags_for_media_two
    inherited_params = controller.send(:inherit_media_params_from_media_set)

    inherited_params[:media_set][:media_attributes][:'1'][:tag_names].should include(tags_for_media_one)
    inherited_params[:media_set][:media_attributes][:'1'][:tag_names].should include(tags_from_media_set)
    inherited_params[:media_set][:media_attributes][:'2'][:tag_names].should include(tags_for_media_two)
    inherited_params[:media_set][:media_attributes][:'2'][:tag_names].should include(tags_from_media_set)
  end

  it "should inherit no tags from media_set to medias, if option is set to 'none'" do
    tags_from_media_set =  'tags for, media_set; "Bildnerisches Gestalten" Chemie'
    @params[:media_set][:tag_names] = tags_from_media_set

    @params[:inherit_tags] = 'none'

    tags_for_media_one =  'tags for media one'
    tags_for_media_two =  'tags for media two'
    @params[:media_set][:media_attributes][:'1'][:tag_names] = tags_for_media_one
    @params[:media_set][:media_attributes][:'2'][:tag_names] = tags_for_media_two
    inherited_params = controller.send(:inherit_media_params_from_media_set)

    inherited_params[:media_set][:media_attributes][:'1'][:tag_names].should == tags_for_media_one
    inherited_params[:media_set][:media_attributes][:'2'][:tag_names].should == tags_for_media_two
  end

end