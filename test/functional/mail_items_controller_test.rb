require 'test_helper'

class MailItemsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:mail_items)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create mail_item" do
    assert_difference('MailItem.count') do
      post :create, :mail_item => { }
    end

    assert_redirected_to mail_item_path(assigns(:mail_item))
  end

  test "should show mail_item" do
    get :show, :id => mail_items(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => mail_items(:one).to_param
    assert_response :success
  end

  test "should update mail_item" do
    put :update, :id => mail_items(:one).to_param, :mail_item => { }
    assert_redirected_to mail_item_path(assigns(:mail_item))
  end

  test "should destroy mail_item" do
    assert_difference('MailItem.count', -1) do
      delete :destroy, :id => mail_items(:one).to_param
    end

    assert_redirected_to mail_items_path
  end
end
