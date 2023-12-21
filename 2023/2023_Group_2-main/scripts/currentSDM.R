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

martenDataNotCoords <- read_csv("data/marten.csv") %>% dplyr::select(longitude,latitude)

martenDataSpatialPts <- SpatialPoints(martenDataNotCoords, proj4string = CRS("+proj=longlat"))

currentEnv <- getData("worldclim", var="bio", res=2.5, path="data/")
climList <- list.files(path = "data/wc2-5/", pattern = ".bil$", 
                       full.names = T) 
clim <- raster::stack(climList)

mask <- raster(clim[[1]]) # mask is the raster object that determines the area where we are generating pts

# determine geographic extent of our data (so we generate random points reasonably nearby)
geographicExtent <- extent(x = martenDataSpatialPts)

set.seed(45) # seed set so we get the same background points each time we run this code 
backgroundPoints <- randomPoints(mask = mask, 
                                 n = nrow(martenDataNotCoords), # n should be at least 1000 (even if your sp has fewer than 1000 pts)
                                 ext = geographicExtent, 
                                 extf = 1.25, # draw a slightly larger area than where our sp was found (ask katy what is appropriate here)
                                 warn = 0)
colnames(backgroundPoints) <- c("longitude", "latitude")

occEnv <- na.omit(raster::extract(x = clim, y = martenDataNotCoords))
absenceEnv<- na.omit(raster::extract(x = clim, y = backgroundPoints))

presenceAbsenceV <- c(rep(1, nrow(occEnv)), rep(0, nrow(absenceEnv)))
presenceAbsenceEnvDf <- as.data.frame(rbind(occEnv, absenceEnv))

martenSDM <- dismo::maxent(x = presenceAbsenceEnvDf, ## env conditions
                           p = presenceAbsenceV,   ## 1:presence or 0:absence
                           path=paste("output/maxent_outputs_marten"))

predictExtent <- 1.25 * geographicExtent # choose here what is reasonable for your pts (where you got background pts from)
geographicArea <- crop(clim, predictExtent, snap = "in")

martenPredictPlot <- raster::predict(martenSDM, geographicArea) # predict the model to 

# for ggplot, we need the prediction to be a data frame 
raster.spdf <- as(martenPredictPlot, "SpatialPixelsDataFrame")
martenPredictDf <- as.data.frame(raster.spdf)

wrld <- ggplot2::map_data("world")

xmax <- max(martenPredictDf$x)
xmin <- min(martenPredictDf$x)
ymax <- max(martenPredictDf$y)
ymin <- min(martenPredictDf$y)


ggplot() +
  geom_polygon(data = wrld, mapping = aes(x = long, y = lat, group = group),
               fill = "grey75") +
  geom_raster(data = martenPredictDf, aes(x = x, y = y, fill = layer)) + 
  scale_fill_gradientn(colors = terrain.colors(10, rev = T)) +
  coord_fixed(xlim = c(xmin, xmax), ylim = c(ymin, ymax), expand = F) + # expand = F fixes weird margin
  scale_size_area() +
  borders("world") +
  borders("state")+
  labs(title = expression(paste("SDM of " ,italic("M. caurina"), " Under Current Climate Conditions")),
       x = "longitude",
       y = "latitude",
       fill = "Environmental \nSuitability") + # \n is a line break
  theme(legend.box.background=element_rect(),legend.box.margin=margin(5,5,5,5))
ggsave(filename="currentSDM.jpg", plot=last_plot(), path="output", width=6.14, height=4.84, units="in")
