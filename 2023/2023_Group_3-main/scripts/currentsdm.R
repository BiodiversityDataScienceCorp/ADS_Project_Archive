#Current SDM Model
#03/18/2023
#Synthesized from team member's individual scripts
#Bailie Wynbelt, Hailey Park, Zoe Evans, Josie Graydon

### CONSIDERATIONS ###
#To run this script using posit cloud the RAM requirements need to be at least 5 GB

### SECTION 1: Download/load required packages and read in clean snail data ###

install.packages("dismo")
install.packages("maptools")
install.packages("tidyverse")
install.packages("rJava")
install.packages("maps")
install.packages("spocc")

library(dismo)
library(maptools)
library(tidyverse)
library(rJava)
library(maps)
library(spocc)

cleanSnail <- read_csv("data/snaildata.csv")

### SECTION 2: Prepare data for plotting ###
snailDataNotCoords <- cleanSnail %>%  #select only longitude and latitude using the select() function
  dplyr::select(longitude,latitude)

# Convert to spatial points, this is necessary for modelling and mapping
snailDataSpatialPts <- SpatialPoints(snailDataNotCoords, 
                                     proj4string = CRS("+proj=longlat")) 

# Obtain climate data required for plotting current SDM ~ using worldclim
currentEnv <- getData("worldclim", var="bio", res=2.5, path="data/") 

# Create a list of the files in wc2-5 folder so we can make a raster stack
climList <- list.files(path = "data/wc2-5/", pattern = ".bil$", 
                       full.names = T) #create a list of the files in wc2-5 folder so we can make a raster stack

# Stacking the bioclim variables to process them at one go
clim <- raster::stack(climList) 


### SECTION 3: Create pseudo-absence points and generate geographic extent for SDM model ###

# Mask is the raster object that determines the area where we are generating pts
mask <- raster(clim[[1]])

# Determine geographic extent of our data (so we generate random points reasonably nearby)
geographicExtent <- extent(x = snailDataSpatialPts) 

set.seed(45) # seed set so we get the same background points each time we run this code 
backgroundPoints <- randomPoints(mask = mask, 
                                 n = 1000, 
                                 ext = geographicExtent, 
                                 extf = 1.25, 
                                 warn = 0) 

colnames(backgroundPoints) <- c("longitude", "latitude") # add column names 

# Get data for observation sites (presence and background) using climate data
occEnv <- na.omit(raster::extract(x = clim, y = snailDataNotCoords))
absenceEnv<- na.omit(raster::extract(x = clim, y = backgroundPoints))

# Create data frame with presence training data and background points (0 = abs, 1 = pres)
presenceAbsenceV <- c(rep(1, nrow(occEnv)), rep(0, nrow(absenceEnv)))
presenceAbsenceEnvDf <- as.data.frame(rbind(occEnv, absenceEnv)) 

# Create a new folder called maxent_outputs
snailSDM <- dismo::maxent(x = presenceAbsenceEnvDf, 
                          p = presenceAbsenceV, 
                          path=paste("output/maxent_outputs"), )

# Create geographic extent points
predictExtent <- 3 * geographicExtent

# Crop clim to the extent of the map
geographicArea <- crop(clim, predictExtent, snap = "in")

# Predict geographic area
snailPredictPlot <- raster::predict(snailSDM, geographicArea)

# Convert prediction into a data frame
raster.spdf <- as(snailPredictPlot, "SpatialPixelsDataFrame")
snailPredictDf <- as.data.frame(raster.spdf)

### SECTION 4: Plot current SDM in ggplot ###
wrld <- ggplot2::map_data("world")

# Adding state variable from map_data to add state labels to SDM
states <- ggplot2::map_data("state")

# clean up labels so state names are spelled out and in title case
state_label <- states %>%
  group_by(region) %>%
  summarize(mean_long = mean(range(long)),
            mean_lat = mean(range(lat)))

state_label$region <- str_to_title(state_label$region)

# Produce latitude and longitude boundaries
xmax <- max(snailPredictDf$x)
xmin <- min(snailPredictDf$x)
ymax <- max(snailPredictDf$y)
ymin <- min(snailPredictDf$y)

##dev.off() #use if ggplot is not working, otherwise this is not needed

#create currentsdm using ggplot and save to jpg
ggplot() +
  geom_polygon(data = wrld, mapping = aes(x = long, y = lat, group = group),
               fill = "grey75") +
  geom_raster(data = snailPredictDf, aes(x = x, y = y, fill = layer)) + 
  scale_fill_gradientn(colors = terrain.colors(10, rev = T)) +
  coord_fixed(xlim = c(xmin, xmax), ylim = c(ymin, ymax), expand = F) + # expand = F fixes weird margin
  scale_size_area() +
  borders("state") +
  geom_text(data=state_label, aes(x=mean_long, y=mean_lat, label=region)) +
  labs(title = "SDM of A. levettei Under \nCurrent Climate Conditions",
       x = "longitude",
       y = "latitude",
       fill = "Environmental \nSuitability") + # \n is a line break +
  geom_text(data=state_label, aes(x=mean_long, y=mean_lat, label=region)) +
  theme(legend.box.background=element_rect(),legend.box.margin=margin(5,5,5,5)) 

# save the map as an image
ggsave(filename = "currentsnailSDM.jpg", 
       plot=last_plot(), 
       path = "output", 
       width=1600, 
       height=1000, 
       units="px")
