extensions [nw]

globals
[
  ticks-for-peak-A ;; the tick for the max of Awareness (was never higher later)
  last-max-peak-A
  ticks-for-peak-AK ;; the tick for the max of AK (was never higher later)
  last-max-peak-AK
  ticks-last-activity ; the last tick when something happened
]

;; defines the type used for links
undirected-link-breed [edges edge]

;; "turtles" (in the good old netlogo terminology)
;; represent individuals holding states for awareness and an expertise
;; they are also nodes in the social network
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

;; "links" represent social links.
;; their states are just used to understand what happens during the simulation
;; (visualisation) but not for computations.
links-own
[
 cascade-awareness?
 cascade-expertise?
 chain-retrieval?
]

to-report result-A
  report (count turtles with [not unaware?] / count turtles)
end

to-report result-AK
  report count turtles with [(not unaware?) and (not ignorant?)] / count turtles
end

to-report genlab-outputs
  report ["result-AK" "result-A" ]
end

to setup-network-load
  ;; load the network from the file and also initialize their state
  show "loading network"
  show network-filename
  nw:load-graphml network-filename
   [
    ; for visual reasons, we don't put any turtles *too* close to the edges
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
     show "network graphical layout..."
     repeat 200 [layout-spring turtles links 0.1 4 4]
     ;layout-radial turtles links (turtle 0)

   ]
   ;repeat 5 [ layout-spring turtles links 0.8 (world-width / (sqrt count turtles)) 1 ]
  show "end of init, let's play!"
end


