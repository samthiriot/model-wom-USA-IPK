# What is it?

This is the implementation of a model of word-of-mouth.
In this model, we investigate what happens is we do not only represent information being just diffused amongst a population, 
but when individuals also search for information.

The model is described in the following publication:

Samuel Thiriot, Word-of-mouth dynamics with information seeking: Information is not (only) epidemics,
Physica A: Statistical Mechanics and its Applications,
Volume 492, 2018, Pages 418-430,
ISSN 0378-4371,
https://doi.org/10.1016/j.physa.2017.09.056.
(http://www.sciencedirect.com/science/article/pii/S0378437117309482)


# How to use it?

This model runs under Netlogo 6; you can freely download it from here: https://ccl.northwestern.edu/netlogo/download.shtml

Start Netlogo; open the `model-wom-information-seeking.nlogo` file from netlogo; click setup, then simulate. 
Then restart by tuning parameters. Have a look to the "info tab" which explains what happens and what to explore.


# Exploration of the space of parameters

To explore the space of parameters, we rely on the OpenMole software: https://www.openmole.org/

Open in OpenMole the exploration workflow found in the "exploration" directory. 
For each point of the space of parameters, this workflow will:
* generate a network using R/igraph and measure its properties
* transmit it to netlogo as an input file
* store the simulation results into a CSV file 


# Advanced 

## generate other networks 

networks in this model represent the structure of interactions, which has a huge influence on the dynamics simulated. 

You can easily genarate novel graphs to use using R/igraph. 

    R
    library(igraph)
	g <- igraph::watts.strogatz.game(size=1000,nei=4,dim=1,multiple=F,loops=F,p=0.1)
	average.path.length(g)
	write.graph(g, file="network_1000.graphml", format="graphml")

