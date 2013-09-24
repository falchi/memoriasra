class Mapa < ActiveRecord::Base
	attr_accessible :titulo, :indice_cog, :indice_rec, :persona
 	has_many :nodos, :dependent => :destroy
	belongs_to :persona
end
