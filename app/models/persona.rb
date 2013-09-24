class Persona < ActiveRecord::Base
  belongs_to :proyecto
  attr_accessible :cargo, :nombre, :rut, :proyecto
  has_many :mapas, :dependent => :destroy
end
