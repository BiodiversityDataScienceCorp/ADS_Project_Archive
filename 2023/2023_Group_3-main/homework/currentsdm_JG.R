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

#load in snailquery data
snailquery <- occ(query = "Ashmunella levettei", from = "gbif", limit = 4000)

snail <- snailquery$gbif$data$Ashmunella_levettei

cleanSnail <- snail %>% 
  filter(latitude != "NA", longitude != "NA") %>%
  mutate(location = paste(latitude, longitude, dateIdentified, sep = "/")) %>%
  distinct(location, .keep_all = TRUE)

write_csv(cleanSnail, file = "snaildata.csv")

### Section 1: Obtaining and Formatting Occurence / Climate Data ### 

# read occurrence data (stop to talk about camelCase)
snailDataNotCoords <- read_csv("data/snaildata.csv") %>% dplyr::select(longitude,latitude)

# convert to spatial points, necessary for modelling and mapping
snailDataSpatialPts <- SpatialPoints(snailDataNotCoords, proj4string = CRS("+proj=longlat"))


# obtain climate data: use get data only once
currentEnv <- getData("worldclim", var="bio", res=2.5, path="data/") # current data

# create a list of the files in wc2-5 filder so we can make a raster stack
climList <- list.files(path = "data/wc2-5/", pattern = ".bil$", 
                       full.names = T)  # '..' leads to the path above the folder where the .rmd file is located

# stacking the bioclim variables to process them at one go
clim <- raster::stack(climList)

plot(clim[[12]]) # show one env layer ( = annual percepitation) (sorry not using ggplot here just for speed)
plot(snailDataSpatialPts, add = TRUE) # looks good, we can see where our data is

# Create pseudo-absence points (making them up, using 'background' approach)
# first we need a raster layer to make the points up on, just picking 1

mask <- raster(clim[[1]]) # mask is the raster object that determines the area where we are generating pts

# determine geographic extent of our data (so we generate random points reasonably nearby)
geographicExtent <- extent(x = snailDataSpatialPts)

set.seed(45) # seed set so we get the same background points each time we run this code 
backgroundPoints <- randomPoints(mask = mask, 
                                 n = 1000, #n should be at least 1000 (even if your sp has fewer than 1000 pts)
                                 ext = geographicExtent, 
                                 extf = 1.25, # draw a slightly larger area than where our sp was found (ask katy what is appropriate here)
                                 warn = 0) # don't complain about not having a coordinate reference system

# add col names (can click and see right now they are x and y)
colnames(backgroundPoints) <- c("longitude", "latitude")

# Data for observation sites (presence and background), with climate data
occEnv <- na.omit(raster::extract(x = clim, y = snailDataNotCoords))
absenceEnv<- na.omit(raster::extract(x = clim, y = backgroundPoints))

# Create data frame with presence training data and background points (0 = abs, 1 = pres)
presenceAbsenceV <- c(rep(1, nrow(occEnv)), rep(0, nrow(absenceEnv)))
presenceAbsenceEnvDf <- as.data.frame(rbind(occEnv, absenceEnv)) 

# create a new folder called maxent_outputs
snailSDM <- dismo::maxent(x = presenceAbsenceEnvDf, ## env conditions
                          p = presenceAbsenceV,   ## 1:presence or 0:absence
                          path=paste("output/maxent_outputs"), ## folder for maxent output; 
                          # if we do not specify a folder R will put the results in a temp file, 
                          # and it gets messy to read those. . .
)

# clim is huge and it isn't reasonable to predict over whole world
# first we will make it smaller

predictExtent <- 1.25 * geographicExtent # choose here what is reasonable for your pts (where you got background pts from)
geographicArea <- crop(clim, predictExtent, snap = "in") # 
# look at what buffers are, maybe this is where mapping problem is
# crop clim to the extent of the map you want
snailPredictPlot <- raster::predict(snailSDM, geographicArea) # predict the model to 

# for ggplot, we need the prediction to be a data frame 
raster.spdf <- as(snailPredictPlot, "SpatialPixelsDataFrame")
snailPredictDf <- as.data.frame(raster.spdf)

# plot in ggplot
wrld <- ggplot2::map_data("world")

xmax <- max(snailPredictDf$x)
xmin <- min(snailPredictDf$x)
ymax <- max(snailPredictDf$y)
ymin <- min(snailPredictDf$y)

##dev.off()
ggplot() +
  geom_polygon(data = wrld, mapping = aes(x = long, y = lat, group = group),
               fill = "grey75") +
  geom_raster(data = snailPredictDf, aes(x = x, y = y, fill = layer)) + 
  scale_fill_gradientn(colors = terrain.colors(10, rev = T)) +
  coord_fixed(xlim = c(xmin, xmax), ylim = c(ymin, ymax), expand = F) + # expand = F fixes weird margin
  scale_size_area() +
  borders("state") +
  labs(title = "SDM of A. levettei Under \nCurrent Climate Conditions",
       x = "longitude",
       y = "latitude",
       fill = "Environmental \nSuitability") + # \n is a line break
  theme(legend.box.background=element_rect(),legend.box.margin=margin(5,5,5,5)) 

ggsave(filename = "currentsnailSDM.jpg", 
       plot=last_plot(), 
       path = "output", 
       width=1600, 
       height=1000, 
       units="px")