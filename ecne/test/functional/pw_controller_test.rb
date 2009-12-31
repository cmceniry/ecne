require File.dirname(__FILE__) + '/../test_helper'
require 'pw_controller'

# Re-raise errors caught by the controller.
class PwController; def rescue_action(e) raise e end; end

class PwControllerTest < Test::Unit::TestCase
  def setup
    @controller = PwController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
