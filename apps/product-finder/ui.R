library(shiny)

shinyUI(fluidPage(
    titlePanel("Clickbank Niche Finder"),
    
    sidebarLayout(
        sidebarPanel(
            sliderInput(
                "gravity",
                "Gravity",
                min = 0,
                max = 1000,
                value = c(0, 1000)
            ),
            sliderInput(
                "average.earnings",
                "Average Earnings Per Sale",
                min = 0,
                max = 100,
                value = c(0, 100)
            )
        ),
        
        mainPanel(plotOutput("gravityPlot"), DT::dataTableOutput("products"))
    )
))
