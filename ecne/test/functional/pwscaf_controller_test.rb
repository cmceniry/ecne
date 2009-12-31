require File.dirname(__FILE__) + '/../test_helper'
require 'pwscaf_controller'

# Re-raise errors caught by the controller.
class PwscafController; def rescue_action(e) raise e end; end

class PwscafControllerTest < Test::Unit::TestCase
  fixtures :passwords

  def setup
    @controller = PwscafController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @first_id = passwords(:first).id
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'
  end

  def test_list
    get :list

    assert_response :success
    assert_template 'list'

    assert_not_nil assigns(:passwords)
  end

  def test_show
    get :show, :id => @first_id

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:password)
    assert assigns(:password).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:password)
  end

  def test_create
    num_passwords = Password.count

    post :create, :password => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_passwords + 1, Password.count
  end

  def test_edit
    get :edit, :id => @first_id

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:password)
    assert assigns(:password).valid?
  end

  def test_update
    post :update, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => @first_id
  end

  def test_destroy
    assert_nothing_raised {
      Password.find(@first_id)
    }

    post :destroy, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      Password.find(@first_id)
    }
  end
end
