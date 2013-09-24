require_relative './grafo'

class AnalisisController < ApplicationController
    def startup
        @map = Mapa.find(params[:mapa_id])
        @graph = CustomGraph.from_db(@map.nodos)
    end

	def tc
        startup
#        respond_to do |format|
            #format.json { render json: { graph: @graph.to_json_obj } }
            #format.json { render json: { result: @graph.causality_type } }
#        end
        tc = @graph.causality_type
        @map.indice_cog = tc[:index]
        @map.save
        render json: { result: tc, type: "indice" }
	end

	def tr
        startup
        tr = @graph.recursivity_type
        @map.indice_rec = tr[:index]
        @map.save
        render json: { result: tr, type: "indice_int" }
	end

	def tp
        startup
        node = Nodo.find(params[:id])
        render json: { result: @graph.central_type(node), type: "indice" }
	end

	def central
        startup
        max_levels = Integer(params[:niveles], 10) unless params[:niveles].blank?
        exact = params[:exacto].present? ? (params[:exacto] == "on" || params[:exacto] == "1") : false
        render json: { result: @graph.central(exact, max_levels), type: "central_array" }
	end

	def central_node
        startup
        max_levels = Integer(params[:niveles], 10) unless params[:niveles].blank?
        exact = params[:exacto].present? ? (params[:exacto] == "on" || params[:exacto] == "1") : false
        node = Nodo.find(params[:id])
        render json: { result: @graph.central_score(node, exact, max_levels), type: "central" }
	end

	def consecuencia
        startup
        node = Nodo.find(params[:id])
        render json: { result: @graph.consequences(node).to_json_obj, type: "chains" }
	end	

	def explicacion
        startup
        node = Nodo.find(params[:id])
        render json: { result: @graph.explanations(node).to_json_obj, type: "chains" }
	end	

	def hieset
        startup
        ids = params[:ids]
        nodes = Nodo.find(ids)
        render json: { result: @graph.hieset(nodes).map { |set| set.to_json_obj }, type: "chains_array" }
	end	
    
    def info
        startup
        node = Nodo.find(params[:id])
        max_levels = Integer(params[:niveles], 10) unless params[:niveles].blank?
        exact = params[:exacto].present? ? (params[:exacto] == "on" || params[:exacto] == "1") : false
        render json: { 
            tp: @graph.central_type(node), 
            central: @graph.central_score(node, exact, max_levels),
            consequence: @graph.consequences(node).to_json_obj,
            explanation: @graph.explanations(node).to_json_obj
        }
    end
end
