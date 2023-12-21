#Homework 6
#Bailie Wynbelt


## SECTION 1: Download and manipulate correct files for snail species

install.packages("spocc")
install.packages("tidyverse") 
install.packages("readr")
library(spocc)
library(tidyverse)
library(readr)

#Pulling data from gbif
snailquery <- occ(query = "Ashmunella levettei", 
                  from = "gbif", 
                  limit = 4000)


#Drill down to get the data 
snail <- snailquery$gbif$data$Ashmunella_levettei


#Finalize the clean data
cleanSnail <- snail %>% 
  filter(latitude != "NA", 
         longitude !="NA") %>% 
  mutate(location = paste(latitude, 
                          longitude, 
                          dateIdentified, 
                          sep = "/")) %>% 
  distinct(location, .keep_all = TRUE)

#writecsv - lat, long, date
cleanSnail2 <- cleanSnail %>% 
  select(latitude, longitude)

utils::write.csv(x = cleanSnail2, file = "data/cleanSnail.csv")

##SECTION 2: Create current SDM

#packages
install.packages("dismo")
install.packages("maptools")
install.packages("rJava")
install.packages("maps")

library(dismo)
library(maptools)
library(rJava)
library(maps)

### Section 2.1: Obtaining and Formatting Occurence / Climate Data ### 

#read occurrence data 
snailDataNotCoords <- cleanSnail %>% 
  dplyr::select(longitude,latitude)

# convert to spatial points, necessary for modelling and mapping
snailDataSpatialPts <- SpatialPoints(snailDataNotCoords, 
                                    proj4string = CRS("+proj=longlat"))

# obtain climate data: use get data only once
currentEnv <- getData("worldclim", var="bio", res=2.5, path="data/") # current data


# create a list of the files in wc2-5 filder so we can make a raster stack
climList <- list.files(path = "data/wc2-5/", pattern = ".bil$", 
                       full.names = T)  

# stacking the bioclim variables to process them at one go
clim <- raster::stack(climList)

### Section 1.2: Adding Pseudo-Absence Points ### 

# mask is the raster object that determines the area where we are generating pts
mask <- raster(clim[[1]]) 

# determine geographic extent of our data 
geographicExtent <- extent(x = snailDataSpatialPts)

#IMPORTANT! There should be at least 1000 background points.
#If your data set has fewer than 1000 background points, replace 'n'
# below, so it reads 'n=1000'

set.seed(45) 
backgroundPoints <- randomPoints(mask = mask, 
                                 n = 1000, 
                                 ext = geographicExtent, 
                                 extf = 1, 
                                 warn = 0)

# add col names (can click and see right now they are x and y)
colnames(backgroundPoints) <- c("longitude", "latitude")

### Section 1.3: Collate Env Data and Point Data into Proper Model Formats ### 
# Data for observation sites (presence and background), with climate data
occEnv <- na.omit(raster::extract(x = clim, y = snailDataNotCoords))
absenceEnv<- na.omit(raster::extract(x = clim, y = backgroundPoints))

# Create data frame with presence training data and background points (0 = abs, 1 = pres)
presenceAbsenceV <- c(rep(1, nrow(occEnv)), rep(0, nrow(absenceEnv)))
presenceAbsenceEnvDf <- as.data.frame(rbind(occEnv, absenceEnv)) 


### Section 1.4: Create SDM with Maxent ### 
# create a new folder called maxent_outputs
snailSDM <- dismo::maxent(x = presenceAbsenceEnvDf, 
                         p = presenceAbsenceV,  
                         path=paste("output/maxent_outputs"),)



### Section 1.5: Plot the Model ###

predictExtent <- 1.25 * geographicExtent 
geographicArea <- crop(clim, predictExtent, snap = "in") 
snailPredictPlot <- raster::predict(snailSDM, geographicArea)  

# for ggplot, we need the prediction to be a data frame 
raster.spdf <- as(snailPredictPlot, "SpatialPixelsDataFrame")
snailPredictDf <- as.data.frame(raster.spdf)

# plot in ggplot
wrld <- ggplot2::map_data("world")

xmax <- max(snailPredictDf$x)
xmin <- min(snailPredictDf$x)
ymax <- max(snailPredictDf$y)
ymin <- min(snailPredictDf$y)

#dev.off() - use if there are errors w/ ggplot (cannot plot)
ggplot() +
  geom_polygon(data = wrld, mapping = aes(x = long, y = lat, group = group),
               fill = "grey75") +
  geom_raster(data = snailPredictDf, aes(x = x, y = y, fill = layer)) + 
  geom_point(data = snailDataNotCoords, aes(x = longitude, y =latitude)) +
  scale_fill_gradientn(colors = terrain.colors(10, rev = T)) +
  coord_fixed(xlim = c(xmin, xmax), ylim = c(ymin, ymax), expand = F) + # expand = F fixes weird margin
  scale_size_area() +
  borders("state") +
  labs(title = "SDM of A. levettei Under Current Climate Conditions",
       x = "longitude",
       y = "latitude",
       fill = "Environmental \nSuitability") + # \n is a line break
  theme(legend.box.background=element_rect(),legend.box.margin=margin(5,5,5,5)) 

#Live code ggsave here:
ggsave(filename = "currentSDM.jpg", 
       plot=last_plot(), 
       path="output", 
       width=1800, 
       height=800, 
       units="px")

## SECTION 3: FUTURE SDM 

# get climate data 
currentEnv <- clim

# to see the specifics 
futureEnv <- raster::getData(name = 'CMIP5', var = 'bio', res = 2.5,
                             rcp = 45, model = 'IP', year = 70, path="data") 

names(futureEnv) = names(currentEnv)

geographicAreaFutureC5 <- crop(futureEnv, predictExtent)


# predict  model onto future climate
snailPredictPlotFutureC5 <- raster::predict(snailSDM, geographicAreaFutureC5)  

# for ggplot, we need the prediction to be a data frame 
raster.spdfFutureC5 <- as(snailPredictPlotFutureC5, "SpatialPixelsDataFrame")
snailPredictDfFutureC5 <- as.data.frame(raster.spdfFutureC5)

# plot in ggplot
wrld <- ggplot2::map_data("world")

# get our lat/lon boundaries
xmax <- max(snailPredictDfFutureC5$x)
xmin <- min(snailPredictDfFutureC5$x)
ymax <- max(snailPredictDfFutureC5$y)
ymin <- min(snailPredictDfFutureC5$y)


ggplot() +
  geom_polygon(data = wrld, mapping = aes(x = long, y = lat, group = group),
               fill = "grey75") +
  geom_raster(data = snailPredictDfFutureC5, aes(x = x, y = y, fill = layer)) +
  geom_point(data = snailDataNotCoords, aes(x = longitude, y =latitude)) +
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


#Live ggsave here:
ggsave(filename = "futureSDM.jpg", 
       plot=last_plot(), 
       path="output", 
       width=1800, 
       height=800, 
       units="px")




