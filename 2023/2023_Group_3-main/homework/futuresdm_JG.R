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
## FUTURE SPECIES SDM
currentEnv <- clim # renaming from the last sdm because clim isn't very specific 

# to see the specifics 
futureEnv <- raster::getData(name = 'CMIP5', var = 'bio', res = 2.5,
                             rcp = 45, model = 'IP', year = 70, path="data") 
# in get data, you can specific with rcp, which is the greenhouse gas emission prediction,
# can also specific which model https://rdrr.io/cran/raster/man/getData.html
# and which year: 50 or 70 years from now

names(futureEnv) = names(currentEnv)

# crop clim to the extent of the map you want
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
  scale_fill_gradientn(colors = terrain.colors(10, rev = T)) +
  coord_fixed(xlim = c(xmin, xmax), ylim = c(ymin, ymax), expand = F) +
  scale_size_area() +
  borders("world") +
  borders("state") +
  labs(title = "SDM of A. levettei Under \nCMIP 5 Climate Conditions",
       x = "longitude",
       y = "latitude",
       fill = "Env Suitability") +
  theme(legend.box.background=element_rect(),legend.box.margin=margin(5,5,5,5)) 

ggsave(filename = "futureSnailSDM.jpg", 
       plot=last_plot(), 
       path = "output", 
       width=1600, 
       height=1000, 
       units="px")
