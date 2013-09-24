require 'json'
class MapasController < ApplicationController

  def show
    @mapa = Mapa.find(params[:id])
    if @mapa.nodos then
        map = @mapa.nodos.includes(:arcos).map do |db_nodo|
            {
                nombre: db_nodo.nombre, texto: db_nodo.texto, db_id: db_nodo.id,
                x: db_nodo.x, y: db_nodo.y,
                edgesTo: db_nodo.arcos.map do |db_arco|
                    {
                        nombre: db_arco.hacia.nombre,
                        bidi: db_arco.bidi
                    }
                end
            }
        end
        
        @mapa_json = map.to_json
    end
  end
  
  def create
    @persona = Persona.find(params[:persona_id])
	@mapa = @persona.mapas.create(params[:mapa])
    redirect_to @mapa
  end
 
  def edit
	@mapa = Mapa.find(params[:id])
    if @mapa.nodos then
        map = @mapa.nodos.order("id asc").includes(:arcos).map do |db_nodo|
            {
                nombre: db_nodo.nombre, texto: db_nodo.texto, db_id: db_nodo.id,
                x: db_nodo.x, y: db_nodo.y,
                edgesTo: db_nodo.arcos.map do |db_arco|
                    {
                        nombre: db_arco.hacia.nombre,
                        bidi: db_arco.bidi,
                        db_id: db_arco.id,
                        hacia_id: db_arco.hacia.id
                    }
                end
            }
        end
        
        @mapa_json = map.to_json
    end
  end

  def update
	@mapa = Mapa.find(params[:id])
    json_changes = JSON.parse(params[:mapa_json])
    
    ActiveRecord::Base.transaction do
        Nodo.create(
            json_changes["nodes"]["new"].map { |json_nodo|
                { :nombre => json_nodo['nombre'], :texto => json_nodo['texto'], :x => json_nodo['x'], :y => json_nodo['y'], :mapa => @mapa }
            }
        )
        
        nodos = {}
        Arco.create(
            json_changes["edges"]["new"].map { |json_arco|
                hash = { :bidi => json_arco['bidi'] }
                if json_arco["desde_id"] then
                    hash[:desde_id] = json_arco["desde_id"]
                else
                    nombre = json_arco["desde"]
                    nodo = nodos[nombre] ? nodos[nombre] : Nodo.where(mapa_id: @mapa, nombre: nombre).first
                    hash[:desde] = nodo
                end
                if json_arco["hacia_id"] then
                    hash[:hacia_id] = json_arco["hacia_id"]
                else
                    nombre = json_arco["hacia"]
                    nodo = nodos[nombre] ? nodos[nombre] : Nodo.where(mapa_id: @mapa, nombre: nombre).first
                    hash[:hacia] = nodo
                end
                hash
            }
        )
        
        json_changes["nodes"]["changed"].each { |json_nodo|
            Nodo.update(json_nodo["db_id"], json_nodo.slice("texto", "x", "y"))
            
        }
        
        json_changes["edges"]["changed"].each { |json_arco|
            Arco.update(json_arco["db_id"], json_arco.slice("bidi", "desde_id", "hacia_id"))
            
        }
        
        Arco.delete_all(:id => json_changes["edges"]["gone"].map { |json_arco|
            json_arco["db_id"]
        })
        
        Nodo.delete_all(:id => json_changes["nodes"]["gone"].map { |json_nodo|
            json_nodo["db_id"]
        })
    end
    
    if @mapa.update_attributes(params[:mapa])
      redirect_to @mapa, :notice  => "Mapa actualizado exitosamente"
    else
      render :action => 'edit'
    end
  end

  def destroy
	@mapa = Mapa.find(params[:id])
    @mapa.destroy
    redirect_to @mapa
  end
end
