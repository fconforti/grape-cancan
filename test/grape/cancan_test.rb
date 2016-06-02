require 'minitest/autorun'
require 'rack/test'
require 'grape/cancan'
require 'cancancan'

Lockable = Class.new

class Ability
  include CanCan::Ability

  def initialize(lockable)
    can :read, Lockable
    cannot :love, Lockable
  end
end

class API < Grape::API
  authorize_routes!
  helpers { define_method(:current_lockable) { Lockable.new } }
  get('/can') { can? :love, current_lockable }
  get('/cannot') { cannot? :read, current_lockable }
  get('/authorize_option', authorize: [:read, Lockable])
  get('/authorize_option_fail', authorize: [:love, Lockable])
  get('/authorize_explicit') { authorize! :read, current_lockable }
  get('/authorize_explicit_fail') { authorize! :love, current_lockable }
end

class GrapeCancanTest < Minitest::Test
  include Rack::Test::Methods

  def app
    API
  end

  def test_can
    get '/can'
    assert_equal 'false', last_response.body
  end

  def test_cannot
    get '/cannot'
    assert_equal 'false', last_response.body
  end

  def test_authorize_option
    get '/authorize_option'
    assert_equal 200, last_response.status
  end

  def test_authorize_option_failure
    assert_raises CanCan::AccessDenied do
      get '/authorize_option_fail'
    end
  end

  def test_authorize_explicit
    get '/authorize_explicit'
    assert_equal 200, last_response.status
  end

  def test_authorize_explicit_failure
    assert_raises CanCan::AccessDenied do
      get '/authorize_explicit_fail'
    end
  end
end
