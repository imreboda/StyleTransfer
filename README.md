# StyleTransfer

## What is this

This is a GAN style transfer game project implemented in shiny.

I installed a shiny server on AWS, put up the scripts, and this is what it does:

Go to the shiny page and upload your picture

![Go to page and upload your picture](https://github.com/imreboda/StyleTransfer/blob/main/illustration/steps_12.png?raw=true)


Pick one of the offered style pictures and click on "Click to Style"

![Select a style and "Click to Style"](https://github.com/imreboda/StyleTransfer/blob/main/illustration/steps_34.png?raw=true)


Wait a few seconds and you will get the result. In fact two results are provided, because some "harsher" styles are better when a bit softened (i.e. blurred).

![Wait a few seconds for the result](https://github.com/imreboda/StyleTransfer/blob/main/illustration/steps_5.png?raw=true)


The uploaded file (i.e. the one to be styled) is stored temporarily: between clicking on "Click to Style" and closing the result styled pictures.


## Structure

shiny app responsible for layout: $HOME/shiny/app.R

The routine that does the style transfer: $HOME/GAN_Style/bd_FastStyletransfer.R

Style template pictures: in $HOME/shiny/www/img and their blurred versions are in $HOME/shiny/www/img/blurred. Every picture has its blurred pair, same name just "blur_" appended in front of the original picture name.



## The way it works


### shiny application (app.R)

bd_image_list (): function that collects filename middle part (between two "_"-s in filename). This is for further use, the idea is that maybe some useful tag is included in the filename that could be shown / used.

Calls style_it (), defined in bd_FastStyletransfer.R.


### GAN style transfer (bd_FastStyletransfer.R)


After some image preprocessing uses 'https://tfhub.dev/google/magenta/arbitrary-image-stylization-v1-256/2' for transferring style.

