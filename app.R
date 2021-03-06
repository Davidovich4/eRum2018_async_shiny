library(shiny)
library(promises)
library(future)
library(shinyjs)

plan(multisession)

long_running <- function(delay, value) {
  Sys.sleep(delay)
  value
}

moduleUI <- function(id, delay, sync) {
  ns <- NS(id)
  
  tagList(
    column(3, 
           actionButton(ns("btn"), paste(delay, sync)),
           verbatimTextOutput(ns("txt"))
    )
  )
}

module <- function(input, output, session, delay, sync) {
  observeEvent(input$btn, {
    output$txt <- renderPrint( {
      shinyjs::addClass(id = "txt", class = "green")
      if (sync) {
        long_running(delay, runif(1))
      } else {
        future(long_running(delay = delay, runif(1))) %...>% 
          print() 
      }
    })
  })
}

ui <- fluidPage(
  useShinyjs(),
  inlineCSS(list(
    .green = "background-color: greenyellow",
    .btn = "
      height: 100px;
      width: 200px;
      font-size: 2.5em;
    ",
    ".shiny-text-output" = "
      height: 150px;
      font-size: 2em;
    "
  )),
  tags$head(tags$script("
    $(document).on({
      'shiny:recalculated': function(event) {
        setTimeout(function(){
          $('.shiny-text-output').removeClass('green');
        }, 2000);
      }
    })
  ")),
  moduleUI("m1", 0, "synch"),
  moduleUI("m2", 15, "synch"),
  moduleUI("m3", 3, "asynch"),
  moduleUI("m4", 10, "asynch")
)

server <- function(input, output, session) {
  callModule(module, id = "m1", session = session, delay = 0, sync = T)
  callModule(module, id = "m2", session = session, delay = 15, sync = T)
  callModule(module, id = "m3", session = session, delay = 3, sync = F)
  callModule(module, id = "m4", session = session, delay = 15, sync = F)
}

shinyApp(ui, server)