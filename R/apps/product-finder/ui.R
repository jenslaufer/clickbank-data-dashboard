library(shiny)
library(shinyWidgets)
library(shinythemes)
library(shinycssloaders)
library(DT)


.slider.input <- function(name, title) {
    sliderInput(name,
                title,
                min = 0,
                max = 1,
                value = c(0, 1))
}


.numeric.input <- function(name, title) {
    numericRangeInput(name,
                      title,
                      c(0, 100),
                      width = "100%",
                      separator = " to ")
}

shinyUI(fluidPage(
    theme = shinytheme("cosmo"),
    chooseSliderSkin("Modern", "DimGray"),
    titlePanel("Clickbank Niche Finder"),
    tabsetPanel(
        type = "tabs",
        tabPanel("Property Filtering",
                 fixedRow(
                     column(
                         2,
                         .slider.input("Gravity", "Gravity"),
                         .slider.input("Gravity_Change", "Gravity Change"),
                         .slider.input("PopularityRank", "PopularityRank"),
                         .slider.input("AverageEarningsPerSale", "Average Earnings Per Sale"),
                         .slider.input("InitialEarningsPerSale", "Initial Earnings Per Sale"),
                         .slider.input("PercentPerRebill", "Percent Per Rebill"),
                         .slider.input("PercentPerSale", "Percent Per Sale"),
                         .slider.input("TotalRebillAmt", "Total Rebill Amt"),
                         .slider.input("Referred", "Referred") ,
                         .slider.input("Commission", "Commission"),
                         .slider.input("ActivateDate", "Activation Date")
                     ),
                     column(
                         10,
                         dataTableOutput("products.filtered"),
                         plotOutput("dummy") %>% withSpinner(type = 6)
                     )
                 )),
        
        tabPanel(
            "Plot Filtering",
            fixedRow(column(
                6,
                plotOutput("pcaPlot", brush = "pca.plot.brush") %>% withSpinner(type = 6)
            ),
            column(
                6,
                plotOutput("pcaPlotMagnifier", brush = "pca.plot.brush")
            )),
            dataTableOutput("products.brushed")
        ),
        
        tabPanel(
            "Gravity Change",
            fixedRow(
                column(
                    3,
                    .numeric.input("Gravity_Numeric_Input_Range", "Gravity"),
                    .numeric.input("Gravity_Change_Numeric_Input_Range", "Gravity Change"),
                    .slider.input("GravityChangeActivateDate", "Activate Date")
                ),
                column(9,
                       plotOutput("gravity.change.barchart",  click = "plot_hover"))
            ),
            fixedRow(column(
                9, offset = 3,
                plotOutput("plot.gravity.change.history")
            )),
            dataTableOutput("productsGravityFiltered")
        )
    )
))
