library(shiny)
library(logging)


source("../api.R")

shinyServer(function(input, output, session) {
    loginfo("initializing...")
    
    data <- load.data()
    
    max.gravity <- data %>% pull(Gravity) %>% max()
    min.gravity <- data %>% pull(Gravity) %>% min()
    updateSliderInput(session, "gravity", max = max.gravity, min = min.gravity)
    
    max.avg.earnings <-
        data %>% pull(AverageEarningsPerSale) %>% max()
    min.avg.earnings <-
        data %>% pull(AverageEarningsPerSale) %>% min()
    
    updateSliderInput(session,
                      "average.earnings",
                      max = max.avg.earnings,
                      min = min.avg.earnings)
    
    loginfo("initializing.")
    
    output$products <-
        DT::renderDataTable(
            data %>%
                filter(Gravity >= input$gravity[1] &
                           Gravity <= input$gravity[2]) %>%
                filter(
                    AverageEarningsPerSale >= input$average.earnings[1] &
                        AverageEarningsPerSale <= input$average.earnings[2]
                ) %>% select(Id, Title, PopularityRank, Gravity, AverageEarningsPerSale),
            selection = 'single'
        )
    
    output$gravityPlot <- renderPlot({
        data %>%
            filter(Gravity >= input$gravity[1] &
                       Gravity <= input$gravity[2]) %>%
            filter(
                AverageEarningsPerSale >= input$average.earnings[1] &
                    AverageEarningsPerSale <= input$average.earnings[2]
            ) %>%
            ggplot(aes(
                x = Gravity,
                y = AverageEarningsPerSale,
                color = PopularityRank_bin
            )) +
            geom_point()
        
    })
    
})
