require 'test_helper'

class EventRecordsControllerTest < ActionController::TestCase
  setup do
    @event_record = event_records(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:event_records)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create event_record" do
    assert_difference('EventRecord.count') do
      post :create, event_record: { description: @event_record.description, user_id: @event_record.user_id }
    end

    assert_redirected_to event_record_path(assigns(:event_record))
  end

  test "should show event_record" do
    get :show, id: @event_record
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @event_record
    assert_response :success
  end

  test "should update event_record" do
    patch :update, id: @event_record, event_record: { description: @event_record.description, user_id: @event_record.user_id }
    assert_redirected_to event_record_path(assigns(:event_record))
  end

  test "should destroy event_record" do
    assert_difference('EventRecord.count', -1) do
      delete :destroy, id: @event_record
    end

    assert_redirected_to event_records_path
  end
end
