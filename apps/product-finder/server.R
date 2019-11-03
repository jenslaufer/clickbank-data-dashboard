library(shiny)
library(logging)


source("../api.R")

.filter.values <- function(data, input) {
    data %>%
        filter(Gravity >= input$gravity[1] &
                   Gravity <= input$gravity[2]) %>%
        filter(
            AverageEarningsPerSale >= input$average.earnings[1] &
                AverageEarningsPerSale <= input$average.earnings[2]
        ) %>%
        filter(
            InitialEarningsPerSale >= input$initial.earnings[1] &
                InitialEarningsPerSale <= input$initial.earnings[2]
        )
}

.update.slider <- function(data, session, name, field) {
    max <- data %>% pull(field) %>% max()
    min <- data %>% pull(field) %>% min()
    updateSliderInput(
        session,
        name,
        max = max,
        min = min,
        value = c(min, max)
    )
}

shinyServer(function(input, output, session) {
    loginfo("initializing...")
    
    data <- load.data()
    
    .update.slider(data, session, "gravity", "Gravity")
    .update.slider(data,
                   session,
                   "average.earnings",
                   "AverageEarningsPerSale")
    .update.slider(data,
                   session,
                   "initial.earnings",
                   "InitialEarningsPerSale")
    .update.slider(data, session, "percent.per.rebill", "PercentPerRebill")
    
    loginfo("initializing.")
    
    output$products <-
        DT::renderDataTable(
            data %>%
                .filter.values(input) %>%
                select(Id, Title, PopularityRank, Gravity, AverageEarningsPerSale),
            selection = 'single'
        )
    
    output$gravityPlot <- renderPlot({
        data %>%
            .filter.values(input) %>%
            ggplot(aes(
                x = Gravity,
                y = AverageEarningsPerSale,
                color = PopularityRank_bin
            )) +
            geom_point()
        
    })
    
})
