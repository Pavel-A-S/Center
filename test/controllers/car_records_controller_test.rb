require 'test_helper'

class CarRecordsControllerTest < ActionController::TestCase
  setup do
    @car_record = car_records(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:car_records)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create car_record" do
    assert_difference('CarRecord.count') do
      post :create, car_record: { date: @car_record.date, date_of_issue: @car_record.date_of_issue, description: @car_record.description, document_description: @car_record.document_description, document_number: @car_record.document_number, document_type: @car_record.document_type, first_name: @car_record.first_name, initiator: @car_record.initiator, last_name: @car_record.last_name, middle_name: @car_record.middle_name }
    end

    assert_redirected_to car_record_path(assigns(:car_record))
  end

  test "should show car_record" do
    get :show, id: @car_record
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @car_record
    assert_response :success
  end

  test "should update car_record" do
    patch :update, id: @car_record, car_record: { date: @car_record.date, date_of_issue: @car_record.date_of_issue, description: @car_record.description, document_description: @car_record.document_description, document_number: @car_record.document_number, document_type: @car_record.document_type, first_name: @car_record.first_name, initiator: @car_record.initiator, last_name: @car_record.last_name, middle_name: @car_record.middle_name }
    assert_redirected_to car_record_path(assigns(:car_record))
  end

  test "should destroy car_record" do
    assert_difference('CarRecord.count', -1) do
      delete :destroy, id: @car_record
    end

    assert_redirected_to car_records_path
  end
end
