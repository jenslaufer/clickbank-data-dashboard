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
library(mongolite)


load.data <- function(url = "mongodb://localhost") {
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
  
  con <- mongo("products", "clickbank", url)
  
  
  data <-
    con$find() %>%
    as_tibble() %>%
    mutate(
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
      ),),
      include.lowest = T
    ))) 
  
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