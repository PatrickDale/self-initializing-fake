require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'json'
require 'open-uri'
require 'pry'

MOUNTEBANK_ENDPOINT = 'http://127.0.0.1:2525/imposters'
WIKIPEDIA_ENDPOINT = 'https://en.wikipedia.org/w/api.php?'
TEST_DOUBLE_ENDPOINT = 'http://localhost'
ACTIONS = Hash.new

get '/*' do
  action = params['splat'].first
  initialize_test_double action if !ACTIONS.key? action
  respond_with_test_double action
end

def initialize_test_double(action)
  test_double = new_fake_test_double action
  ACTIONS[action] = post_to_mountebank test_double
end

def new_fake_test_double(action)
  test_double_response = open(WIKIPEDIA_ENDPOINT + action).read

  mountebank_response = {
  'protocol' => 'http',
  'stubs' =>
  [
    {
    'responses' =>
    [
      {'is' =>
        {
          'headers' =>
          {
            'Content-Type' => 'application/json'
          },
          'body' => test_double_response
        }
      }
    ]
    }
  ]
  }
  
  mountebank_response.to_json
end

def post_to_mountebank(test_double)
  uri = URI(MOUNTEBANK_ENDPOINT)
  request = Net::HTTP::Post.new uri
  request.body = test_double

  response = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(request)
  end

  response.to_hash['location'].first.split('/').last
end

def respond_with_test_double(action)
  open(TEST_DOUBLE_ENDPOINT + ':' + ACTIONS[action] + "/" + action).read
end
