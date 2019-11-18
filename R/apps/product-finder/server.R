library(shiny)
library(logging)
library(DT)
library(glue)
library(lubridate)
library(ggrepel)


source("../api.R")

.update.slider <- function(data, session, field) {
    max <- data %>% pull(field) %>% max(na.rm = TRUE) + 1
    min <-
        data %>% pull(field) %>% min(na.rm = TRUE) - 1
    
    logdebug("min: {min}, max: {max}" %>% glue)
    
    updateSliderInput(
        session,
        field,
        max = max,
        min = min,
        value = c(min, max)
    )
}

shinyServer(function(input, output, session) {
    basicConfig(level = 10)
    loginfo("initializing...")
    
    data <- load.data()
    logdebug(data %>% nrow())
    
    .update.slider(data, session, "Gravity")
    .update.slider(data, session, "PopularityRank")
    .update.slider(data, session, "AverageEarningsPerSale")
    .update.slider(data, session, "InitialEarningsPerSale")
    .update.slider(data, session, "PercentPerRebill")
    .update.slider(data, session, "PercentPerSale")
    .update.slider(data, session, "TotalRebillAmt")
    .update.slider(data, session, "Referred")
    .update.slider(data, session, "Commission")
    .update.slider(data, session, "ActivateDate")
    
    
    loginfo("initializing.")
    
    brushed.data <- reactive({
        brushedPoints(
            data %>%
                filter(`Date` == max(`Date`), is.na(ParentCategory)),
            brush = input$pca.plot.brush,
            xvar = "PC1",
            yvar = "PC2"
        )
    })
    
    filtered.data <- reactive({
        data %>%
            filter(`Date` == max(`Date`), is.na(ParentCategory)) %>%
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
            filter(
                PopularityRank >= input$PopularityRank[1] &
                    PopularityRank <= input$PopularityRank[2]
            )  %>%
            filter(
                ActivateDate >= as.Date(input$ActivateDate[1]) &
                    ActivateDate <= as.Date(input$ActivateDate[2])
            ) %>%
            filter(Referred >= input$Referred[1] &
                       Referred <= input$Referred[2]) %>%
            filter(Commission >= input$Commission[1] &
                       Commission <= input$Commission[2])
    })
    
    
    output$products.filtered <-
        renderDataTable(
            filtered.data() %>%
                mutate(cluster = as.factor(kmeans.cluster)) %>%
                select(
                    Id,
                    cluster,
                    Date,
                    Title,
                    ActivateDate,
                    PopularityRank,
                    Gravity,
                    AverageEarningsPerSale,
                    InitialEarningsPerSale
                )
        )
    
    output$products.brushed <-
        renderDataTable(
            brushed.data() %>%
                mutate(cluster = as.factor(kmeans.cluster)) %>%
                select(
                    Id,
                    cluster,
                    Title,
                    Date,
                    ActivateDate,
                    PopularityRank,
                    Gravity,
                    AverageEarningsPerSale,
                    InitialEarningsPerSale
                )
        )
    
    output$gravityPlot <- renderPlot({
        filtered.data() %>%
            ggplot(aes(
                x = Gravity,
                y = AverageEarningsPerSale,
                color = PopularityRank_bin
            )) +
            geom_point()
        
    })
    
    output$dummy <- renderPlot({
        NULL
    })
    
    output$pcaPlot <- renderPlot({
        data %>%
            mutate(cluster = as.factor(kmeans.cluster)) %>%
            arrange(-Gravity, -AverageEarningsPerSale) %>%
            ggplot(aes(
                x = PC1,
                y = PC2,
                color = cluster
            )) +
            geom_point(alpha = 0.6, size = 2) +
            scale_color_tableau()
    })
    
    output$pcaPlotMagnifier <- renderPlot({
        data <- brushed.data()
        data <-
            data %>%
            mutate(Title = as.character(Title)) %>%
            mutate(selected.title = if_else(
                Gravity %in%
                    (
                        data %>%
                            arrange(-Gravity) %>%
                            head(10) %>% pull(Gravity)
                    ),
                Title,
                ""
            ))
        
        
        data %>%
            mutate(cluster = as.factor(kmeans.cluster)) %>%
            arrange(-Gravity, -AverageEarningsPerSale) %>%
            ggplot(aes(
                x = PC1,
                y = PC2,
                color = cluster
            )) +
            geom_point(alpha = 0.6, size = 2) +
            geom_label_repel(aes(label = selected.title)) +
            scale_color_tableau()
    })
    
})