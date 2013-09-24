"use strict";

$(function() {
    if (typeof(window.getMapData) === "undefined") return;
    
    var canvas = $("canvas");
    var viewOnly = canvas.data("mode") !== "edit";
    var tempView = false;
	
	var colors = {
		edge: "#000",
		edgeHighlight: "#E00",
		nodeBackground: "#FFF",
		nodeBorder: "#000",
		nodeBackgroundHighlight: "#CCC",
		nodeBorderHighlight: "#F00",
		nodeText: "#000",
		background: "#E5E6E7"
	};

    var dragCursors = {
        mouseover: viewOnly ? "auto" : "move"
    };
    var addCursors = {
        mouseover: "auto"
    };

    var addEdge = {
        isAdding: false,
        isBidi: false,
        selectedBox: null
    };
    
    var hiesetSelected = [];

    var dragReset = {
        translateX: 0,
        translateY: 0,
        lastDragX: 0,
        lastDragY: 0
    };
    
    function createId() {
        var d = new Date().getTime();
        var uuid = 'xxxxxxx'.replace(/x/g, function (c) {
            var r = (d + Math.random() * 16) % 16 | 0;
            d = Math.floor(d / 16);
            return r.toString(16);
        });
        return uuid;
    }

    function min(a, b) {
        return a < b ? a : b;
    }
    
    function toggleHighlight(boxLayer, highlight) {
        if (highlight) {
            boxLayer.strokeStyle = colors.nodeBorderHighlight;
            boxLayer.fillStyle = colors.nodeBackgroundHighlight;
        } else {
            boxLayer.strokeStyle = colors.nodeBorder;
            boxLayer.fillStyle = colors.nodeBackground;
        }
    }

    function boxHover(boxLayer, textLayer, entering) {
        if (addEdge.isAdding) {
            toggleHighlight(boxLayer, entering);
            addEdge.selectedBox = entering ? textLayer : null;
        }
    }

    function calcVector(edge) {
        return {
            x: edge.x2 - edge.x1,
            y: edge.y2 - edge.y1
        };
    }

    function calcRotation(vector) {
        var goLeft = vector.x < 0;
        return (Math.atan(vector.y / vector.x) / Math.PI * 180) + (goLeft ? 270 : 90);
    }

    $.fn.extend({
        importJson: function (json) {
            var canvas = this;
            canvas.drawBackground();

            for (var i in json) {
                var node = json[i];
                canvas.drawTextBox(node.texto, node.x, node.y, node.nombre, node.db_id);
            }
            for (var i in json) {
                var node = json[i];
                for (var j in node.edgesTo) {
                    var edgeTo = node.edgesTo[j];
                    canvas.drawEdge(node.nombre, edgeTo.nombre, edgeTo.bidi, edgeTo.db_id);
                }
            }
        },

        exportChanges: function() {
            function extractEdges(graph) {
                return [].concat.apply([], graph.map(function(node) {
                    return node.edgesTo.map(function(edge) {
                        return {
                            bidi: edge.bidi,
                            desde: node.nombre,
                            hacia: edge.nombre,
                            desde_id: node.db_id,
                            hacia_id: edge.hacia_id,
                            db_id: edge.db_id
                        };
                    });
                }));
            }
            function sortStrings(a, b) {
                var firstCompare = a.desde.localeCompare(b.desde);
                if (firstCompare !== 0) return firstCompare;
                return a.hacia.localeCompare(b.hacia);
            }
            function sortInts(a, b) { return a.db_id - b.db_id; }
            function sortMixed(a, b) {
                var firstCompare = sortInts(a, b)
                if (firstCompare !== 0) return firstCompare;
                return sortStrings(a, b);
            }
            
            var canvas = this;
            
            var original = getMapData();
            var current = canvas.getLayers()
                .filter(function (layer) {
                    return layer.type === "text";
                })
                .map(function (layer) {
                    return {    
                        db_id: layer.data.db_id,
                        nombre: layer.name,
                        texto: layer.text,
                        x: layer.data.x,
                        y: layer.data.y,
                        edgesTo: layer.data.edges
                            .filter(function (edge) { return edge.data.nodeFrom.name === layer.name; })
                            .map(function (edge) {
                                return {
                                    nombre: edge.data.nodeTo.name,
                                    hacia_id: edge.data.nodeTo.data.db_id,
                                    bidi: edge.data.bidi,
                                    db_id: edge.data.db_id
                                };
                            })
                    }
                });
            
            var originalEdges = extractEdges(original);
            var currentEdges = extractEdges(current);
            
            var oldObjs = current.filter(function(node) { return node.db_id });
            var newObjs = current.filter(function(node) { return !node.db_id });
            
            var oldEdges = currentEdges.filter(function(node) { return node.db_id });
            var newEdges = currentEdges.filter(function(node) { return !node.db_id });
            
            var removedObjs = [];
            var changedObjs = [];
            var removedEdges = [];
            var changedEdges = [];
            
            originalEdges.sort(sortMixed);
            oldEdges.sort(sortMixed);
            oldObjs.sort(sortInts);
            
            function separateStuff(leftArray, rightArray, changed, removed, properties) {
                var i = 0, j = 0;
                var left = leftArray[i], right = rightArray[j];
                for (i, j; j < rightArray.length; left = leftArray[i], right = rightArray[j]) {
                    if (left.db_id === right.db_id) {
                        var hadChange = false;
                        var change = {
                            db_id: right.db_id
                        };
                        properties.forEach(function(prop) {
                            if (left[prop] !== right[prop]) {
                                change[prop] = right[prop];
                                hadChange = true;
                            }
                        });
                        if (hadChange) changed.push(change);
                        i++; j++;
                    } else if (left.db_id < right.db_id) {
                        removed.push(left);
                        i++;
                    }
                    /*left.db_id > right.db_id*/ // No es posible, ya que solo se pueden quitar nodos prenumerados.
                } while (j < rightArray.length);
                
                for (i; i < leftArray.length; i++) {
                    removed.push(leftArray[i]);
                }
            }
            
            separateStuff(original, oldObjs, changedObjs, removedObjs, ["texto", "x", "y"]);
            separateStuff(originalEdges, oldEdges, changedEdges, removedEdges, ["bidi", "desde_id", "hacia_id"]);
            
            return {
                nodes: { gone: removedObjs, changed: changedObjs, "new": newObjs },
                edges: { gone: removedEdges, changed: changedEdges, "new": newEdges }
            };
        },
        
        drawBackground: function() {
            var canvas = this;
            // BACKGROUND
            canvas.addLayer({
                fillStyle: colors.background,
                type: "rectangle",
                x: 0,
                y: 0,
                fromCenter: false,
                width: canvas.width(),
                height: canvas.height(),
                name: "background",
                draggable: !viewOnly,
                dragGroups: viewOnly ? undefined : ["draggables"],
                groups: ["draggables"],
                drag: viewOnly ? undefined : function (layer) {
                    dragReset.lastDragX = layer.x;
                    dragReset.lastDragY = layer.y;
                    layer.x = 0;
                    layer.y = 0;
                },
                dragstop: viewOnly ? undefined : function (layer) {
                    dragReset.translateX += dragReset.lastDragX;
                    dragReset.translateY += dragReset.lastDragY;
                },
                dblclick: viewOnly ? undefined : function (layer) {
                    var node = $("#newBoxTemplate")
                        .clone()
                        .attr("id", "createBox_" + createId())
                        .css("left", (layer.eventX - 28) + "px").css("top", (layer.eventY - 22) + "px")
                        .data({ x: layer.eventX - 5, y: layer.eventY - 12 })
                        .find("button.save")
                            .click(function() {
                                var box = $(this).parent();
                                var data = box.data();
                                canvas.drawTextBox(box.find("input").val(), data.x, data.y);
                                box.remove();
                                return false;
                            })
                        .end()
                        .find("button.cancel")
                            .click(function() {
                                $(this).parent().remove();
                                return false;
                            })
                        .end()
                        .find("input.text")
                            .keypress(function (e) {
                                if (e.keyCode === 13) $(this).siblings("button.save").click();
                            })
                        .end()
                        .appendTo("#canvasOverlay")
                        .find("input.text").focus();
                }
            }).drawLayers();
        },

        drawEdge: function (nodeFrom, nodeTo, bidirectional, db_id) {
            bidirectional = !!bidirectional;

            var canvas = this;
            if (typeof (nodeFrom) === "string") nodeFrom = canvas.getLayer(nodeFrom);
            if (typeof (nodeTo) === "string") nodeTo = canvas.getLayer(nodeTo);

            if (!nodeFrom.canvas || !nodeTo.canvas) {
                throw "ArgumentsError DrawEdge";
            }

            var layerId = "edge_" + nodeFrom.name + "_" + nodeTo.name;
            if (canvas.getLayer(layerId)) {
				console.log("Duplicate Edge " + layerId);
				return;
			}

            // EDGE
            canvas.addLayer({
                name: layerId,
                type: "line",
                strokeStyle: colors.edge,
                strokeWidth: 5,
                x1: nodeFrom.x,
                y1: nodeFrom.y + nodeFrom.height / 2,
                x2: nodeTo.x,
                y2: nodeTo.y + nodeTo.height / 2,
                index: min(nodeFrom.data.box.index, nodeTo.data.box.index),
                groups: ["graph_elements"],
                data: {
                    nodeFrom: nodeFrom,
                    nodeTo: nodeTo,
                    bidi: bidirectional,
                    db_id: db_id
                },
				dblclick: viewOnly ? undefined : function (layer) {
					var node = $("#editEdgeTemplate")
						.clone()
                        .attr("id", "editEdge_" + layer.name)
						.data("layerId", layer.name)
						.css("top", layer.eventY).css("left", layer.eventX)
						.find("button.cancel")
							.click(function() {
								layer.strokeStyle = colors.edge;
								if (layer.data.triangle) {
									layer.data.triangle.fillStyle = colors.edge;
								}
                                $(this).parent().remove();
                                return false;
							})
						.end()
						.find("button.swap")
							.click(function() {
                                var tx = layer.x1;
                                var ty = layer.y1;
                                var tnode = layer.data.nodeFrom;
                                layer.x1 = layer.x2;
                                layer.y1 = layer.y2;
                                layer.data.nodeFrom = layer.data.nodeTo;
                                layer.x2 = tx;
                                layer.y2 = ty;
                                layer.data.nodeTo = tnode;
                                
                                if (layer.data.triangle) {
                                    layer.data.triangle.rotate += 180;
                                }
                                canvas.drawLayers();
                                return false;
							})
						.end()
                        .find("button.changeType")
							.click(function() {
                                if (layer.data.bidi) {
                                    canvas.drawEdgeArrow(layer, true);
                                } else {
                                    canvas.removeLayer(layer.data.triangle.name);
                                    layer.data.triangle = undefined;
                                }
                                layer.data.bidi = !layer.data.bidi;
                                $(this).siblings("button.swap").toggle();
                                canvas.drawLayers();
                                return false;
							})
                        .end()
                        .find("button.delete")
                            .click(function() {
                                if (layer.data.triangle) {
                                    canvas.removeLayer(layer.data.triangle.name);
                                    layer.data.triangle = undefined;
                                }
                                
                                var edgesInFromNode = layer.data.nodeTo.data.edges;
                                var edgesInToNode = layer.data.nodeFrom.data.edges;
                                edgesInFromNode.splice(edgesInFromNode.indexOf(edge) , 1);
                                edgesInToNode.splice(edgesInToNode.indexOf(edge) , 1);
                                canvas.removeLayer(layer.name);
                                $(this).siblings("button.cancel").click();
                                return false;
                            })
                        .end()
						.appendTo("#canvasOverlay");
                    if (layer.data.bidi) {
                        node.find("button.swap").hide();
                    }
					layer.strokeStyle = colors.edgeHighlight;
					if (layer.data.triangle) {
						layer.data.triangle.fillStyle = colors.edgeHighlight;
					}
				}
            });

            var edge = canvas.getLayer(layerId);

            if (!bidirectional) canvas.drawEdgeArrow(edge, false);

            canvas.drawLayers();
            nodeFrom.data.edges.push(edge);
            nodeTo.data.edges.push(edge);
            return edge;
        },
        
        drawEdgeArrow: function(edge, selected) {
            var vector = calcVector(edge);
            var angle = calcRotation(vector);

            // EDGE TRIANGLE
            canvas.addLayer({
                type: "polygon",
                name: "triangle_" + edge.name,
                fillStyle: selected ? colors.edgeHighlight : colors.edge,
                x: edge.x1 + vector.x / 2,
                y: edge.y1 + vector.y / 2,
                radius: 10,
                sides: 3,
                rotate: angle,
                index: edge.index,
                groups: ["triangles"]
            });
            
            var triLayer = canvas.getLayer("triangle_" + edge.name);
            edge.data.triangle = triLayer;
        },

        drawTextBox: function (text, x, y, layerId, db_id, margin, fontSize, maxWidth) {
            if (!fontSize) fontSize = 14;
            if (!maxWidth) maxWidth = 150;
            if (!margin) margin = 10;
            if (!layerId) layerId = createId();
            if (typeof(x) === "string") x = parseInt(x);
            if (typeof(y) === "string") y = parseInt(y);
            if (!text || (x != 0 && !x) || (x != 0 && !x)) {
                throw "ArgumentsError";
            }
            var canvas = this;
            var half_margin = margin / 2;

            // TEXTBOX TEXT
            canvas.addLayer({
                type: "text",
                fillStyle: colors.nodeText,
                x: x + half_margin,
                y: y + half_margin,
                fromCenter: false,
                fontSize: fontSize,
                fontFamily: "Arial",
                text: text,
                layer: true,
                name: layerId,
                maxWidth: maxWidth,
                groups: ["textboxes", layerId + "_group", "graph_elements", "draggables"],
                draggable: !viewOnly,
                dragGroups: viewOnly ? undefined : [layerId + "_group"],
                drag: viewOnly ? undefined : function (layer) {
                    if (addEdge.isAdding) {
                        layer.x = layer.data.x + half_margin;
                        layer.y = layer.data.y + half_margin;
                        layer.data.box.x = layer.data.x - layer.data.box.width / 2 + half_margin * 3 / 2;
                        layer.data.box.y = layer.data.y;

                        var x1 = layer.x,
                            y1 = layer.y + layer.height / 2,
                            x2 = layer.eventX,
                            y2 = layer.eventY;
                        canvas.drawLine({
                            strokeStyle: colors.edge,
                            strokeWidth: 5,
                            rounded: true,
                            x1: x1,
                            y1: y1,
                            x2: x2,
                            y2: y2,
                            index: 0
                        });

                        if (!addEdge.isBidi) {
                            var vector = {
                                x: x2 - x1,
                                y: y2 - y1
                            };
                            var angle = calcRotation(vector);
                            canvas.drawPolygon({
                                fillStyle: colors.edge,
                                x: x1 + vector.x / 2,
                                y: y1 + vector.y / 2,
                                radius: 10,
                                sides: 3,
                                rotate: angle
                            });
                        }
                    } else {
                        var edges = layer.data.edges;
                        for (var i in edges) {
                            var edge = edges[i];
                            layer.data.x = layer.x - half_margin;
                            layer.data.y = layer.y - half_margin;
                            
                            var idx = edge.data.nodeFrom.name === layer.name ? "1" : "2";
                            edge["x" + idx] = layer.x;
                            edge["y" + idx] = layer.y + layer.height / 2;

                            var vector = calcVector(edge);
                            var angle = calcRotation(vector);

                            if (edge.data.triangle) {
                                edge.data.triangle.x = edge.x1 + vector.x / 2;
                                edge.data.triangle.y = edge.y1 + vector.y / 2;
                                edge.data.triangle.rotate = angle;
                            }
                        }
                    }
                },
                dragstop: viewOnly ? undefined : function (layer) {
                    if (addEdge.selectedBox !== null) {
                        canvas.drawEdge(layer, addEdge.selectedBox, addEdge.isBidi);
                    }
                },
                mouseover: viewOnly ? undefined : function (layer) {
                    boxHover(layer.data.box, layer, true);
                },
                mouseout: viewOnly ? undefined : function (layer) {
                    boxHover(layer.data.box, layer, false);
                },
                click: !viewOnly ? undefined : function(layer){
                    if (tempView) return;
                    
                    var lit = layer.data.lit = !layer.data.lit;
                    toggleHighlight(layer.data.box, lit);
                    var obj = { name: "ids[]", value: layer.data.db_id };
                    if (lit) {
                        hiesetSelected.push(obj);
                    } else {
                        var idx = -1;
                        for (var i in hiesetSelected) {
                            if (hiesetSelected[i].value === layer.data.db_id) {
                                idx = i;
                                break;
                            }
                        }
                        if (idx >= 0 && idx < hiesetSelected.length)
                            hiesetSelected.splice(idx, 1);
                    }
                    
                    var dataPanel = $("#rightPanel > div");
                    var loadingImg = $("#rightPanel img");
                    var template = $("#viewNodeTemplate");
                    dataPanel.hide();
                    loadingImg.show();
                    
                    $.get(template.data("url") + layer.data.db_id, "", function (data) {
                        loadingImg.hide();
                        
                        var infoPanel = template
                            .clone()
                            .attr("id", "infoPanel")
                            .find("span.central").text(data.central.score).end()
                            .find("span.tp_type").text(data.tp.type).end()
                            .find("span.tp_score").text(data.tp.index).end()
                            .find("a.explanations").data("json", data.explanation).end()
                            .find("a.consequences").data("json", data.consequence).end();
                        dataPanel.show()
                            .find("h2").text(layer.text).end()
                            .find("div").empty().end()
                            .append(infoPanel);
                    });
                    
                    
                },
				dblclick: viewOnly ? undefined : function (layer) {
					var node = $("#editBoxTemplate")
						.clone()
                        .attr("id", "editBox_" + layer.name)
						.data("layerId", layer.name)
						.css("top", layer.y - layer.height - 2).css("left", layer.x - layer.width / 2 - 15)
						.find("input.text")
							.width(layer.width + margin > 67 ? layer.width + margin : 67)
							.height(layer.height + half_margin)
							.val(layer.text)
						.end()
						.find("button.save")
							.click(function() {
								var box = $(this).parent();
								layer.text = box.find("input").val();
								canvas.drawLayers();
								var measure = canvas.measureText(layer);
								layer.data.box.width = measure.width + margin;
								layer.data.box.height = measure.height + margin;
								layer.data.box.x = layer.data.x - measure.width / 2 + margin / 4;
								layer.data.box.y = layer.data.y;
								box.remove();
                                return false;
							})
						.end()
						.find("button.delete")
							.click(function() {
								var box = $(this).parent();
								var layerId = box.data("layerId");
								var boxLayer = canvas.getLayer(layerId);
                                
								boxLayer.data.edges.forEach(function(edge) {
                                    if (edge.data.triangle) {
										canvas.removeLayer(edge.data.triangle.name);
                                        edge.data.triangle = undefined;
									}
                                    
                                    var edgesInOtherNode;
                                    if (edge.data.nodeFrom.name === boxLayer.name) {
                                        edgesInOtherNode = edge.data.nodeTo.data.edges;
                                    } else {
                                        edgesInOtherNode = edge.data.nodeFrom.data.edges;
                                    }
                                    edgesInOtherNode.splice(edgesInOtherNode.indexOf(edge) , 1);
									canvas.removeLayer(edge.name);
								});
								canvas
									.removeLayer(boxLayer.data.box.name)
									.removeLayer(layerId)
									.drawLayers();
								$(this).parent().remove();
                                return false;
							})
						.end()
						.find("button.cancel")
							.click(function() {
								$(this).parent().remove();
                                return false;
							})
						.end()
						.find("input.text")
							.keypress(function (e) {
								if (e.keyCode === 13) $(this).siblings("button.save").click();
							})
						.end()
						.appendTo("#canvasOverlay")
						.find("input.text")
							.focus();
				},
                cursors: dragCursors,
                data: {
                    x: x,
                    y: y,
                    db_id: db_id,
                    edges: [],
                    box: null
                }
            }).drawLayers();

            var textLayer = canvas.getLayer(layerId);
            var measure = canvas.measureText(textLayer);

            // TEXTBOX BOX
            canvas.addLayer({
                type: "rectangle",
                strokeStyle: colors.nodeBorder,
                strokeWidth: 1,
				cornerRadius: 5,
                fillStyle: colors.nodeBackground,
                x: x - measure.width / 2 + margin / 4,
                y: y,
                fromCenter: false,
                width: measure.width + margin,
                height: measure.height + margin,
                layer: true,
                index: 1,
                name: layerId + "_box",
                data: {
                    text: textLayer
                },
                groups: [layerId + "_group", "graph_elements", "draggables"],
                mouseover: viewOnly ? undefined : function (layer) {
                    boxHover(layer, layer.data.text, true);
                },
                mouseout: viewOnly ? undefined : function (layer) {
                    boxHover(layer, layer.data.text, false);
                },
            }).drawLayers();

            var boxLayer = canvas.getLayer(layerId + "_box");
            textLayer.data.box = boxLayer;
            return textLayer;
        }
    });

    /*$("#recenter").click(function() {
        if (dragReset.translateX != 0 || dragReset.translateY != 0) {
            canvas.setLayerGroup("graph_elements", {
                translateX: -dragReset.translateX,
                translateY: -dragReset.translateY
            }).drawLayers();
        }
    });*/

    if (viewOnly) {
        $("#map_calcs p a").click(function(e) {
            var me = $(this);
            var dataPanel = $("#rightPanel > div");
            var loadingImg = $("#rightPanel img");
            var type = me.data("type");
            
            var options;
            if (type === "central") {
                options = $("#map_calcs input").serialize();
            } else if (type === "hieset") {
                if (hiesetSelected.length < 1) return false;
                options = $.param(hiesetSelected);
            }
            
            loadingImg.show();
            dataPanel.hide();

            $.get(me.attr("href"), options, function(data) {
                loadingImg.hide();
                dataPanel.show().find("h2").text(me.data("title"));
                    
                var contents = "<div>";
                switch (data.type) {
                    case "indice":
                        contents += "<p>Índice: " + data.result.index.toFixed(2) + "</p><p>Tipo: " + data.result.type + "</p>";
                        break;
                    case "indice_int":
                        contents += "<p>Índice: " + data.result.index + "</p><p>Tipo: " + data.result.type + "</p>";
                        break;
                    case "central_array":
                        contents += "<div class='list'><ol>"
                        data.result.map(function(node) {
                            contents += "<li>" + node.texto + " (" + node.puntaje + ")</li>";
                        });
                        contents += "</ol></div>"
                        break;
                    case "chains_array":
                        contents += "<div class='list'><ul>"
                        data.result.forEach(function(chain) {
                            var head = chain[0];
                            contents += "<li><a href='#' class='chainLink' data-chain='" + JSON.stringify(chain) + "'>" + head.texto + "</a><ul>";
                            chain.slice(1).forEach(function(node) {
                                contents += "<li>" + node.texto + "</li>";
                            });
                            contents += "</ul></li>";
                        });
                        contents += "</ul>";
                        contents += "<p><a class='restoreLink' href='#' >Restaurar Mapa</a></p>";
                        contents += "</div>";
                        break;
                }
                contents += "</div>";
                dataPanel.find("div").remove();
                dataPanel.append(contents);
            });
            return false;
        });
        
        $("#rightPanel").on("click", "a.chainLink", function() {
            var me = $(this);
            tempView = true;
            hiesetSelected.length = 0;
            
            canvas.removeLayers();
            canvas.importJson(me.data("chain"));
            me.closest("div").find("a.restoreLink").show();
            return false;
        }).on("click", "a.graphLink", function() {
            var me = $(this);
            
            tempView = true;
            hiesetSelected.length = 0;
            
            canvas.removeLayers();
            canvas.importJson(me.data("json"));
            me.closest("div").find("a.restoreLink").show();
            return false;
        }).on("click", "a.restoreLink", function() {
            var me = $(this);
            tempView = false;
            
            canvas.removeLayers();
            canvas.importJson(getMapData());
            me.hide();
            return false;
        });
    } else {
        $("button.createEdge").click(function() {
            var btn = $(this);
            var isBidi = btn.data("bidi");

            if (addEdge.isAdding) {
                if (addEdge.isBidi !== isBidi) {
                    var otherBtn = btn.siblings("button.createEdge").first();
                    otherBtn.toggleClass("pressed");
                    addEdge.isBidi = isBidi;
                    addEdge.selectedBox = null;
                } else {
                    addEdge.isAdding = false;
                    addEdge.selectedBox = null;
                    canvas.setLayerGroup("textboxes", { cursors: dragCursors });
                    canvas.getLayer("background").draggable = true;
                }
            } else {
                addEdge.isAdding = true;
                addEdge.isBidi = isBidi;
                addEdge.selectedBox = null;
                canvas.setLayerGroup("textboxes", { cursors: addCursors });
                canvas.getLayer("background").draggable = false;
            }
            btn.toggleClass("pressed");
            return false;
        });
        
        $("form.edit_mapa").submit(function() {
            $("#json_content").val(JSON.stringify(canvas.exportChanges()));
            return true;
        });
    }
   
    canvas.importJson(getMapData());
});