extensions [nw]

; for interfacing with genlab: indicate what is inputs
to-report genlab-inputs
  report ["network-filename" "proportion-active" "proportion-promoters" "duration-seek" "duration-proactive"]
end


to-report result-A
  report (count turtles with [not unaware?] / count turtles)
end

to-report result-AK
  report count turtles with [(not unaware?) and (not ignorant?)] / count turtles
end

to-report genlab-outputs
  report ["result-AK" "result-A" ]
end

breed [nodes node]
undirected-link-breed [edges edge]

globals
[
  ticks-for-peak-A ;; the tick for the max of Awareness (was never higher later)
  last-max-peak-A
  ticks-for-peak-AK ;; the tick for the max of AK (was never higher later)
  last-max-peak-AK
  ticks-last-activity ; the last tick when something happened
]

turtles-own
[
  unaware?           ;; state on the awareness dimension: if true, the turtle is unaware
  seeking?           ;; state on the awareness dimension: if true, the turtle is seeking (aware and search for info)
  aware?             ;; state on the awareness dimension: if true, the turtle is aware (and not seeking)
  ignorant?          ;; state on the expertise dimension: if true, the turtle is ignorant
  proactive?         ;; state on the expertise dimension: if true, the turtle is knowledgeable and proactively passing the word
  knowledgeable?     ;; state on the expertise dimension: if true, the turtle is knowledgeable but passive

  ; characteristics which remain constant
  curious?            ;; if true, this individual would like to seek actively information
  enthusiastic?          ;; if true, thisindividual would ike to promote his knowledge
  supporter?

  time ; if > 0, the time to remain in this step
]

links-own
[
 cascade-awareness?
 cascade-expertise?
 chain-retrieval?

]


to setup-network-load
  ;; load the network from the file and also initialize their state
  show "loading network"
  show network-filename
  nw:load-gml network-filename nodes links
   [
    ; for visual reasons, we don't put any nodes *too* close to the edges
    setxy (random-xcor * 0.8) (random-ycor * 0.8)
    set size 1.5
    set unaware? true
    set seeking? false
    set aware? false
    set ignorant? true
    set proactive? false
    set knowledgeable? false
    set time 0
    ;set curious? random-float 1 < proportion-curious
    ;set enthusiastic? random-float 1 < proportion-enthusiastic
    ;set supporter? random-float 1 < proportion-supporters
    ;if (curious? or enthusiastic?) [ set shape "square" ]
    ;if (with-gui) [ set-color ]
  ]
   show "loaded links and turtles"
   show count edges
   show count turtles
   ;; also layout it for beauty purpose
   if (with-gui) [
     repeat 500 [layout-spring turtles links 0.1 4 4]
     ;layout-radial turtles links (turtle 0)

   ]
   ;repeat 5 [ layout-spring turtles links 0.8 (world-width / (sqrt count turtles)) 1 ]

end


to setup

  clear-all

  setup-network-load
  setup-nodes

  ; init the characteristics
  ask nodes [
    set curious? false
    set enthusiastic? false
    set supporter? false
  ]

  ask n-of (proportion-curious * count nodes) nodes [
    set curious? true
  ]
  ask n-of (proportion-enthusiastic * count nodes) nodes [
      set enthusiastic? true
  ]
  ask n-of (proportion-supporters * count nodes) nodes [
        set supporter? true
  ]

  ask nodes [
    set shape "circle"
    if curious? [ set shape "triangle" ]
    if enthusiastic? or supporter? [  set shape "square"]
    if curious? and (enthusiastic? or supporter?) [set shape "pentagon"]
      if (with-gui) [ set-color ]
  ]



  set ticks-for-peak-A 0
  set ticks-for-peak-AK 0
  set last-max-peak-A 0
  set last-max-peak-AK 0
  set ticks-last-activity 0

  ask n-of (initial-proportion-knowledgeable * count turtles) turtles [ become-knowledgeable ]

  ask links [
    set chain-retrieval? false
    set cascade-expertise? false
    set cascade-awareness? false
    set color gray
  ]

  reset-ticks
