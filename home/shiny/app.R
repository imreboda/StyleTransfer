#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#


# mi van ebben
#
# kitesz kepeket grid-ben es megerti ha rajuk klikkel valaki
# F1.-el jelolt reszek vegzik a kepek kiteveset grid-ben es a raklikkeles elkapasat. 
#
# beolvas egy file-t a kliens pc-rol
# F2.-el jelolt reszek vegzik a beolvasast es a kivalasztott kep megjeleniteset
#
# Action button-t tilt amig nincs style es file kivalasztva, illetve letilt a style transfer idejere
# F3.-al jelolt reszek vegzik az Action Button tiltast / engedelyezest
#




library(shiny)
library(shinyjs)   #for enable / disable action button and clickable picture grid
library(shinythemes)
library (tidyr)
library(tableHTML)
library (dplyr)
library(keras)

# Include the script that does the fast neural style transfer
source ('$HOME/GAN_Style/bd_FastStyletransfer.R')

if (names(dev.cur()) != "null device") dev.off()
pdf(NULL)

image_dir <- '/$HOME/shiny/www/img'

# below needed to present the style images in the grid 
# use later in code part "tags$img(src=paste0("image_dir", "/", img)..."
addResourcePath(prefix = 'image_dir', directoryPath = image_dir)

bd_image_list <- function (shiny_dir)
# list files in a dataframe (src column)
# text processing for possible future use: second part after "_" collected in text column/ 
{
  partx <- function (words, place)
  {
    ifelse (length(words) < place, "", words[place])
  }
    
  data.frame (src = list.files (shiny_dir, pattern = "*.jpg|png"),stringsAsFactors = FALSE) %>% 
    mutate (txt = sapply (strsplit(src, "_"), function(x) partx(x,2)))
}
images <<- bd_image_list (image_dir)


###################################################
### shiny ui part
ui <- fluidPage(theme = shinytheme("superhero"),
                
                #F3.
                useShinyjs(),    
                
                ### Main Window - Application title
                titlePanel(withTags(
                    div("Style your photo",
                        div(class = 'pull-right',
                            a(href = 'https://github.com/mrjoh3/shiny-gallery-example',
                              icon('github'))), hr() )
                                    ), 
                    windowTitle = "Styler"
                          ),
                
                
                sidebarLayout(     
                    ### Left panel: read user's file. 
                    ### Consists of: textOutput: SideTitle, fileInput: myFile, actionButton: do
                    sidebarPanel
                    (
                        tags$style(make_css(list('.well', 'border-width', '4px'))),
                        h3(textOutput("SideTitle")),
                        #F2.
                        fluidRow( 
                            fileInput("myFile", "", accept = c('image/png', 'image/jpeg'))
                        ),
                        
                        actionButton("do", "Click to Style", class = "btn-success btn-lg"),
                        
                        
                        #F2.
                        div(id = "image-container", style = "display:flexbox"),
                        width = 3
                    ),
                    
                    ### Main panel: shows style pictures and lets user to select from 
                    ### Consists of: textOutput: MainTitle, fileInput: myFile, actionButton: do
                    mainPanel 
                    (
                        HTML( paste('<br/>', h3(textOutput("MainTitle")))),  #add newline before title
                        textOutput("text2"),
                         
                        # F1. Ez teszi ki a kepeket az UI oldalon es elkapja a click-eket (JS)
                        uiOutput("imageGrid"),
                        tags$script(HTML(
                            "$(document).on('click', '.clickimg', function() {",
                            "  Shiny.onInputChange('clickimg', $(this).data('value'));",
                            "});"
                        )),
                        width = 8
                      )
                ) # end of sidebarLayout
)  # end of ui (fluidPage)


###################################################
### Server part
server <- function(input, output, session) {
    temp_save_fname <- NULL   # temporarily storing the styled file (in www subdir otherwise shiny would not present)
    temp_save_fname_blur <- NULL   # temporarily storing the styled file (in www subdir otherwise shiny would not present)
    output$MainTitle <- renderText("Pick your style")
    output$SideTitle <- renderText("Pick your file")
    
    
    # F1. Ez teszi ki a kepeket a server oldalon es engedi a click input-ot a kepeken
    output$imageGrid <- renderUI({
        fluidRow(
            lapply(images$src, function(img) {
                column(3, style='padding:25px;',
                       tags$img(src=paste0("image_dir", "/", img), class="clickimg", 
                                'data-value'=img, width = "200px", height = "200px")
                      )
                })
              )
    })
    
    
    
    # F1. Ez kezeli a click-elest: elkapja a kep nevet es itt valtoztat a text2 output-on 
    output$text2 <- reactive({  
        x <- input$clickimg  
        ifelse (is.null(x), "No style selected", x)
    })
    

    # F2. reads user's file from user's laptop (file to be styled)
    observeEvent(input$myFile, {
        inFile <- input$myFile
        if (is.null(inFile) )
            return()
        
        b64 <- base64enc::dataURI(file = inFile$datapath, mime = "image/png")
        img <- image_load(inFile$datapath)
        
        insertUI(
            selector = "#image-container",
            where = "afterBegin",
            ui = img(src = b64, width = 250)
        )
        
    })   # end of observeEvent input$myFile
    
    
    # F3. Enable "Click to style" action button only after file and style selected
    observe({
        if(is.null(input$myFile) || is.null(input$clickimg)){
            disable("do")
        }
        else{
            enable("do")
        }
    })
    
    
    # Disable file input after it is selected (to avoid showing multiple file pictures)    
    observe({
        if(is.null(input$myFile)) enable("myFile") else disable ("myFile")
    })
    
    
    # clicking on the "Click to Style" button
    observeEvent(input$do, {
        
        # disable "Click to Style" button in order not to allow multiple clicks while styling
        disable("do")
        
        # do the fast style transfer: original_pic, style_pic, file_to_save 
        temp_save_fname <<- gsub("/","", input$myFile$datapath)
        temp_save_fname_blur <<- paste0("bd_", temp_save_fname)
        style_it(input$myFile$datapath, 
                 file.path(image_dir,input$clickimg), 
                 file.path ("/home/teddy/shiny/www", temp_save_fname))
        style_it(input$myFile$datapath, 
                 file.path(image_dir,"blurred", paste0("blur_", input$clickimg)), 
                 file.path ("/home/teddy/shiny/www", temp_save_fname_blur))
        
        # draw pic
        showModal(modalDialog(
            title = "Your Image",
            "Here is the converted image with strong and light style transfers",
            renderUI({tags$div(img(src = temp_save_fname, width = 400), img(src = temp_save_fname_blur, width = 400))}),
            size="l",
            fade=F,
            easyClose = FALSE,
            footer=actionButton("StyledPopClose", "CLOSE")
        ))
    })
    
    
    # catch modal (child window) close button. -> close modal, remove styled file, reload session
    observeEvent(input$StyledPopClose, {
        removeModal()
        file.remove(file.path ("$HOME/shiny/www", temp_save_fname))
        file.remove(file.path ("$HOME/shiny/www", temp_save_fname_blur))
        # re-start the entire process
        session$reload()
    })

}   # end of server

shinyApp(ui, server)
