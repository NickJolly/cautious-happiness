## CRAN Packages
install.packages(c("ggplot2", "stringr", "reshape2", "dichromat", "devtools"))
## EBImage
if (!require("BiocManager", quietly = TRUE))
  install.packages("BiocManager")
BiocManager::install(version = "3.14")
BiocManager::install("EBImage")
## Packages on GitHub
library(devtools)
install_github("ramnathv/rblocks")
## And finally ...
install_github("woobe/rPlotter")

library(rPlotter)




vertical <- function (paths) {
  par(mfrow=c(1,8), mai=c(0.1,0.1,0.1,0.1), bg='#f2f2f2')
  for (path in paths) {
    pal <- extract_colours(path)
    hist(0.1+1:5, breaks=4, col=pal, main=NA, axes=F, border=NA)
  }
}

horizontal <- function (paths) {
  par(mfrow=c(1,8), mai=c(0.1,0.1,0.1,0.1), bg='#f2f2f2')
  for (path in paths) {
    pal <- extract_colours(path)
    barplot(rep(1,5), col=pal, horiz=T, main=NA, axes=F, space=0, border=NA)
  }
}

slices <- function (paths, params=F) {
  par(mfrow=c(2,5), mai=c(0,0,0,0), bg='#ece0d9')
  for (path in paths) {
    pal <- extract_colours(path)
    pie(rep(1,5), col=pal, edges=5,labels=NA, border=NA, init.angle = runif(1)*360)
  }
}

# NOTE: actual images are not available
# TAS
paths <- paste( 'tas/', as.character(1:8), '.JPG', sep='')
# VIC
paths <- paste( 'vic/', as.character(1:8), '.JPG', sep='')
# SA
paths <- paste( 'sa/', as.character(1:8), '.JPG', sep='')
# GOR
paths <- paste( 'gor/', as.character(1:8), '.JPG', sep='')


vertical(paths)
horizontal(paths)
slices(paths)