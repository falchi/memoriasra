class Arco < ActiveRecord::Base
  attr_accessible :bidi, :desde, :hacia, :desde_id, :hacia_id
  belongs_to :desde, :class_name => "Nodo"
  belongs_to :hacia, :class_name => "Nodo"
end
