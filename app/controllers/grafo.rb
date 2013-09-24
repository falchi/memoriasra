require "rgl/adjacency"
require 'set'

class CustomGraph < RGL::DirectedAdjacencyGraph
    def initialize(edgelist_class=Set, *other_graphs)
        super
        @vertice_reverse = Hash.new
	end
    
    def initialize_copy(orig)
        super
		# Duplica la lista inversa igual como el original hace con la lista de vertices.
        @vertice_reverse = orig.instance_eval{@vertice_reverse}.dup
        @vertice_reverse.keys.each do |v|
            @vertice_reverse[v] = @vertice_reverse[v].dup
      end
    end

    def get_connected(v)
	# Todos los nodos conectados, ya sean entrantes o salientes.
        adjacency_list = @vertice_dict[v] or raise RGL::NoVertexError, "No vertex #{v}."
        reverse_list = @vertice_reverse[v] or raise RGL::NoVertexError, "No vertex #{v} in reverse."
	
        adjacency_list | reverse_list
    end

    def get_outgoing(v)
	# Los salientes.
        @vertice_dict[v] or raise RGL::NoVertexError, "No vertex #{v}."
    end

    def get_incoming(v)
	# Los entrantes.
        @vertice_reverse[v] or raise RGL::NoVertexError, "No vertex #{v} in reverse."
    end
    
    def each_connected(v, &b)
        self.get_connected(v).each(&b)
	end
    
    def each_incoming(v, &b)
        self.get_incoming(v).each(&b)
	end
    
    def add_vertex(v)
        super
        @vertice_reverse[v] ||= @edgelist_class.new
	end
    
    def remove_vertex(v)
        super
        @vertice_reverse.delete(v)
        @vertice_reverse.each_value { |adjList| adjList.delete(v) }
	end
    
    def remove_edge (u,v)
        super
        @vertice_reverse[v].delete(u) unless @vertice_dict[v].nil?
	end
    
    def basic_add_edge(u,v)
        super
        @vertice_reverse[v].add u
	end
    
    ### INFRASTRUCTURE
    ### CONVERSIONS
    
    #[
	#	{ nombre "jsoncaja1", texto: "Caja JSON 1", x: 350, y: 50, edgesTo: [
	#		{ nombre "jsoncaja2", bidi: false },
	#		{ nombre "precaja1", bidi: true }
	#	] },
	#	{ nombre "jsoncaja2", texto: "Caja JSON 2", x: 500, y: 150, edgesTo: [] }
	#]
	def to_json_obj
		self.map { |start_v| 
			{
				"edgesTo" => get_outgoing(start_v).map { |end_v|
					{
						"nombre" => end_v.nombre,
						"bidi" => get_incoming(start_v).include?(end_v)
					}
				},
				"nombre" => start_v.nombre,
				"texto" => start_v.texto,
				"x" => start_v.x,
				"y" => start_v.y,
			}
		}
	end
    
    def self.from_db(nodes)
        array = nodes.map { |node|
            node.arcos.map { |edge|
                if edge.bidi then
                    [edge.desde, edge.hacia, edge.hacia, edge.desde]
                else
                    [edge.desde, edge.hacia]
                end
            }
        }.flatten
        dg = self.from_edges(array)
        nodes.select { |node| node.arcos.length == 0 }.each { |node| dg.add_vertex(node) }
        dg
    end

    def self.from_edges(edge_array)
        result = new
        0.step(edge_array.size-1, 2) { |i| result.add_edge(edge_array[i], edge_array[i+1]) }
        result
    end
    
    def self.from_chains(chain_array, reverse = false)
        result = new
        chain_array.each { |chain| 
            if (chain.size == 1) then
                result.add_vertex(chain[0])
            else 
                (0..(chain.size-2)).each { |i| 
                    if reverse then
                        result.add_edge(chain[i+1], chain[i])
                    else
                        result.add_edge(chain[i], chain[i+1])
                    end
                }
            end
        }
        result
    end
	
	def self.from_json_obj(json_obj)
		edge_array = json_obj.map { |nodeFrom|
            
		}.flatten
        
        self.from_edges(edge_array)
	end

    ### CONVERSIONS
    ### DATA
    
    def orphan
	# Toma todos los vertices que no tengan nodos conectados (sus listas de adyacencias están vacias).
        self.reject { |v| @vertice_dict[v].length > 0 }
    end
    
    def loop
        self.cycles.reject{ |cycle| cycle.length < 3 }
    end

    private

    def dfs_travel(current, visited, vertice_list, stop_markers = [])
	# Los vertices a visitar: Todos los del nodo actual, excepto los ya visitados o los marcados como finales.
        vertices = vertice_list[current].reject { |v| visited.include?(v) || stop_markers.include?(v) }
		# Nodo actual como array.
        curr_arr = [current]

        if not vertices.empty? then 
		# Si tiene vertices, se visita cada uno, lo cual devolverá una lista de caminos, al que le pegamos el nodo actual para hacer los caminos.
            chains = vertices.map { |v|  dfs_travel(v, visited + curr_arr, vertice_list, stop_markers).map { |chain| curr_arr + chain } }.flatten(1)
        else
		# Si no hay vertices, entonces solo hay un camino.
            chains = [curr_arr]
        end
    
        chains
    end

    public
    
    def explanations(v)
	# Explicaciones: Los nodos que llegan hasta este nodo.
        chains = dfs_travel(v, [], @vertice_reverse)
        CustomGraph.from_chains(chains, true)
    end
    
    def consequences(v)
	# Consecuencias: Los nodos que salen de este nodo.
        chains = dfs_travel(v, [], @vertice_dict)
        CustomGraph.from_chains(chains, false)
    end

    def hieset(vertices)
	# El hieset son básicamente las explicaciones para cada vértice, deteniéndose si se topa con otro vértice del conjunto.
        vertices.map { |v|
            chains = dfs_travel(v, [], @vertice_reverse, vertices)
            CustomGraph.from_chains(chains, true)
        }
    end
	
    private

    def bfs_score(ancestors, truncate, current_level, current_count, max_level, visited)
    # Devuelve puntaje/nodos visitados.
		# No hay puntaje para el nivel si pasamos el nivel máximo.
        if current_level > max_level then return [0, current_count] end

		# Toma los vertices del nivel anterior, saca todos los nodos conectados sin visitar y elimina repetidos.
        level_vertices = ancestors.map { |v| self.get_connected(v).to_a }.flatten(1).reject { |v| visited.include?(v) }.uniq
		# Si no hay nodos en el nivel, el puntaje es cero.
        if level_vertices.empty? then return [0, current_count] end

		# Banxia por defecto trunca el puntaje total de cada nivel al hacer division de enteros. Por lo mismo, si queremos mantener precision hay
		# que covertir a float.
        if truncate then
            level_score = level_vertices.length / current_level
        else
            level_score = level_vertices.length.to_f / current_level
        end

		# Obtenemos el puntaje del siguiente nivel.
        descendants_score = bfs_score(level_vertices, truncate, current_level + 1, current_count + level_vertices.length, max_level, visited | level_vertices)
		# El puntaje total es el puntaje de este nivel mas todos los descendientes.
        [level_score + descendants_score[0], descendants_score[1]]
    end

    public

    def central_score(v, exact = false, max_level = 3)
	# Calcula el valor central para un nodo dado.
        max_level ||= 3
        score = bfs_score([v], !exact, 1, 0, max_level, [v])
        { score: score[0], visited: score[1] }
    end

    def central(exact = false, max_level = 3)
    # Calcula el valor central para todos los nodos y los entrega de mayor a menor.
        max_level ||= 3
        scores = {}
        self.map { |v|
            score = central_score(v, exact, max_level)
            { nombre: v.nombre, texto: v.texto, puntaje: score[:score], visitados: score[:visited] }
        }.sort_by { |v| v[:puntaje] }.reverse
    end

    def causality_index
		causal = 0
		asociativo = 0
		self.each { |start_v| 
			get_outgoing(start_v).each { |end_v|
				if get_incoming(start_v).include?(end_v)
					asociativo = asociativo + 0.5
				else
					causal = causal + 1
				end
			}
		}
		return causal / (causal + asociativo)
	end
	
	def causality_type
		index = self.causality_index
		if index > 0.85 and index <= 1 then
			type = "Causal Fuerte"
		elsif index > 0.65 and index <= 0.85
			type = "Causal Medio"
		elsif index >= 0.5 and index <= 0.65
			type = "Causal Debil"
		elsif index >= 0.35 and index < 0.5
			type = "Asociativo Debil"
		elsif index > 0.15 and index <= 0.35
			type = "Asociativo Medio"
		else index > 0 and index <= 0.15
			type = "Asociativo Fuerte"
        end
        { index: index, type: type }
	end
	
	def recursivity_type
		cycles = self.loop.length
		if cycles > 10 then
			type = "Recursivo Fuerte"
		elsif cycles > 5 and cycles <= 10
			type = "Recursivo Medio"
		else cycles > 0 and cycles <= 5
			type = "Recursivo Bajo"
        end
        { index: cycles, type: type }
	end
       
    def central_index(v)
        index = self.node_density(v) / self.edges.length.to_f
    end
    
    def central_type(v)
        index = self.central_index(v)
		if index > 0.85 and index <= 1 then
			type = "Convergente Fuerte"
		elsif index > 0.65 and index <= 0.85
			type = "Convergente Medio"
		elsif index >= 0.5 and index <= 0.65
			type = "Convergente Debil"
		elsif index >= 0.35 and index < 0.5
			type = "Divergente Debil"
		elsif index > 0.15 and index <= 0.35
			type = "Divergente Medio"
		else index > 0 and index <= 0.15
			type = "Divergente Fuerte"
        end
        { index: index, type: type }
    end
    
    def node_density(v, count_assoc = false)
        get_incoming(v).inject(0) { |links, inc_v|
            if count_assoc then
                links + 1
            elsif not get_outgoing(v).include?(inc_v)
                links + 1
            else
                links
            end
        }
    end
end