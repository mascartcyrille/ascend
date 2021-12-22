################################################################################
## Package ASCEND
## authors: C. Mascart, G. Mezzadri
################################################################################
# Installation of required packages
if(! "httr" %in% rownames(installed.packages())) {
  install.packages("httr")
}
if(! "network" %in% rownames(installed.packages())) {
  install.packages("network")
}

# Load required packages
library(httr)
library(network)

# Getting the papers through the SemanticScholars API
MaxLoops <- 1
InitPaperID <- "118d0088f145124b9631bef0dbe784eed7df60f9"
AuthorsNetwork <- network.initialize(0, loops = TRUE)
AuthorsVertexIDs <- list()
AuthorsIDs <- list()
AuthorsNames<- list()
PapersHistory <- c()
PapersPresent <- c()

## Main loop will go here
PapersFuture <- c(InitPaperID)

for(loop in 1:MaxLoops) {
  PapersHistory <- unique(c(PapersHistory, PapersPresent))
  PapersPresent <- PapersFuture
  PapersFuture <- c()
  for(paperID in PapersPresent) {
    if(!is.null(paperID) && !paperID %in% PapersHistory) {
      ##### Will return the names of all authors who have cited this paper + all references' authors cited by this paper
      r <- GET(paste("https://api.semanticscholar.org/graph/v1/paper/", paperID, "?fields=authors,citations.authors,references.authors", sep=""))
      authors <- content(r)$authors
      # citatiers <- content(r)$citations
      citatiees <- content(r)$references
      
      for(author in authors) {
        if(!author$name %in% AuthorsNames) {
          add.vertices(x = AuthorsNetwork, nv = 1, vattr = replicate(1,list(auth.name=author$name),simplify = FALSE))
          AuthorsIDs[[ AuthorsNetwork$gal$n ]] = author$authorId
          AuthorsNames[[ AuthorsNetwork$gal$n ]] = author$name
          AuthorsVertexIDs[[ author$name ]] = AuthorsNetwork$gal$n
        }
      }
      
      # for(cit in citatiers) {
      #   for(author in cit$authors) {
      #     if(!author$name %in% AuthorsNames) {
      #       add.vertices(x = AuthorsNetwork, nv = 1, vattr = replicate(1,list(auth.name=author$name),simplify = FALSE))
      #       AuthorsIDs[[ AuthorsNetwork$gal$n ]] = author$authorId
      #       AuthorsNames[[ AuthorsNetwork$gal$n ]] = author$name
      #       AuthorsVertexIDs[[ author$name ]] = AuthorsNetwork$gal$n
      #     }
      #     for(art_author in authors) {
      #       add.edge(x = AuthorsNetwork, tail = AuthorsVertexIDs[[ author$name ]], head = AuthorsVertexIDs[[ art_author$name ]])
      #     }
      #   }
      # }
      
      for(cit in citatiees) {
        for(author in cit$authors) {
          if(!author$name %in% AuthorsNames) {
            add.vertices(x = AuthorsNetwork, nv = 1, vattr = replicate(1,list(auth.name=author$name),simplify = FALSE))
            AuthorsIDs[[ AuthorsNetwork$gal$n ]] = author$authorId
            AuthorsNames[[ AuthorsNetwork$gal$n ]] = author$name
            AuthorsVertexIDs[[ author$name ]] = AuthorsNetwork$gal$n
          }
          for(art_author in authors) {
            add.edge(x = AuthorsNetwork, tail = AuthorsVertexIDs[[ art_author$name ]], head = AuthorsVertexIDs[[ author$name ]])
          }
        }
      }
      
      PapersFuture <- unique(c(PapersFuture
                               , unlist(sapply(citatiees, function(p){p$paperId}))
                               # , unlist(sapply(citatiers, function(p){p$paperId}))
                               ))
    }
  }
}

plot(AuthorsNetwork)