end

to setup-nodes
  if (with-gui) [ set-default-shape turtles "circle" ]

end


to go
  ; stopping condition
  if (
    ((ticks < advertisement-duration) and not (any? turtles with [ proactive? or seeking? or unaware?]))
    or
    ((ticks >= advertisement-duration) and not (any? turtles with [ proactive? or seeking?]))
    )
    [ stop ]



  ; change the state of agents which are in timeout
  manage-timeouts

  ; inform with advertisement
  if (ticks < advertisement-duration) [
    ask n-of (advertisement-proportion-per-step * count turtles) turtles [ receive-advertisement ]
  ]
  ; change from proactive to knowledage, or seeking to aware
  exchange-info

  ; detect outputs related to time
  update-ticks-detection

  ;spread-virus
  ;do-virus-checks
  tick
end

to update-ticks-detection
  let prop_A (count turtles with [aware?] / count turtles)
  if (prop_A > last-max-peak-A) [
    set ticks-for-peak-A ticks
    set last-max-peak-A prop_A
  ]

  let prop_AK (count turtles with [not unaware? and not ignorant?] / count turtles)
  if (prop_AK > last-max-peak-AK) [
    set ticks-for-peak-AK ticks
    set last-max-peak-AK prop_AK
  ]

  set ticks-last-activity max list ticks-for-peak-A ticks-for-peak-AK

end

to set-color
  if (with-gui) [
  if (unaware? and ignorant?) [ set color gray set label "UI"]
  if (unaware? and proactive?) [ set color orange  set label "UP"]
  if (unaware? and knowledgeable?) [ set color brown set label "UK"]

  if (seeking? and ignorant?) [ set color green set label "SI"]

  if (aware? and ignorant?) [ set color gray set label "AI"]
  if (aware? and proactive?) [ set color red set label "AP"]
  if (aware? and knowledgeable?) [ set color violet set label "AK"]


  ; these cases are errors
  if (seeking? and proactive?) [ set color green set label "!SP" print "illegal SP" print who]
  if (seeking? and knowledgeable?) [ set color green set label "!SK" print "illegal SK" print who]

  ]
end

to become-unaware ;; turtle procedure
  set unaware? true
  set seeking? false
  set aware? false
  set time 0
  set-color
end


to become-seeking  ;; turtle procedure
  if (unaware?) [
    set unaware? false
    set seeking? true
    set aware? false
    set time duration-seek
    set-color
  ]
end

to become-aware  ;; turtle procedure
  set unaware? false
  set seeking? false
  set aware? true
  set time 0
  set-color
end

to become-ignorant ;; turtle procedure
  set ignorant? true
  set proactive? false
  set knowledgeable? false
  set time 0
  set-color
end

to become-proactive ;; turtle procedure
  ;show "becoming proactive"
  set ignorant? false
  set proactive? true
  set knowledgeable? false
  set time duration-proactive
  if (seeking?) [ set seeking? false set aware? true ]
  set-color
end

to become-knowledgeable ;; turtle procedure
  set ignorant? false
  set proactive? false
  set knowledgeable? true
  set time 0
  if (seeking?) [ set seeking? false set aware? true ]
  set-color
end

to inform-someone
  ask one-of turtles [ become-proactive ]
end

to advertise-someone
  ask one-of turtles [ receive-advertisement ]
end

to receive-advertisement
  if unaware?
  [
    if (ignorant?) [
      ifelse (curious?) [ become-seeking] [ become-aware]
    ]
    if (knowledgeable?) [
      become-aware
      if (supporter?) [ become-proactive]
    ]
  ]
end

to receive-knowledge
  ;show "receive knowledge"
  if ignorant?
  [
   ;show "receive knowledge 2"
   ifelse enthusiastic? [ become-proactive ] [ become-knowledgeable ]
  ]
end

