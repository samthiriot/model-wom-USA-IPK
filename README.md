# model-wom-USA-IPK
a model of word-of-mouth 

# prerequires

This model runs under Netlogo 5.1 


# generate other networks 

networks in this model represent the structure of interactions, which has a huge influence on the dynamics simulated. 

You can easily genarate novel graphs to use using R/igraph. 

> R
> library(igraph)
> g <- igraph::watts.strogatz.game(size=1000,nei=4,dim=1,multiple=F,loops=F,p=0.1)
> average.path.length(g)
> write.graph(g, file="network_1000.graphml", format="graphml")