to setup

  clear-all

  setup-network-load
  setup-turtles

  ; init the characteristics
  ask turtles [
    set curious? false
    set enthusiastic? false
    set supporter? false
  ]

  ask n-of (proportion-curious * count turtles) turtles [
    set curious? true
  ]
  ask n-of (proportion-enthusiastic * count turtles) turtles [
      set enthusiastic? true
  ]
  ask n-of (proportion-supporters * count turtles) turtles [
        set supporter? true
  ]

  ask turtles [
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

to setup-turtles
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
2172
1506
-1
-1
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
0.42
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
5.0
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
5.0
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
0.04
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
0.03
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
0.39
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
0.0
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
networks/network_1000.graphml
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
6.0
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
0.0
0.01
1
NIL
HORIZONTAL

TEXTBOX
689
41
1222
281
Node shapes represent the constant properties of people:\ncircle = nothing special\ntriangle = curious (if aware, starts seeking out)\nsquare = enthusiastic or supporter (if knowledgeable, starts passing the word)\npentagon = curious and (enthousiastic or supporter)\n\nNode colors: current state of people\npurple = Aware and Knowledgeable\nbrown = Unaware and Knowledgeable\norange = proactive\n\nLink colors:\ngreen = awareness cascade\norange = expertise cascade\npurple = chain of information retrieval\n
12
9.9
1

@#$#@#$#@
## WHAT IS IT?

Studies on word-of-mouth identify two facets in the transmission of information: seeking and spreading. People seek out for information when they become aware of an innovation, in order to gather the expert knowledge required to understand it. Only when they are aware and expert, people can decide to adopt or reject. Past models only saw word-of-mouth as one-dimentionnal epidemic dynamics (Susceptible, Infective, Removed); here we provide a minimalist model to study what happens if we consider both awareness and expertise. In this model, a small proportion of the population is initially holding expertise; the question is how many agents will achieve to gather it because of advertisement or peers raising their curiosity.

Information seeking is only possible if an individual can hold at least two levels of knowledge, namely awareness and expert knowledge:

  * **awareness**: does the individual knows the existence of the innovation, even if s/he does not understands it? Encoded as 3 levels: U, S, A
    * **U**naware: the individual does not know the existence of the innovation 
    * aware & **S**eeking: the individual heard about the existence of the innovation, and is curious of it, so s/he is seeking for more information around him/her
    * passively **A**ware: the individual knows the existence of the innovation but is not searching for information (maybe s/he did before)
  * **expertise**: the individual holds expertise, either because he’s interested in this domain/brand/category of innovation or because someone else passed him this expertise. We define it as 3 levels: I, P, K
    * **I**gnorant: the individual does not know the expert knowledge required to understand the innovation
    * knowledgeable & **P**romoting: the individual discovered the expert knowledge, and because s/he understands the interest of it, is promoting it
    * passively **K**nowledgeable: the individual holds the expert knowledge, does not spreads the word proactively, but answers questions if questionned

The goal of an institution driving a communication campaign is to **achieve to have a population which is not only aware, but also holds the expert knowledge required to assess it**. Using the model, one can explore the following questions:

  * is it more efficient to design advertisement so people are curious of it and engage into information seeking (parameter curiousness), or make them speak about it when they understood the innovation (parameters supporters and enthusiastic)?
  * what it is the impact of the social network on the diffusion dynamics?
  * how efficient is word-of-mouth for individuals to retrieve the expertise scattered throughout the population?


## HOW IT WORKS

Each agent in the population represents an individual. Individuals have **constant characteristics** constant during the simulation:

  * _curious_ individuals start seeking out information when they become aware; else they are just passively aware.
  * _enthusiastic_ individuals start promoting the innovation when they receive the expertise after being aware
  * _supporter_ individuals start promoting the innovation when they receive the awareness after being knowledgable 

Individuals also have a **state of knowledge** which evolves during the simulation. It is made of both awareness and expertise knowledge, so individuals hold a tuple (awareness, expertise), for instance (Unaware, Ignorant) for most of them, or (Unaware, Knowledgeable) for people holding the generic expertise but unaware of the innovation of interest. 

During initialization, a population of agents is created being in state (Unaware, Ignorant), meaning agents first do not know the existence of the innovation (awareness knowledge) and also don't hold the expertise required to understand it (expert knowledge). A proportion "initial-proportion-knowledgeable" is set to (Unaware, Knowledgeable): they are not aware of the existence of the innovation, but they hold the expertise required to understand it (for instance because they know the category of production, a similar innovation, the brand of the product, attended a training, etc.).

At setup time, the network indicated as a parameter is also loaded and used as a social network in the model. This network defines the structure of interactions in the population.

Also during initialization, agents are randomly assigned three personnality characteristics: curious, enthusiastic, supporter, according to the parameters "proportion-curious", "proportion-enthusiastic", "proportion-supporter" defined by the user.

Each time step (tick):

  1. the advertisement campain reaches a given proportion of the population and sends them awareness.
  2. the individuals linked together are offered the possibility to interact. If one of them is in state Seeking or Promoting, then an interaction takes place; each individual transmits its knowledge to the other individual. 


The individual state of knowledge is driven by the following rules (which are easier to understand with the figures on the related publication, see "how to cite" below):

  * when an (Unaware,Ignorant) agent receives awareness (by advertisement or an interaction): he becomes (Seeking,Ignorant) if he is _curious_, else he becomes (Aware,Ignorant)
  * when an (Unaware,Ignorant) agent receives expertise (through an interaction): he becomes (Unaware,Promoting) if he is _enthusiastic_, else he becomes (Unaware,Knowledgeabe)
  * when a (Seeking,Ignorant) individual is seeking since more than a timeout parameter _duration-seek_, he becomes (Aware,Ignorant) (meaning he stops seeking) 
  * when a (Seeking,Ignorant) individual receives expertise (through an interaction): if he is _enthusiatic_, he stops seeking and starts promoting, thus becomes (Aware,Promoting). Else he stops seeking and becomes passively Knowledgeable: (Aware,Knowledgeable).
  * when an (Aware,Ignorant) individual receives expertise: if he is _enthusiatic_, he becomes (Aware,Promoting), else he becomes (Aware,Knowledgeable)
  * when an (Unaware,Promoting) individual receives awareness, he gets awareness and keeps promoting, so he becomes (Aware,Promoting)
  * when an (Unaware,Promoting) individual is promoting since more than a timeout parameter duration-promoting, he becomes (Unaware,Knowledeagble) (meaning he stops promoting)
  * when an (Unaware,Knowledgeable) individual receives awareness, it means someone expert discovers the innovation;  if he is _supporter_ he becomes (Aware,Promoting), else he becomes (Aware,Knowledgable)

## HOW TO USE IT

Set _proportion-curious_, _proportion-enthusiatic_, _proportion-supporters_ to 0.3; set _initial-proportion-knowledgeable_ to 0.03; that's a way to see many things to happen. Click "setup" then "run". 

## THINGS TO NOTICE

Look at the "diffusion" plot. The green and orange curves represent the people Seeking and Promoting the innovation; the diffusion of knowledge is first bootstrapped by people who Seek out for information (if there are enough curious) and thus also propagate the  existence of awareness. There is first a _diffusion of seeking_: an "hype" is inchreasing in the population of people who want to know more. Then when people Seeking for information achieve to find expertise held by one of the few initial experts, they hold the expertise and can pass it back to others. Information seeking acts as a bootstrap for expertise retrieval. 

Notice that at the end of the simulation, a large part of the population got the expertise, despite of the very low initial proportion of expertise in the population (3%). 

Look at the network view of the population. Green edges mean someone discovered awareness thanks to this edge; orange than expertise was propagated; purple that both occured. At the beginning many awareness cascades happen, where each Seeker is "contaminating" other curious entities. When a Seeker meets an expert, then he becomes expert, and can thus answer the questions asked by people around him; so there is the apparition of "information retrieval chains" in purple, in which individuals A made B curious who made C curious, C gets expertise from D, then becomes knowledgeable, then tells expertise to B, who passes it to A, etc. This type of chain is capital in the model, and raises the question of their actual existence in the field. 

Note how on the diffusion plot the S-curve of the proportion of awareness is always way higher than the curve "AK" (Aware and Knowledgeable). Measuring the impact of advertisement would only measure how many people were made aware, but would not quantify how many people hold enough information to understand and adopt the innovation.

## THINGS TO TRY

Set _proportion-curious_ to 0, so there is no information seeking any more, falling back to a pure epidemic setting. Explore the proportions of enthusiastic and supporters required to reach high levels of awareness and knowledge at the end of the simulation. 

Try also a high proportion of curious and few enthusiastic and supporters; observe how we actually need both to reach efficient information diffusion.


## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Samuel Thiriot, Word-of-mouth dynamics with information seeking: Information is not (only) epidemics,
Physica A: Statistical Mechanics and its Applications,
Volume 492, 2018, Pages 418-430,
ISSN 0378-4371,
https://doi.org/10.1016/j.physa.2017.09.056.
(http://www.sciencedirect.com/science/article/pii/S0378437117309482)

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
NetLogo 6.0.3
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