to manage-timeouts

  ask turtles with [time > 0 and (seeking? or proactive?)]
    [
      set time (time - 1)
    ]
  ask turtles with [proactive? and time = 0]
     [
      become-knowledgeable
     ]
  ask turtles with [seeking? and time = 0]
     [
      become-aware
     ]


end

; when agent a1 meets a2, then a2 will receive any piece of unknown information from a1
to-report exchange-info-agents [ a1 a2 ]
  let exchange false

  if ( (not [unaware?] of a1) and ([unaware?] of a2)) [
    ask a2 [receive-advertisement]
    set exchange true
  ]

  if ( (not [ignorant?] of a1) and ([ignorant?] of a2)) [
   ask a2 [receive-knowledge]
   set exchange true
  ]

  report exchange
end

to exchange-info

  ; by default, all the links are gray
  ;ask links [ set color gray ]

  ; drive a given number of links
  ask n-of (probability-link-meeting * count links)  links
  [

    ; so these links are at least active
    ; set color white

    if ( ( [seeking?] of end1 ) or ( [seeking?] of end2) or ( [proactive?] of end1 ) or ( [proactive?] of end2 )) [
     ; the interaction takes place

      let ignorant-before? [ignorant?] of end1 or [ignorant?] of end2
      let unaware-before? [unaware?] of end1 or [unaware?] of end2
      let seeking-before? [seeking?] of end1 or [seeking?] of end2

      let exchange12 (exchange-info-agents end1 end2)
      let exchange21 (exchange-info-agents end2 end1)

      if [not ignorant?] of end1 and [not ignorant?] of end2 and ignorant-before? [
       set cascade-expertise? true
       if seeking-before? [
         set chain-retrieval? true
       ]
      ]
      if [not unaware?] of end1 and [not unaware?] of end2 and unaware-before? [
       set cascade-awareness? true
      ]
      set color gray
      if chain-retrieval? [
          set color violet
          set thickness 0.4
      ]
      if color = gray and cascade-awareness? [
        set color green
        set thickness 0.4
      ]
      if color = gray and cascade-expertise? [
        set color orange
        set thickness 0.4
      ]

    ]

  ]

end

; Copyright 2016 Samuel Thiriot.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
677
10
2174
1528
50
50
14.732
1
10
1
1
1
0
0
0
1
-50
50
-50
50
1
1
1
ticks
30.0

BUTTON
26
165
121
205
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
136
165
231
205
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
27
327
648
551
diffusion
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Seeking" 1.0 0 -14439633 true "" "plot (count turtles with [seeking?] / count turtles)"
"Aware" 1.0 0 -4539718 true "" "plot (count turtles with [aware?] / count turtles)"
"AK" 1.0 0 -8630108 true "" "plot (count turtles with [(not unaware?) and (not ignorant?)] / count turtles)"
"Proactive" 1.0 0 -955883 true "" "plot (count turtles with [proactive?] / count turtles)"

BUTTON
137
217
231
256
step
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
242
247
546
280
probability-link-meeting
probability-link-meeting
0
1
1
0.01
1
NIL
HORIZONTAL

SLIDER
437
13
609
46
duration-seek
duration-seek
0
100
5
1
1
NIL
HORIZONTAL

SLIDER
437
55
609
88
duration-proactive
duration-proactive
0
100
6
1
1
NIL
HORIZONTAL

SLIDER
242
207
549
240
advertisement-proportion-per-step
advertisement-proportion-per-step
0
1
0.1
0.01
1
NIL
HORIZONTAL

SLIDER
242
164
547
197
initial-proportion-knowledgeable
initial-proportion-knowledgeable
0
1
0.1
0.01
1
NIL
HORIZONTAL

PLOT
36
578
647
728
interactions
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"active" 1.0 0 -16777216 true "" "plot (count links with [color = white] / count links)"
"used" 1.0 0 -955883 true "" "plot (count links with [color = orange] / count links)"

SLIDER
241
13
436
46
proportion-curious
proportion-curious
0
1
0.1
0.01
1
NIL
HORIZONTAL

