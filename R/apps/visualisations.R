library(tidyverse)
library(ggthemes)
library(logging)
library(bbplot)



plot.gravity.averageenarningspersale <- function(data) {
  data %>%
    ggplot(aes(x = Gravity,
               y = AverageEarningsPerSale,
               color = PopularityRank_bin)) +
    geom_point()
}

plot.cluster.scatter <- function(data) {
  data %>%
    ggplot(aes(x = PC1,
               y = PC2,
               color = cluster)) +
    geom_point(alpha = 0.6, size = 2) +
    scale_color_tableau()
}

plot.magnifier <- function(data) {
  data %>%
    mutate(cluster = as.factor(kmeans.cluster)) %>%
    arrange(-Gravity, -AverageEarningsPerSale) %>%
    ggplot(aes(x = PC1,
               y = PC2,
               color = cluster)) +
    geom_point(alpha = 0.6, size = 2) +
    geom_label_repel(aes(label = selected.title)) +
    scale_color_tableau()
}

plot.gravity.change.history <- function(data, id) {
  data %>%
    filter(Id == id, !is.na(ParentCategory)) %>%
    select(Id, Date, Category, Gravity, Gravity_Change) %>%
    na.omit() %>%
    arrange(Date) %>%
    mutate(
      Gravity_Change = Gravity_Change * 100,
      Date = as.Date(Date),
      sign = if_else(Gravity_Change < 0, "-", "+")
    ) %>%
    ggplot(aes(x = Date, y = Gravity_Change)) +
    geom_bar(aes(fill = sign), stat = "identity") +
    geom_line(size = 3) +
    geom_point(size = 8) +
    geom_hline(aes(yintercept = 0)) +
    scale_x_date(date_breaks = "1 day") +
    scale_fill_manual(values = c("#E15759", "#4E79A7")) +
    bbc_style() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    guides(fill = FALSE)
}

plot.gravity.change.barchart <- function(data, num) {
  data %>%
    select(Id,
           Title,
           ParentCategory,
           Category,
           Date,
           Gravity,
           Gravity_Change) %>%
    filter(Gravity_Change != Inf) %>%
    distinct(Id, .keep_all = T) %>%
    arrange(-Gravity_Change) %>%
    head(num) %>%
    ggplot() +
    geom_bar(aes(x = reorder(
      paste(Id, Title, sep = ': '), Gravity_Change
    ), y = Gravity_Change),
    stat = 'identity',
    fill = "#4E79A7") +
    coord_flip() +
    bbc_style()
}

plot.gravity.gravity.change <- function(data) {
  data %>%
    ggplot(aes(x = Gravity, y = Gravity_Change)) +
    geom_point(alpha = 0.2, color = "#4E79A7") +
    scale_y_log10() +
    scale_x_log10() +
    bbc_style()
}