# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
proj = Proyecto.create({nombre: "Proyecto Test 1", descripcion: "asdf"})
person = Persona.create({nombre: "Milhouse", rut: "123456789", cargo: "Programmer", proyecto: proj})
map = Mapa.create({titulo: "Test Map 1", persona: person})
node1 = Nodo.create({ nombre: "testnode1", texto: "Nodo Test 1", x: 100, y: 100, mapa: map })
node2 = Nodo.create({ nombre: "testnode2", texto: "Nodo Test 2", x: 300, y: 100, mapa: map })
node3 = Nodo.create({ nombre: "testnode3", texto: "Nodo Test 3", x: 100, y: 300, mapa: map })
node4 = Nodo.create({ nombre: "testnode4", texto: "Nodo Test 4", x: 300, y: 300, mapa: map })
node5 = Nodo.create({ nombre: "testnode5", texto: "Nodo Test 5", x: 500, y: 100, mapa: map })
Arco.create({bidi: true, desde: node1, hacia: node2})
Arco.create({bidi: false, desde: node2, hacia: node3})
Arco.create({bidi: false, desde: node3, hacia: node1})
Arco.create({bidi: false, desde: node2, hacia: node5})