SLIDER
241
54
435
87
proportion-enthusiastic
proportion-enthusiastic
0
1
0.11
0.01
1
NIL
HORIZONTAL

INPUTBOX
24
11
231
87
network-filename
ws1000_network.txt
1
0
String

SWITCH
694
326
806
359
with-gui
with-gui
0
1
-1000

MONITOR
557
174
653
219
NIL
count turtles
17
1
11

MONITOR
559
231
653
276
NIL
count links
17
1
11

SLIDER
248
290
474
323
advertisement-duration
advertisement-duration
0
50
10
1
1
NIL
HORIZONTAL

MONITOR
28
274
86
319
peak A
ticks-for-peak-A
17
1
11

MONITOR
98
273
155
318
peak AK
ticks-for-peak-AK
17
1
11

MONITOR
170
274
227
319
NIL
ticks-last-activity
17
1
11

SLIDER
241
103
458
136
proportion-supporters
proportion-supporters
0
1
0
0.01
1
NIL
HORIZONTAL

TEXTBOX
689
41
1079
281
Node shapes:\ncircle = no interesting property\ntriangle = curious\nsquare = enthusiastic or supporter\npentagon = curious and (enthousiastic or supporter)\n\nNode colors:\npurple = Aware and Knowledgeable\nbrown = Unaware and Knowledgeable\norange = proactive\n\nLink colors:\ngreen = awareness cascade\norange = expertise cascade\npurple = chain of information retrieval\n
12
9.9
1

@#$#@#$#@
## WHAT IS IT?

Studies on word-of-mouth identify two behaviors leading to transmission of information between individuals: proactive transmission of information, and information seeking. Individuals who are aware might be curious of it and start seeking for information; they might find around them the expertise held by another individual. Field studies indicate individuals do not adopt an innovation if they don’t hold the corresponding expertise.

This model describes this information seeking behavior, and enables the exploration of the dynamics which emerges out of it.

Information seeking is only possible if an individual can hold at least two levels of knowledge:
* awareness: the individual heard about the existence of an innovation or product thanks to advertisement or another individual who passed him the word.
* expertise: the individual holds expertise, either because he’s interested in this domain/brand/category of innovation or because someone else passed him this expertise.

The goal of an institution driving a communication campaign is to achieve to have a population which is not only aware, but also holds the expert knowledge required to assess it. Using the model, one can explore the following questions:
* is it more efficient to design advertisement so people are curious of it and engage into information seeking (parameter curiousness), or make them speak about it when they understood the innovation (parameters supporters and enthusiastic)?
* what it is the impact of the social network on the diffusion dynamics?
* how efficient is word-of-mouth for individuals to retrieve the expertise scattered throughout the population?


## HOW IT WORKS

During initialization, a population of agents is created being in state (Unaware, Ignorant), meaning agents first do not know the existence of the innovation (awareness knowledge) and also don't hold the expertise required to understand it (expert knowledge). A proportion "initial-proportion-knowledgeable" is set to (Unaware, Knowledgeable): they are not aware of the existence of the innovation, but they hold the expertise required to understand it (for instance because they know the category of production, a similar innovation, the brand of the product, attended a training, etc.).

At setup time, the network indicated as a parameter is also loaded and used as a social network in the model. This network defines the structure of interactions in the population.

Also during initialization, agents are randomly assigned three personnality characteristics: curious, enthusiastic, supporter, according to the parameters defined by the user.


Each time step (tick), the advertisement campain reaches a given proportion of the population and sends them awareness.

When an Unaware and Ignorant agent receives awareness, an agent becomes Seeking out expert knowledge if he has property curious=True, or else becomes passively Aware of the existence of the innovation.



OLD OLD OLD !!!

each infected node (colored red) attempts to infect all of its neighbors.  Susceptible neighbors (colored green) will be infected with a probability given by the VIRUS-SPREAD-CHANCE slider.  This might correspond to the probability that someone on the susceptible system actually executes the infected email attachment.
Resistant nodes (colored gray) cannot be infected.  This might correspond to up-to-date antivirus software and security patches that make a computer immune to this particular virus.

