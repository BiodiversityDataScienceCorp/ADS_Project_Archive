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


GophDataNotCoords <- cleanTortoise %>% dplyr::select(longitude,latitude)

GophDataSpatialPts <- SpatialPoints(GophDataNotCoords, proj4string = CRS("+proj=longlat"))

currentEnv <- getData("worldclim", var="bio", res=2.5, path="data/") 

climList <- list.files(path = "data/wc2-5/", pattern = ".bil$", full.names = T)  


clim <- raster::stack(climList)

plot(GophDataSpatialPts, add = TRUE)

mask <- raster(clim[[1]]) 

geographicExtent <- extent(x = GophDataSpatialPts)


set.seed(45) 
backgroundPoints <- randomPoints(mask = mask, 
                                 n = nrow(GophDataNotCoords),
                                 ext = geographicExtent, 
                                 extf = 1.25, 
                                 warn = 0) 


colnames(backgroundPoints) <- c("longitude", "latitude")

occEnv <- na.omit(raster::extract(x = clim, y = GophDataNotCoords))
absenceEnv<- na.omit(raster::extract(x = clim, y = backgroundPoints))

presenceAbsenceV <- c(rep(1, nrow(occEnv)), rep(0, nrow(absenceEnv)))
presenceAbsenceEnvDf <- as.data.frame(rbind(occEnv, absenceEnv)) 


GophSDM <- dismo::maxent(x = presenceAbsenceEnvDf, 
                         p = presenceAbsenceV,  
                         path=paste("output/maxent_outputs"))

predictExtent <- 1.25 * geographicExtent
geographicArea <- crop(clim, predictExtent, snap = "in") 

GophPredictPlot <- raster::predict(GophSDM, geographicArea) 

raster.spdf <- as(GophPredictPlot, "SpatialPixelsDataFrame")
GophPredictDf <- as.data.frame(raster.spdf)

wrld <- ggplot2::map_data("world")

xmax <- max(GophPredictDf$x)
xmin <- min(GophPredictDf$x)
ymax <- max(GophPredictDf$y)
ymin <- min(GophPredictDf$y)

dev.off()
ggplot() +
  geom_polygon(data = wrld, mapping = aes(x = long, y = lat, group = group),
               fill = "grey1") +
  geom_raster(data = GophPredictDf, aes(x = x, y = y, fill = layer)) + 
  scale_fill_gradientn(colors = terrain.colors(10, rev = T)) +
  coord_fixed(xlim = c(xmin, xmax), ylim = c(ymin, ymax), expand = F) + 
  scale_size_area() +
  borders("state") +
  labs(title = "SDM of G. morafkai Under 
Current Climate Conditions",
       x = "longitude",
       y = "latitude",
       fill = "Environmental \nSuitability") + 
  theme(legend.box.background=element_rect(),legend.box.margin=margin(5,5,5,5)) 

ggsave(filename = "currentSDM.jpg", plot=last_plot(),path="output", width=2000, height=900, units="px")
