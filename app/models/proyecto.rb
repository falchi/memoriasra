class Proyecto < ActiveRecord::Base
  attr_accessible :nombre, :descripcion
  has_many :personas, :dependent => :destroy

  validates :nombre, :presence => true
end