Infected nodes are not immediately aware that they are infected.  Only every so often (determined by the VIRUS-CHECK-FREQUENCY slider) do the nodes check whether they are infected by a virus.  This might correspond to a regularly scheduled virus-scan procedure, or simply a human noticing something fishy about how the computer is behaving.  When the virus has been detected, there is a probability that the virus will be removed (determined by the RECOVERY-CHANCE slider).

If a node does recover, there is some probability that it will become resistant to this virus in the future (given by the GAIN-RESISTANCE-CHANCE slider).

When a node becomes resistant, the links between it and its neighbors are darkened, since they are no longer possible vectors for spreading the virus.

## HOW TO USE IT

Using the sliders, choose the NUMBER-OF-NODES and the AVERAGE-NODE-DEGREE (average number of links coming out of each node).

The network that is created is based on proximity (Euclidean distance) between nodes.  A node is randomly chosen and connected to the nearest node that it is not already connected to.  This process is repeated until the network has the correct number of links to give the specified average node degree.

The INITIAL-OUTBREAK-SIZE slider determines how many of the nodes will start the simulation infected with the virus.

Then press SETUP to create the network.  Press GO to run the model.  The model will stop running once the virus has completely died out.

The VIRUS-SPREAD-CHANCE, VIRUS-CHECK-FREQUENCY, RECOVERY-CHANCE, and GAIN-RESISTANCE-CHANCE sliders (discussed in "How it Works" above) can be adjusted before pressing GO, or while the model is running.

The NETWORK STATUS plot shows the number of nodes in each state (S, I, R) over time.

## THINGS TO NOTICE

At the end of the run, after the virus has died out, some nodes are still susceptible, while others have become immune.  What is the ratio of the number of immune nodes to the number of susceptible nodes?  How is this affected by changing the AVERAGE-NODE-DEGREE of the network?

## THINGS TO TRY

Set GAIN-RESISTANCE-CHANCE to 0%.  Under what conditions will the virus still die out?   How long does it take?  What conditions are required for the virus to live?  If the RECOVERY-CHANCE is bigger than 0, even if the VIRUS-SPREAD-CHANCE is high, do you think that if you could run the model forever, the virus could stay alive?

## EXTENDING THE MODEL

The real computer networks on which viruses spread are generally not based on spatial proximity, like the networks found in this model.  Real computer networks are more often found to exhibit a "scale-free" link-degree distribution, somewhat similar to networks created using the Preferential Attachment model.  Try experimenting with various alternative network structures, and see how the behavior of the virus differs.

Suppose the virus is spreading by emailing itself out to everyone in the computer's address book.  Since being in someone's address book is not a symmetric relationship, change this model to use directed links instead of undirected links.

Can you model multiple viruses at the same time?  How would they interact?  Sometimes if a computer has a piece of malware installed, it is more vulnerable to being infected by more malware.

Try making a model similar to this one, but where the virus has the ability to mutate itself.  Such self-modifying viruses are a considerable threat to computer security, since traditional methods of virus signature identification may not work against them.  In your model, nodes that become immune may be reinfected if the virus has mutated to become significantly different than the variant that originally infected the node.

## RELATED MODELS

Virus, Disease, Preferential Attachment, Diffusion on a Directed Network

## NETLOGO FEATURES

Links are used for modeling the network.  The `layout-spring` primitive is used to position the nodes and links such that the structure of the network is visually clear.

Though it is not used in this model, there exists a network extension for NetLogo that you can download at: https://github.com/NetLogo/NW-Extension.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Stonedahl, F. and Wilensky, U. (2008).  NetLogo Virus on a Network model.  http://ccl.northwestern.edu/netlogo/models/VirusonaNetwork.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2008 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2008 Cite: Stonedahl, F. -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.2.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
