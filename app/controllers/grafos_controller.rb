class GrafosController < ApplicationController
	def insertar
		#result = '[{"nombre": "jsoncaja1", "texto": "Caja JSON 1", "x": 350, "y": "50", "edgesTo" : [{"hacia": "jsoncaja2", "bidi": "false"}, {"hacia": "precaja1", "bidi": "true"}]}, {"nombre": "jsoncaja2", "texto": "Caja JSON 2", "x": 500, "y": "150", "edgesTo" : []}]'
		result = URI::decode(params[:result])
		json_map = JSON.parse(result)

		query_mapa = Mapa.where(:titulo => params[:titulo])

		if not query_mapa
			mapa = Mapa.new(params[:titulo])
			mapa.save
			json_map.each do |json_nodo|
				nodo = Nodo.new(:nombre => json_nodo['nombre'], :texto => json_nodo['texto'], :x => json_nodo['x'], :y => json_nodo['y'])
				nodo.mapa = mapa
				nodo.save
				json_nodo['edgesTo'].each do |json_arco|
					arco = Arco.new(:hacia => json_arco['hacia'], :bidi => json_arco['bidi'])
					arco.nodo = nodo
					arco.save
				end
			end

			respond_to do |format|
		      format { render json: result }
		    end
		else
			respond_to do |format|
		    	  format { render json: "no permitido" }
			end
		end
	end

	def mostrar
		query_mapa = Mapa.where(:titulo => params[:titulo])

		if query_mapa
			db_mapa = query_mapa.first

			mapa = []
			db_mapa.nodos.each do |db_nodo|
				nodo = {:nombre => db_nodo.nombre, :texto => db_nodo.texto, :x =>db_nodo.x, :y => db_nodo.y}
				
				nodo['edgesTo'] = []
				db_nodo.arcos.each do |db_arco|
					arco = {:hacia => db_arco.hacia, :bidi => db_arco.bidi}
					nodo['edgesTo'].append(arco)
				end
				mapa.append(nodo)
			end

			respond_to do |format|
		    	  format { render json: mapa }
			end
		end
	end
end