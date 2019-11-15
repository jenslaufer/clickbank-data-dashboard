library(glue)
library(XML)
library(methods)
library(jsonlite)
library(DT)
library(ggthemes)
library(devtools)
library(ggrepel)
library(tidyverse)
library(ggbiplot)
library(mclust)
library(ggalt)


load.file <- function(){
  
  url <-
    "https://accounts.clickbank.com/feeds/marketplace_feed_v2.xml.zip"
  target.dir <- tempdir()
  target.file <- "{target.dir}/clickbank.zip" %>% glue()
  xml.file.name <- "{target.dir}/marketplace_feed_v2.xml" %>% glue()
  
  if (!file.exists(target.file)) {
    download.file(url,
                  target.file)
    unzip(target.file, exdir = target.dir)
  }
  
  xml.file.name
}

load.data <- function() {
  
  xml.file.name <- load.file()
  
  numeric.cols <-  c(
    "Gravity",
    "PercentPerSale",
    "PercentPerRebill",
    "AverageEarningsPerSale",
    "InitialEarningsPerSale",
    "TotalRebillAmt",
    "Referred",
    "Commission"
  )
  
  data <-
    xmlToDataFrame(nodes = getNodeSet(
      xmlParse(file = xml.file.name, encoding = "ISO-8859-1"),
      "//Site"
    )) %>%
    mutate_at(numeric.cols, as.character) %>%
    mutate_at(numeric.cols, as.double) %>%
    mutate(
      PopularityRank = as.integer(as.character(PopularityRank)),
      PopularityRank_bin = cut(
        PopularityRank,
        breaks = quantile(PopularityRank, probs =
                            seq(0, 1, 0.2)),
        include.lowest = T
      ),
      ActivateDate = as.Date(ActivateDate),
      HasRecurringProducts = if_else(HasRecurringProducts == 'true', T, F)
    ) %>%
    mutate_at(numeric.cols, .funs = list(bin =  ~ cut(
      .,
      breaks = unique(quantile(
        ., probs = seq(0, 1, by = 0.20), na.rm = T
      ), ),
      include.lowest = T
    ))) %>%
    group_by(Id) %>%
    arrange(Id, PopularityRank) %>%
    slice(1) %>%
    ungroup()
  
  
  data.pca <- data %>%
    dplyr::select(numeric.cols) %>%
    prcomp(center = T, scale. = T)
  
  data <- data %>% bind_cols(data.pca$x %>% as_tibble())
  fit <- kmeans(data %>% select(PC1, PC2), 5)
  

  data <- data %>% mutate(kmeans.cluster = fit$cluster) %>% 
    mutate(ActivateDate = if_else(is.na(ActivateDate), as.Date("2000-01-01"), ActivateDate))
  
  
  # gmm <- Mclust(data %>% select(numeric.cols))
  # data <- data %>% mutate(gmm.cluster = gmm$classification)
  
  data
}