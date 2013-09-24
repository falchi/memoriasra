require 'test_helper'

class ProyectosControllerTest < ActionController::TestCase
  def test_index
    get :index
    assert_template 'index'
  end

  def test_show
    get :show, :id => Proyecto.first
    assert_template 'show'
  end

  def test_new
    get :new
    assert_template 'new'
  end

  def test_create_invalid
    Proyecto.any_instance.stubs(:valid?).returns(false)
    post :create
    assert_template 'new'
  end

  def test_create_valid
    Proyecto.any_instance.stubs(:valid?).returns(true)
    post :create
    assert_redirected_to proyecto_url(assigns(:proyecto))
  end

  def test_edit
    get :edit, :id => Proyecto.first
    assert_template 'edit'
  end

  def test_update_invalid
    Proyecto.any_instance.stubs(:valid?).returns(false)
    put :update, :id => Proyecto.first
    assert_template 'edit'
  end

  def test_update_valid
    Proyecto.any_instance.stubs(:valid?).returns(true)
    put :update, :id => Proyecto.first
    assert_redirected_to proyecto_url(assigns(:proyecto))
  end

  def test_destroy
    proyecto = Proyecto.first
    delete :destroy, :id => proyecto
    assert_redirected_to proyectos_url
    assert !Proyecto.exists?(proyecto.id)
  end
end
