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


#Query for Gopherus morafkai (Sonoran desert tortoise) data from GBIF, with a limit of 4000.
tortoiseQuery <- occ(query = "Gopherus morafkai", from="gbif", limit = 4000)
tortoiseQuery

tortoise <- tortoiseQuery$gbif$data$Gopherus_morafkai

#cleaning data...
clean.tortoise <- tortoise %>%
  filter(latitude != "NA", longitude != "NA") %>%
  #Removing duplicates
  mutate(location = paste(latitude, longitude, dateIdentified, sep = "/")) %>%
  distinct(location, .keep_all = TRUE) %>%
  filter(occurrenceStatus == "PRESENT")

#read occurence data and convert to spatial points for mapping and modeling
tortoiseDataNotCoords <- clean.tortoise %>% dplyr::select(longitude,latitude)
tortoiseDataSpatialPts <- SpatialPoints(tortoiseDataNotCoords, proj4string = CRS("+proj=longlat"))


#get climate data
currentEnv <- getData("worldclim", var="bio", res=2.5, path="data/") # current data

#create list of files then make raster stack of bioclim variables
climList <- list.files(path = "data/wc2-5/", pattern = ".bil$", 
                       full.names = T)
clim <- raster::stack(climList)

#create psuedo-absence points
mask <- raster(clim[[1]])

#determine geographic extent of data
geographicExtent <- extent(x = tortoiseDataSpatialPts)

#set seed for replicable results
set.seed(45)
backgroundPoints <- randomPoints(mask = mask, 
                                 n = nrow(tortoiseDataNotCoords),
                                 ext = geographicExtent, 
                                 extf = 1.25, 
                                 warn = 0)

#add column names
colnames(backgroundPoints) <- c("longitude", "latitude")

#collate env data and point data into model formats
occEnv <- na.omit(raster::extract(x = clim, y = tortoiseDataNotCoords))
absenceEnv<- na.omit(raster::extract(x = clim, y = backgroundPoints))

# Create data frame with presence training data and background points (0 = abs, 1 = pres)
presenceAbsenceV <- c(rep(1, nrow(occEnv)), rep(0, nrow(absenceEnv)))
presenceAbsenceEnvDf <- as.data.frame(rbind(occEnv, absenceEnv)) 

# create a new folder called maxent_outputs
tortoiseSDM <- dismo::maxent(x = presenceAbsenceEnvDf, ## env conditions
                         p = presenceAbsenceV,   ## 1:presence or 0:absence
                         path=paste("output/maxent_outputs"), ## folder for maxent output; 
                         # if we do not specify a folder R will put the results in a temp file, 
                         # and it gets messy to read those. . .
                         
)

#set extent
predictExtent <- 1.25 * geographicExtent
geographicArea <- crop(clim, predictExtent, snap = "in")
tortoisePredictPlot <- raster::predict(tortoiseSDM, geographicArea)

#data->dataframe for ggplot
raster.spdf <- as(tortoisePredictPlot, "SpatialPixelsDataFrame")
tortoisePredictDf <- as.data.frame(raster.spdf)

#plot in ggplot
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
  labs(title = "SDM of G. morafkai \nUnder Current \nClimate Conditions",
       x = "longitude",
       y = "latitude",
       fill = "Environmental \nSuitability") + # \n is a line break
  theme(legend.box.background=element_rect(),legend.box.margin=margin(5,5,5,5)) 

ggsave(filename = "currentSDM.jpg", plot = last_plot(), path = "output", width = 1200, height = 800, units = "px")
#saved current SDM in ouput folder!

#Future SDM...
#get climate data again
currentEnv <- clim
futureEnv <- raster::getData(name = 'CMIP5', var = 'bio', res = 2.5,
                             rcp = 45, model = 'IP', year = 70, path="data") 
#middle of the road greenhouse gas prediction, 70 years from now.

#future names should be the same as current names..
names(futureEnv) = names(currentEnv)
#crop area to the extent we want
geographicAreaFutureC5 <- crop(futureEnv, predictExtent)

#predict model -> future climate
tortoisePredictPlotFutureC5 <- raster::predict(tortoiseSDM, geographicAreaFutureC5)

#convert raster to data frame for ggplot
raster.spdfFutureC5 <- as(tortoisePredictPlotFutureC5, "SpatialPixelsDataFrame")
tortoisePredictDfFutureC5 <- as.data.frame(raster.spdfFutureC5)

#plot in ggplot and save
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
  labs(title = "SDM of G. morafkai \nUnder Future \nClimate Conditions",
       x = "longitude",
       y = "latitude",
       fill = "Env Suitability") +
  theme(legend.box.background=element_rect(),legend.box.margin=margin(5,5,5,5)) 

ggsave(filename = "futureSDM.jpg", 
       plot = last_plot(), path = "output", 
       width = 1200, height = 800,
       units = "px")
