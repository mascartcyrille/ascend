################################################################################
## Package ASCEND
## authors: C. Mascart, G. Mezzadri
################################################################################
# Installation of required packages ----
if(! "httr" %in% rownames(installed.packages())) {
  install.packages("httr")
}
if(! "network" %in% rownames(installed.packages())) {
  install.packages("network")
}
if(! "doParallel" %in% rownames(installed.packages())) {
  install.packages("doParallel")
}

rm(list=ls())
# Load required packages ----
library(httr)
library(doParallel)

# Functions -----
getEntryLine <- function(paperId, line) {
  r <- GET(paste("https://api.semanticscholar.org/graph/v1/paper/", paperId, "?fields=title,authors,references.authors,references.title", sep=""))
  references <- content(r)$references
  
  for(cit in references) {  # For all the references cited in the article
    if(!is.null(cit$paperId)) {
      for(author in cit$authors) {  # For all the authors of these references
        if(!is.null(author$authorId) && author$authorId %in% AuthorsIDs) { # Check whether the author is within the list of authors considered
          line[author$authorId] = line[author$authorId] + 1
        }
      }
    }
  }
  
  return(line)
}

getOutputLine <- function(paperId, line) {
  r <- GET(paste("https://api.semanticscholar.org/graph/v1/paper/", paperId, "?fields=authors,references.authors", sep=""))
  authors    <- content(r)$authors
  
  ## Put all new authors in the lists ----
  for(author in authors) {
    if(!is.null(author$authorId) && author$authorId %in% AuthorsIDs)
      line[author$authorId] = line[author$authorId] + 1
  }
  
  return(line)
}

# Variables -----
AuthorsList <- c("103641375")# , "1380244052", "2379247", "2113541", "2300147", "1755591")
AuthorsIDs       <- c()
AuthorsNames     <- c()
AuthorsVertexIDs <- list()
PapersHistory <- c()
PapersIDs <- list()

papr_idx <- 1
max_authors <- 100
for(auth_idx in 1:max_authors) {
  # print(paste("Author ", auth_idx, "/", max_authors, sep=""))
  r <- GET(paste("https://api.semanticscholar.org/graph/v1/author/", AuthorsList[auth_idx], "?fields=name,papers.authors", sep=""))
  papers <- content(r)$papers
  papr_idx <- 1
  for(paper in papers) {
    # cat(paste("Paper ", papr_idx, "/", length(papers), sep=""))
    papr_idx <- papr_idx + 1
    if(!is.null(paper$paperId) && is.null(PapersIDs[[paper$paperId]])) {
      PapersIDs[[paper$paperId]] <- TRUE
      PapersHistory <- c(PapersHistory, paper$paperId)
      
      if(length(AuthorsIDs) < max_authors) {
        r <- GET(paste("https://api.semanticscholar.org/graph/v1/paper/", paper$paperId, "?fields=authors,references.authors", sep=""))
        authors    <- content(r)$authors
        
        ## Put all new authors in the lists ----
        for(author in authors) {
          if(!is.null(author$authorId) && !is.null(author$name) && !author$name %in% AuthorsNames) {
            AuthorsIDs = c(AuthorsIDs, author$authorId)
            AuthorsNames = c(AuthorsNames, author$name)
            if(!author$authorId %in% AuthorsList)
              AuthorsList = c(AuthorsList, author$authorId)
          }
        }
      }
    }
  }
}

# Instanciate Input and Output data matrices
InputList  <- data.frame(matrix(data = 0, nrow = length(PapersHistory), ncol = length(AuthorsIDs), dimnames = list(rowNames = PapersHistory, colNames = AuthorsIDs)), check.names = F)
OutputList <- data.frame(matrix(data = 0, nrow = length(PapersHistory), ncol = length(AuthorsIDs), dimnames = list(rowNames = PapersHistory, colNames = AuthorsIDs)), check.names = F)

no_cores <- detectCores()
cl <- makeCluster(no_cores, type="FORK")  
registerDoParallel(cl)  
InputList <- foreach(i=1:length(PapersHistory), .combine = rbind) %dopar% getEntryLine(PapersHistory[i], InputList[i,])
OutputList <- foreach(i=1:length(PapersHistory), .combine = rbind) %dopar% getOutputLine(PapersHistory[i], OutputList[i,])
stopCluster(cl)