library(shiny)
library(logging)


source("../api.R")

.filter.values <- function(data, input) {
    data %>%
        filter(Gravity >= input$Gravity[1] &
                   Gravity <= input$Gravity[2]) %>%
        filter(
            AverageEarningsPerSale >= input$AverageEarningsPerSale[1] &
                AverageEarningsPerSale <= input$AverageEarningsPerSale[2]
        ) %>%
        filter(
            InitialEarningsPerSale >= input$InitialEarningsPerSale[1] &
                InitialEarningsPerSale <= input$InitialEarningsPerSale[2]
        ) %>%
        filter(
            PercentPerRebill >= input$PercentPerRebill[1] &
                PercentPerRebill <= input$PercentPerRebill[2]
        ) %>%
        filter(
            PercentPerSale >= input$PercentPerSale[1] &
                PercentPerSale <= input$PercentPerSale[2]
        ) %>%
        filter(
            TotalRebillAmt >= input$TotalRebillAmt[1] &
                TotalRebillAmt <= input$TotalRebillAmt[2]
        ) %>%
        filter(Referred >= input$Referred[1] &
                   Referred <= input$Referred[2]) %>%
        filter(Commission >= input$Commission[1] &
                   Commission <= input$Commission[2])
}

.update.slider <- function(data, session, field) {
    max <- data %>% pull(field) %>% max()
    min <- data %>% pull(field) %>% min()
    updateSliderInput(
        session,
        field,
        max = max,
        min = min,
        value = c(min, max)
    )
}

shinyServer(function(input, output, session) {
    loginfo("initializing...")
    
    data <- load.data()
    
    .update.slider(data, session, "Gravity")
    .update.slider(data, session, "AverageEarningsPerSale")
    .update.slider(data, session, "InitialEarningsPerSale")
    .update.slider(data, session, "PercentPerRebill")
    .update.slider(data, session, "PercentPerSale")
    .update.slider(data, session, "TotalRebillAmt")
    .update.slider(data, session, "Referred")
    .update.slider(data, session, "Commission")
    
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
