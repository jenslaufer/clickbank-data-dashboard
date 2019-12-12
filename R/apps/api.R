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


load.data <- function(url = "mongodb://localhost") {
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
      ), ),
      include.lowest = T
    ))) %>%
    mutate(ActivateDate = if_else(is.na(ActivateDate), as.Date("2000-01-01"), ActivateDate))
  
  
  data <- data %>%
    arrange(Id, ParentCategory, Category, Date)  %>%
    group_by(Id, ParentCategory, Category) %>%
    mutate_at(numeric.cols, list(Change = ~ ((.) - dplyr::lag(.)) / dplyr::lag(.))) %>%
    ungroup()
  
  
  # gmm <- Mclust(data %>% select(numeric.cols))
  # data <- data %>% mutate(gmm.cluster = gmm$classification)
  
  data <- data %>% inner_join(
    data %>%
      filter(!is.na(ParentCategory)) %>%
      group_by(Id) %>%
      dplyr::summarise(Gravity_Change_mean = median(Gravity_Change, na.rm = T)) %>%
      arrange(-Gravity_Change_mean) %>%
      ungroup(),
    by = "Id"
  )
  
  data
}

cluster.data <- function(data) {
  data.pca <- data %>%
    dplyr::select(numeric.cols) %>%
    prcomp(center = T, scale. = T)
  
  data <- data %>% bind_cols(data.pca$x %>% as_tibble())
  fit <- kmeans(data %>% select(PC1, PC2), 5)
  
  
  data <- data %>% mutate(kmeans.cluster = fit$cluster)
  data
}
