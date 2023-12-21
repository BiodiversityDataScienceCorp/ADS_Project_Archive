install.packages("dismo")
install.packages("maptools")
install.packages("tidyverse")
install.packages("rJava")
install.packages("maps")

library(dismo)
library(maptools)
library(tidyverse)
library(rJava)
library(maps)

currentEnv <- clim  

futureEnv <- raster::getData(name = 'CMIP5', var = 'bio', res = 2.5,
                             rcp = 45, model = 'IP', year = 70, path="data") 

names(futureEnv) = names(currentEnv)

geographicAreaFutureC5 <- crop(futureEnv, predictExtent)


snailPredictPlotFutureC5 <- raster::predict(snailSDM, geographicAreaFutureC5)  

raster.spdfFutureC5 <- as(snailPredictPlotFutureC5, "SpatialPixelsDataFrame")

snailPredictDfFutureC5 <- as.data.frame(raster.spdfFutureC5)

wrld <- ggplot2::map_data("world")


xmax <- max(snailPredictDfFutureC5$x)
xmin <- min(snailPredictDfFutureC5$x) 
ymax <- max(snailPredictDfFutureC5$y) 
ymin <- min(snailPredictDfFutureC5$y)


ggplot() +
  geom_polygon(data = wrld, mapping = aes(x = long, y = lat, group = group),
               fill = "grey75") +
  geom_raster(data = snailPredictDfFutureC5, aes(x = x, y = y, fill = layer)) + 
  scale_fill_gradientn(colors = terrain.colors(10, rev = T)) +
  coord_fixed(xlim = c(xmin, xmax), ylim = c(ymin, ymax), expand = F) +
  scale_size_area() +
  borders("world") +
  borders("state") +
  labs(title = "SDM of A. levettei Under CMIP 5 Climate Conditions",
       x = "longitude",
       y = "latitude",
       fill = "Env Suitability") +
  theme(legend.box.background=element_rect(),legend.box.margin=margin(5,5,5,5)) 

ggsave(filename = "futureSnailSDM.jpg", plot=last_plot(), path="output", width = 2000, 
       height = 1000, units = "px")

