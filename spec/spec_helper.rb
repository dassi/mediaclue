# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] ||= 'test'
require File.dirname(__FILE__) + "/../config/environment" unless defined?(RAILS_ROOT)
require 'spec/autorun'
require 'spec/rails'
 
Spec::Runner.configure do |config|
  # If you're not using ActiveRecord you should remove these
  # lines, delete config/database.yml and disable :active_record
  # in your config/boot.rb
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
  config.fixture_path = RAILS_ROOT + '/spec/fixtures/'

  # == Fixtures
  #
  # You can declare fixtures for each example_group like this:
  #   describe "...." do
  #     fixtures :table_a, :table_b
  #
  # Alternatively, if you prefer to declare them only once, you can
  # do so right here. Just uncomment the next line and replace the fixture
  # names with your fixtures.
  #
  # config.global_fixtures = :table_a, :table_b
  #
  # If you declare global fixtures, be aware that they will be declared
  # for all of your examples, even those that don't use them.
  #
  # == Mock Framework
  #
  # RSpec uses it's own mocking framework by default. If you prefer to
  # use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
end

def permit_everything
    # controller.should_receive(:permit?).and_return(true)
    
    Medium.send(:define_method, :can_view?) do true; end
    Medium.send(:define_method, :can_edit?) do true; end
      
    MediaSet.send(:define_method, :can_view?) do true; end
    MediaSet.send(:define_method, :can_edit?) do true; end
      
end

def logged_in_user
    @current_user = mock_user
    @current_user.stub!(:is_owner_of?).and_return(:true)
    controller.stub!(:login_required).and_return(:true)
    controller.stub!(:current_user).and_return(@current_user)  
    User.should_receive(:find_by_id).any_number_of_times.and_return(@current_user)
    request.session[:user] = @current_user   
    request.session[:current_user] = @current_user
    
    @current_user
end

class RenderLayout
  def initialize(expected)
    @expected = 'layouts/' + expected
  end

  def matches?(controller)
    @actual = controller.layout
    @actual == @expected
  end

  def failure_message
    return "render_layout expected #{@expected.inspect}, got #{@actual.inspect}", @expected, @acutual
  end

  def negative_failure_message
    return "render_layout expected #{@expected.inspect} not to equal #{@actual.inspect}", @expected, @actual
  end
end

def render_layout(expected)
  RenderLayout.new(expected)
end

def mock_media_set(attributes = {})
  
  attributes.reverse_merge!(:media_set_memberships => [],
                            :media => [])
  
  mock = mock_model(MediaSet, attributes)
  mock
end

def mock_medium(attributes = {})

  attributes.reverse_merge!(:permit? => true)
  
  mock = mock_model(Medium, attributes)
  mock
end

def mock_search_query(attributes = {})
  attributes.reverse_merge!(:ferret_query => 'something to search',
                            :images? => true,
                            :video_clips? => true,
                            :audio_clips? => true,
                            :documents? => true,
                            :my_media_only? => false,
                            :name => 'Search query XY',
                            :media_type? => true,
                            :all_media_types? => true)
                            
  
  mock = mock_model(SearchQuery, attributes)
  
  mock.stub!(:ferret_query=)
  mock.stub!(:images=)
  mock.stub!(:audio_clips=)
  mock.stub!(:video_clips=)
  mock.stub!(:documents=)
  mock.stub!(:my_media_only=)
  mock.stub!(:save!)               
  mock.stub!(:execute).and_return(attributes[:search_result] || mock_search_result(:search_query => mock))
  
  mock
end

def mock_search_result(attributes = {})
  attributes.reverse_merge!(:empty? => false,
                            :media_set => mock_media_set,
                            :media => [],
                            :media_sets_and_media => {})
                            
  mock = mock_model(SearchResult, attributes)
  mock.stub!(:search_query).and_return(attributes[:search_query] || mock_search_query(:search_result => mock))
  
  mock
end
def mock_user(attributes = {})
  attributes.reverse_merge!(:get_or_create_last_search_query => mock_search_query,
                            :last_search_query => mock_search_query,
                            :search_queries => [],
                            :full_name => 'Ed Min',
                            :media_sets => [],
                            :media => [])
  
  mock = mock_model(User, attributes)
  
  mock.stub!(:can_edit?).and_return(true)
  mock.stub!(:can_view?).and_return(true)
  mock.stub!(:can_upload?).and_return(true)
  
  mock
end