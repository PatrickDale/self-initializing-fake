ENV['RACK_ENV'] = 'test'

require File.expand_path 'self_init_fake.rb'
require 'test/unit'
require 'rack/test'
require 'open-uri'
require 'yaml'
require 'pry'

class SelfInitFakeTest < Test::Unit::TestCase
  include Rack::Test::Methods

  WIKIPEDIA_ENDPOINT = 'https://en.wikipedia.org/w/api.php?'

  ACTIONS = YAML.load_file('api_actions.yml')['actions']

  def app
    Sinatra::Application
  end

  def test_all_api_actions
    ACTIONS.each do |action|
      get '/' + action
      assert last_response.ok?
      assert_equal open(WIKIPEDIA_ENDPOINT + action).read, last_response.body
    end
  end
end
