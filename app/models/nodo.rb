class Nodo < ActiveRecord::Base
  attr_accessible :nombre, :texto, :x, :y, :mapa
  has_many :arcos, :foreign_key => 'desde_id', :class_name => "Arco", :dependent => :destroy
  has_many :arcos_entrantes, :foreign_key => 'hacia_id', :class_name => "Arco", :dependent => :destroy
  belongs_to :mapa
end
