#packages

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

#This is PREVIOUS stuff from current plot 
#Use this to adjust how zoomed in or out the map is
zoom <- 4
set.seed(45) # seed set so we get the same background points each time we run this code 
backgroundPoints <- randomPoints(mask = mask, 
                                 n = nrow(tortoiseDataNotCoords), # n should be at least 1000 (even if your sp has fewer than 1000 pts)
                                 ext = geographicExtent, 
                                 extf = zoom, # draw a slightly larger area than where our sp was found (ask katy what is appropriate here)
                                 warn = 0) # don't complain about not having a coordinate reference system
# add col names (can click and see right now they are x and y)
colnames(backgroundPoints) <- c("longitude", "latitude")

### Section 3: Collate Env Data and Point Data into Proper Model Formats ### 
# Data for observation sites (presence and background), with climate data
occEnv <- na.omit(raster::extract(x = clim, y = tortoiseDataNotCoords))
absenceEnv<- na.omit(raster::extract(x = clim, y = backgroundPoints))

# Create data frame with presence training data and background points (0 = abs, 1 = pres)
presenceAbsenceV <- c(rep(1, nrow(occEnv)), rep(0, nrow(absenceEnv)))
presenceAbsenceEnvDf <- as.data.frame(rbind(occEnv, absenceEnv)) 


### Section 4: Create SDM with Maxent ### 
# create a new folder called maxent_outputs
tortoiseSDM <- dismo::maxent(x = presenceAbsenceEnvDf, ## env conditions
                             p = presenceAbsenceV,   ## 1:presence or 0:absence
                             path=paste("output/maxent_outputs"), ## folder for maxent output; 
)
#Crop
predictExtent <- zoom*geographicExtent # choose here what is reasonable for your pts (where you got background pts from)
geographicArea <- crop(clim, predictExtent, snap = "in") # 





### OK BACK TO THE FUTURE 
# get climate data 
currentEnv <- clim # renaming from the last sdm because clim isn't very specific

#to set our specific future data
futureEnv <- raster::getData(name = 'CMIP5', var = 'bio', res = 2.5,
                             rcp = 45, model = 'IP', year = 70, path="data") 

names(futureEnv) = names(currentEnv)
# look at current vs future climate vars
plot(currentEnv[[1]])
plot(futureEnv[[1]])


## NOTE: predictExtent is defined in the current tortoise SDM
# crop clim to the extent of the map you want
geographicAreaFutureC5 <- crop(futureEnv, predictExtent)


# predict  model onto future climate
#Note: tortoiseSDM defined in current tortoise SDM
tortoisePredictPlotFutureC5 <- raster::predict(tortoiseSDM, geographicAreaFutureC5)  

# for ggplot, we need the prediction to be a data frame 
#convert output of ranapredictplot to a data frame
raster.spdfFutureC5 <- as(tortoisePredictPlotFutureC5, "SpatialPixelsDataFrame")
tortoisePredictDfFutureC5 <- as.data.frame(raster.spdfFutureC5)

#PLOT IT!!!
wrld <- ggplot2::map_data("world")

# get our lat/lon boundaries
xmax <- max(tortoisePredictDfFutureC5$x)
xmin <- min(tortoisePredictDfFutureC5$x)
ymax <- max(tortoisePredictDfFutureC5$y)
ymin <- min(tortoisePredictDfFutureC5$y)


ggplot() +
  geom_polygon(data = wrld, mapping = aes(x = long, y = lat, group = group),
               fill = "grey75") +
  geom_raster(data = tortoisePredictDfFutureC5, aes(x = x, y = y, fill = layer)) + 
  scale_fill_gradientn(colors = terrain.colors(10, rev = T)) +
  coord_fixed(xlim = c(xmin, xmax), ylim = c(ymin, ymax), expand = F) +
  scale_size_area() +
  borders("world") +
  borders("state") +
  labs(title = "SDM of G. Morafkai Under CMIP 5 Climate Conditions",
       x = "longitude",
       y = "latitude",
       fill = "Env Suitability") +
  theme(legend.box.background=element_rect(),legend.box.margin=margin(5,5,5,5)) 


#Live ggsave here:

ggsave(filename="FuturePlotTortoise.jpg", plot=last_plot(),path="output", width=1600, height=800, units="px")

