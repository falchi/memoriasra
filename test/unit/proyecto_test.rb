require 'test_helper'

class ProyectoTest < ActiveSupport::TestCase
  def test_should_be_valid
    assert Proyecto.new.valid?
  end
end
