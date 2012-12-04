[width,height] = [$ \#content .width!,680]

charge = (d) -> -1000 - ((d[\hover] || 0) && 8000)
color  = d3.scale.category20!
force  = null
svg    = null
gc1    = null
gc2    = null
custom-drag = null

clear = ->
  $ \svg .remove!
  force := d3.layout.force!
     .charge       charge
     .linkDistance 100
     .gravity      0.1
     .linkStrength 0.1
     .size         [width,height]
  svg := d3.select \#content .append \svg
     .attr \width width
     .attr \height height
  force.custom-drag = ->
    if !custom-drag
      custom-drag := d3.behavior.drag!.origin(-> it) .on \dragstart  -> it.fixed .|.=2
        .on \drag ->
          it.px = d3.event.x
          it.py = d3.event.y
          force.resume!
        .on \dragend   -> 
          if !playstate then force.stop!
          it.fixed .&.=1
    this.on \mouseover.force -> it.fixed .|.=4
      .on \mouseout.force -> it.fixed .&.=3
      .call custom-drag

tmp2d3 = ->
  position = {}
  for i til it.nodes.length
    position[it.nodes[i].id] = i
  
  nodes: [{
    id:       position[it.nodes[i].id]
    gid:      it.nodes[i].id
    name:     it.nodes[i].name
    group:    i
  } for i til it.nodes.length] 
  links: [{
    source:   position[it.links[i].src]
    target:   position[it.links[i].des]
    name:     it.links[i].name
    bidirect: it.links[i].bidirect
    value:  1
  } for i til it.links.length]

playstate = 1
@togglePlay = ->
  if !force then return
  playstate := 1-playstate
  if playstate 
    force.start!
    $ \#toggle-play .removeClass \active
  else
    force.stop!
    $ \#toggle-play .addClass \active

lockstate = 0
nodes = null
@toggleLock = ->
  if !force then return
  lockstate := 1 - lockstate
  if lockstate then $ \#toggle-lock .addClass \active
  else $ \#toggle-lock .removeClass \active
  nodes.each (d,i)->
    d.fixed = if lockstate then true
    else false
  nodes.selectAll \circle .attr \stroke if lockstate then \#f00 else \#999

gravitystate = 1
@toggle-gravity = (v) ->
  if !gc1 or !playstate then return
  $ "\#toggle-gravity li:nth-child(#{gravitystate})" .removeClass \active
  gravitystate := v
  $ "\#toggle-gravity li:nth-child(#{gravitystate})" .addClass \active
  switch v
  |1 => 
    gc1.transition! .duration 750
      .attr \r 3*height/4
    gc2.transition! .delay 100 .duration 750
      .attr \fill \#bec
      .attr \r height
    force.gravity 0.1 .start!
  |2 => 
    gc1.transition! .duration 750
      .attr \r 3*height/5
    gc2.transition! .delay 100 .duration 750
      .attr \fill \#cdb
      .attr \r 4*height/5
    force.gravity 0.2 .start!
  |3 => 
    gc1.transition! .duration 750
      .attr \r 2*height/5
    gc2.transition! .delay 100 .duration 750
      .attr \fill \#dca
      .attr \r 3*height/5
    force.gravity 0.4 .start!
  |4 =>
    gc1.transition! .duration 750
      .attr \r 3*height/10
    gc2.transition! .delay 100 .duration 750
      .attr \fill \#eaa
      .attr \r 2*height/5
    force.gravity 1.0 .start!
  | _ => force.gravity 1.5 .start!

generate = (error, graph) ->
  graph = tmp2d3 graph
  force.nodes graph.nodes
       .links graph.links .start!

  gc2 := svg.append \circle
      .attr \cx width/2
      .attr \cy height/2
      .attr \r  height
      .attr \fill \#bec

  gc1 := svg.append \circle
      .attr \cx width/2
      .attr \cy height/2
      .attr \r  3*height/4
      .attr \fill \#fff

  defs = svg.selectAll \defs .data graph.nodes .enter! .append \pattern
      .attr \id -> \defs_h + it.id
      .attr \patternUnits \userSpaceOnUse
      .attr \width 100
      .attr \height 100

  imgs = defs.append \image
      .attr \xlink:href -> \img/head/h +it.gid + \.png
      .attr \x 0
      .attr \y 0
      .attr \width 60
      .attr \height 60

  defs.append \marker
      .attr \id \arrow
      .attr \viewBox "-30 -5 10 10"
      .attr \markerWidth 20
      .attr \markerHeight 7
      .attr \fill \none
      .attr \stroke \#999
      .attr \stroke-width 1
      .attr \orient \auto
      .append \path
      .attr \d "M -30 -3 L -25 0 L -30 3"

  defs.append \marker
      .attr \id \arrow2
      .attr \viewBox "10 -5 30 10"
      .attr \markerWidth 20
      .attr \markerHeight 7
      .attr \fill \none
      .attr \stroke \#999
      .attr \stroke-width 1
      .attr \orient \auto
      .append \path
      .attr \d "M 30 -3 L 25 0 L 30 3"
  link = svg.selectAll \line.link .data graph.links .enter! .append \g

  nodes := svg.selectAll \circle.node .data graph.nodes .enter! .append \g
      .attr \x 100
      .attr \y 100

  oldnode = null
  circles = nodes.append \circle
      .attr \class \node
      .attr \cx 30
      .attr \cy 30
      .attr \r 30
      .attr \fill -> "url(\#defs_h#{it.id})"
      .attr \stroke \#999
      .attr \stroke-width \2.5px
      .on \mouseover -> 
        if oldnode==it then return
        if oldnode then oldnode.hover = 0
        it <<< hover: 1
        oldnode := it
        if playstate then force.start!
      #.on \mouseout -> it <<< hover: 0, fixed: false; force.start!
      .on \click -> 
        if it.fixed
          $ d3.event.target .attr \stroke \#999
          it.fixed = false
        else
          $ d3.event.target .attr \stroke \#f00
          it.fixed = true
      .call force.custom-drag 

  lines = link.append \line
      .attr \class \link
      .attr \marker-end 'url(#arrow)'
      .attr \marker-start -> if it.bidirect then 'url(#arrow2)'
      .style \stroke-width -> 2 #Math.sqrt it.value
  
  names = nodes.append \text
      .attr \width 200
      .attr \x 30
      .attr \y 70
      .attr \text-anchor \middle
      .text -> it.name
      .on \mousemover -> 
        if oldnode==it then return
        if oldnode then oldnode.hover = 0
        oldnode := it
        it <<< hover: 1
        if playstate then force.start!
      #.on \mouseout -> it <<< hover: 0, fixed: false; force.start!

  relations = link.append \text
      .attr \width 2000
      .attr \x 300
      .attr \y 100
      .attr \text-anchor \middle
      .attr \font-size 11
      .text -> it.name

  force.on \tick ->
    lines.attr \x1 -> it.source.x
      .attr \y1 -> it.source.y
      .attr \x2 -> it.target.x
      .attr \y2 -> it.target.y
    nodes.attr \transform -> "translate(#{it.x-30},#{it.y-30})"
    relations.attr \x -> 
      if it.bidirect
        (it.source.x + it.target.x)/2
      else 
        (2*it.source.x + it.target.x)/3
    .attr \y -> 
        if it.bidirect
          (it.source.y + it.target.y)/2
        else 
          (2*it.source.y + it.target.y)/3


d3.json \/names (error,graph) ->
  names = []
  names = [graph[x].name for x til graph.length]
  d3.select \select#name-chooser .selectAll \option .data names .enter! .append \option
      .attr \value -> it
      .text -> it
  $ \select#name-chooser .select2 do
    placeholder: "select a person"
    allowClear: true
    width: \200px
  $ \select#name-chooser .change ->
    clear!
    #d3.json "/ppllink/relation.json" generate
    d3.json "/query/#{$ \select#name-chooser .val!}/2" generate

$.fn.disableSelect = ->
  this.attr \unselectable \on
      .css \user-select \none
      .on \selectstart false

$ document .ready ->
  $ document .disableSelect!