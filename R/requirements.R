update.packages(lib.loc="/usr/local/lib/R/site-library", ask=FALSE, checkBuilt=TRUE, repos = "https://cloud.r-project.org")

list.of.packages <- c('ggbiplot', 'mclust', 'ggalt', 'bbplot', 'scales', 'shinyWidgets', 'shinythemes', 'shinycssloaders', 'logging', 'ggrepel')
new.packages <-
  list.of.packages[!(list.of.packages %in% installed.packages()[, "Package"])]
if (length(new.packages))
  install.packages(new.packages)