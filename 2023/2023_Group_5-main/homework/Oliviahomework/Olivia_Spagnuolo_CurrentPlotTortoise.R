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

### Section 1: Obtaining and Formatting Occurence / Climate Data ### 

# read occurrence data (stop to talk about camelCase)
tortoiseDataNotCoords <- cleantortoise %>% dplyr::select(longitude,latitude)

# convert to spatial points, necessary for modelling and mapping
tortoiseDataSpatialPts <- SpatialPoints(tortoiseDataNotCoords, proj4string = CRS("+proj=longlat"))

# obtain climate data: use get data only once
currentEnv <- getData("worldclim", var="bio", res=2.5, path="data/") # current data
# see what each variable is here: https://www.worldclim.org/data/bioclim.html#:~:text=The%20bioclimatic%20variables%20represent%20annual,the%20wet%20and%20dry%20quarters).
#?raster::getData

# create a list of the files in wc2-5 filder so we can make a raster stack
climList <- list.files(path = "data/wc2-5/", pattern = ".bil$", 
                       full.names = T)  # '..' leads to the path above the folder where the .rmd file is located

# stacking the bioclim variables to process them at one go
clim <- raster::stack(climList)

plot(clim[[12]]) # show one env layer ( = annual percepitation) (sorry not using ggplot here just for speed)
plot(tortoiseDataSpatialPts, add = TRUE) # looks good, we can see where our data is


### Section 2: Adding Pseudo-Absence Points ### 
# Create pseudo-absence points (making them up, using 'background' approach)
# first we need a raster layer to make the points up on, just picking 1
mask <- raster(clim[[1]]) # mask is the raster object that determines the area where we are generating pts

# determine geographic extent of our data (so we generate random points reasonably nearby)
geographicExtent <- extent(x = tortoiseDataSpatialPts)

# Random points for background (same number as our observed points we will use )

#determine how zoomed in or out the map will be
#set the zoom variable to 1 to zoom the map into Northern Mexico, California, Arizona. 
#set the zoom variable to 2 to zoom out the map a bit more so that you can see the whole area. 
#the max zoom we recommend is 4 which will show the whole US and Mexico. 
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


### Section 5: Plot the Model ###
# first we will make it smaller

predictExtent <- zoom*geographicExtent # choose here what is reasonable for your pts (where you got background pts from)
geographicArea <- crop(clim, predictExtent, snap = "in") # 
# crop clim to the extent of the map you want

tortoisePredictPlot <- raster::predict(tortoiseSDM, geographicArea) # predict the model to 

# for ggplot, we need the prediction to be a data frame 
raster.spdf <- as(tortoisePredictPlot, "SpatialPixelsDataFrame")
tortoisePredictDf <- as.data.frame(raster.spdf)

# plot in ggplot
wrld <- ggplot2::map_data("world")

xmax <- max(tortoisePredictDf$x)
xmin <- min(tortoisePredictDf$x)
ymax <- max(tortoisePredictDf$y)
ymin <- min(tortoisePredictDf$y)

dev.off()
ggplot() +
  geom_polygon(data = wrld, mapping = aes(x = long, y = lat, group = group),
               fill = "grey75") +
  geom_raster(data = tortoisePredictDf, aes(x = x, y = y, fill = layer)) + 
  scale_fill_gradientn(colors = terrain.colors(10, rev = T)) +
  coord_fixed(xlim = c(xmin, xmax), ylim = c(ymin, ymax), expand = F) + # expand = F fixes weird margin
  scale_size_area() +
  borders("state") +
  labs(title = "SDM of G. morafkai Under Current Climate Conditions",
       x = "longitude",
       y = "latitude",
       fill = "Environmental \nSuitability") + # \n is a line break
  theme(legend.box.background=element_rect(),legend.box.margin=margin(5,5,5,5)) 

#save plot to file
#more on ggsave here: https://ggplot2.tidyverse.org/reference/ggsave.html

#Live code ggsave here:
ggsave(filename="CurrentPlotTortoise.jpg", plot=last_plot(),path="output", width=1600, height=800, units="px")

