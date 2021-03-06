library(shiny)
library(logging)
library(DT)
library(glue)
library(lubridate)
library(ggrepel)


source("../api.R")
source("../visualisations.R")

.update.slider <- function(data, session, field, name = field) {
    max <- data %>% pull(field) %>% max(na.rm = TRUE)
    min <-
        data %>% pull(field) %>% min(na.rm = TRUE)
    
    logdebug(".update.slider: min: {min}, max: {max}" %>% glue())
    
    updateSliderInput(
        session,
        name,
        max = max,
        min = min,
        value = c(min, max)
    )
}

.update.numeric.range.input <-
    function(data, session, field, name = field) {
        logdebug(".update.numeric.range.input...")
        max <- data %>% pull(field) %>% max(na.rm = TRUE)
        min <-
            data %>% pull(field) %>% min(na.rm = TRUE)
        
        logdebug(".update.numeric.range.input: min: {min}, max: {max}" %>% glue())
        
        updateNumericRangeInput(session,
                                name,
                                label = "",
                                value = c(min, max))
    }


.table.data <- function(data) {
    data %>%
        select(
            Id,
            Date,
            Title,
            ActivateDate,
            PopularityRank,
            Gravity,
            Gravity_Change_Pct,
            Gravity_Change_Mean_Pct,
            AverageEarningsPerSale,
            InitialEarningsPerSale
        )
}

shinyServer(function(input, output, session) {
    basicConfig(level = 10)
    loginfo("initializing...")

    
    mongo.uri.env.var <- "MONGODB_URI"
    mongo.url <- "mongodb://localhost"
  
    if (Sys.getenv(c(mongo.uri.env.var)) != "") {
      mongo.url <- Sys.getenv(c(mongo.uri.env.var))
    }
    loginfo("mongourl: {mongo.url}" %>% glue())
    data.all <- load.data(mongo.url)
    
    data <- data.all %>%
        filter(`Date` == max(`Date`), !is.na(ParentCategory)) %>%
        filter(!is.infinite(Gravity_Change) &
                   !is.na(Gravity_Change)) %>%
        filter(!is.infinite(Gravity_Change_mean) &
                   !is.na(Gravity_Change_mean)) %>%
        cluster.data() %>%
        mutate(Date = as.Date(Date, origin = "1970-01-01")) %>%
        mutate(Gravity_Change = round(Gravity_Change * 100, 1)) %>%
        mutate(Gravity_Change_mean = round(Gravity_Change_mean * 100, 1)) %>%
        mutate(
            Gravity_Change_Pct = if_else(
                Gravity_Change >= 0,
                "+{Gravity_Change} %" %>% glue(),
                "{Gravity_Change} %" %>% glue()
            )
        )  %>%
        mutate(
            Gravity_Change_Mean_Pct = if_else(
                Gravity_Change_mean >= 0,
                "+{Gravity_Change_mean} %" %>% glue(),
                "{Gravity_Change_mean} %" %>% glue()
            )
        ) %>% 
        arrange(desc(Gravity_Change_mean))
    
    
    
    logdebug(data %>% nrow())
    
    #.update.numeric.range.input(data, session, "Gravity", "Gravity_Numeric_Input_Range")
    .update.slider(data,
                                session,
                                "Gravity_Change_mean",
                                "GravityChangeMean")
    # .update.slider(data,
    #                session,
    #                "ActivateDate",
    #                "GravityChangeActivateDate")
    .update.slider(data, session, "Gravity")
    .update.slider(data, session, "Gravity_Change")
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
    
    pca.brushed.data <- reactive({
        brushedPoints(
            data,
            brush = input$pca.plot.brush,
            xvar = "PC1",
            yvar = "PC2"
        )
    })
    
    gravity.gravity.change.brushed.data <- reactive({
        brushedPoints(
            data,
            brush = input$gravity.gravity.change.brush,
            xvar = "Gravity",
            yvar = "Gravity_Change"
        )
    })
    
    
    
    filtered.data <- reactive({
        result <- data %>%
            filter(Gravity >= input$Gravity[1] &
                       Gravity <= input$Gravity[2]) %>%
            filter(
                Gravity_Change >= input$Gravity_Change[1] &
                    Gravity_Change <= input$Gravity_Change[2]
            ) %>%
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
            ) %>%
            filter(
                ActivateDate >= as.Date(input$ActivateDate[1]) &
                    ActivateDate <= as.Date(input$ActivateDate[2])
            ) %>%
            filter(Referred >= input$Referred[1] &
                       Referred <= input$Referred[2]) %>%
            filter(Commission >= input$Commission[1] &
                       Commission <= input$Commission[2])
        
        result
    })
    
    
    
    filtered.data.gravity <- reactive({
        result <- data %>%
            # filter(
            #     Gravity >= input$Gravity_Numeric_Input_Range[1] &
            #         Gravity <= input$Gravity_Numeric_Input_Range[2]
            # ) %>%
            # filter(
            #     ActivateDate >= as.Date(input$GravityChangeActivateDate[1]) &
            #         ActivateDate <= as.Date(input$GravityChangeActivateDate[2])
            # ) %>%
            filter(
                Gravity_Change_mean >= input$GravityChangeMean[1] &
                    Gravity_Change_mean <= input$GravityChangeMean[2]
            ) 
        
        result
    })
    
    
    selected.product <- reactive({
        result <-
            nearPoints(data,
                       input$plot_hover,
                       xvar = "Gravity_Change",
                       yvar = "Title")
        input$plot_hover
    })
    
    selected.gravity.change.product <- reactive({
        filtered.data.gravity()
    })
    
    
    output$products.filtered <-
        renderDataTable(filtered.data() %>% .table.data())
    
    output$products.brushed <-
        renderDataTable(pca.brushed.data() %>% .table.data())
    
    output$productsGravityFiltered <-
        renderDataTable(filtered.data.gravity() %>% .table.data(), selection = 'single')
    
    output$gravityPlot <- renderPlot({
        filtered.data() %>%
            plot.gravity.averageenarningspersale()
        
    })
    
    output$dummy <- renderPlot({
        NULL
    })
    
    
    output$pcaPlot <- renderPlot({
        data %>%
            mutate(cluster = as.factor(kmeans.cluster)) %>%
            arrange(-Gravity,-AverageEarningsPerSale) %>%
            plot.cluster.scatter()
    })
    
    output$pcaPlotMagnifier <- renderPlot({
        data <- pca.brushed.data()
        data %>%
            mutate(Title = as.character(Title)) %>%
            mutate(selected.title = if_else(
                Gravity %in%
                    (data %>%
                         arrange(desc(Gravity)) %>%
                         head(10) %>% pull(Gravity)),
                Title,
                ""
            )) %>%
            plot.magnifier()
    })
    
    output$gravity.change.barchart <- renderPlot({
        filtered.data.gravity() %>%
            plot.gravity.change.barchart()
    })
    
    output$plot.gravity.change.history <- renderPlot({
        print(selected.product())
        if (length(input$productsGravityFiltered_rows_selected) > 0) {
            product <-
                selected.gravity.change.product() %>% dplyr::slice(input$productsGravityFiltered_rows_selected[1])
            data.all %>%
                filter(is.na(ParentCategory)) %>%
                plot.gravity.change.history(product %>% pull(Id))
        } else{
            NULL
        }
    })
    
    
    output
    
})