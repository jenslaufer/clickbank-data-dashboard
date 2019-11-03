library(shiny)


.slider.input <- function(name, title) {
    sliderInput(name,
                title,
                min = 0,
                max = 100,
                value = c(0, 100))
}

shinyUI(fluidPage(
    titlePanel("Clickbank Niche Finder"),
    
    sidebarLayout(
        sidebarPanel(
            .slider.input("Gravity", "Gravity"),
            .slider.input("AverageEarningsPerSale", "Average Earnings Per Sale"),
            .slider.input("InitialEarningsPerSale", "Initial Earnings Per Sale"),
            .slider.input("PercentPerRebill", "Percent Per Rebill"),
            .slider.input("PercentPerSale", "Percent Per Sale"),
            .slider.input("TotalRebillAmt", "Total Rebill Amt"),
            .slider.input("Referred", "Referred") ,
            .slider.input("Commission", "Commission")
        ),
        
        mainPanel(plotOutput("gravityPlot"), DT::dataTableOutput("products"))
    )
))
