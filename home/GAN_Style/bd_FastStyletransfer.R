##### FAST STYLE TRANSFER FUNKCIOKENT

library(tensorflow)
tfe_enable_eager_execution(device_policy = "silent")
tf$executing_eagerly()

library(tfhub)
hub_model = hub_load('https://tfhub.dev/google/magenta/arbitrary-image-stylization-v1-256/2')

library (keras)

img_nrows <- 0
img_ncols <- 0

# Auxilary Functions
preprocess_image <- function(path, Content = TRUE) 
  # model was tested w 256 x 256 styles. Larger the size here weaker the style
{
  TARGET_SIZE <- if (Content) c(img_nrows, img_ncols) else c(256,256)
  img <- image_load(path, target_size = TARGET_SIZE) %>%
    image_to_array() %>%
    array_reshape(c(1, dim(.)))
  img <- img/255  
  #imagenet_preprocess_input(img)
}


deprocess_image <- function(img) {
  img <- keras::array_reshape(img, dim = c(dim(img)[[2]], dim(img)[[3]], 3))
  img <- as.matrix(img)
  img <- img * 255
  img
}

style_it <- function (content_image_path, style_image_path, TB_saved_image_path)
{
  
  img <- image_load(content_image_path)
  
  width <- img$size[[1]]
  height <- img$size[[2]]
  img_nrows <<- 400
  img_ncols <<- as.integer(width * img_nrows / height)
  
  stylized_image = hub_model(tf$cast(tf$constant(preprocess_image(content_image_path)), 
                                     tf$float32), 
                             tf$cast(tf$constant(preprocess_image(style_image_path, FALSE)), 
                                     tf$float32))[[1]]
  
  image_array_save(deprocess_image(stylized_image), TB_saved_image_path)
  
}


# style_it ("/home/teddy/GAN_Style/paplak.jpg", "/home/teddy/GAN_Style/t_rippl-ronai_parkban-festem-lazarinne-t-es-anellat.jpg",
#           "/home/teddy/r_paplak_ripplparkban.png")
