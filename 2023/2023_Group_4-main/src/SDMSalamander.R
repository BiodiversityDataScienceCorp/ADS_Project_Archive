install.packages("dismo")
install.packages("maptools")
install.packages("rJava")
install.packages("maps")
install.packages("tidyverse") 

library(dismo)
library(maptools)
library(rJava)
library(maps)
library(tidyverse)
#Install packages required for the code


salamanderCSV<-read_csv("data/salamanderData.csv")
salamanderDataNotCoords<-salamanderCSV%>%dplyr::select(longitude,latitude)
salamanderDataSpatialPts <- SpatialPoints(salamanderDataNotCoords, proj4string = CRS("+proj=longlat")) 
#Read in CSV file created in data collection, selected only latitude and longitude columns, turned 
#into Spatial Points data type (Explicit position data type)


currentEnv <- getData("worldclim", var="bio", res=0.5, lon=-121 , lat=46 , path="data/")
climList <- list.files(path = "data/wc2-5/", pattern = ".bil$",full.names = T)
clim <- raster::stack(climList)
#got climate data from WorldClim, created list of all levels of data, stacked into one raster stack called clim. 
#(All climate data for one point represented as one dataframe)

mask <- raster(clim[[1]]) 
#Used a mask to only get a shape of the land
geographicExtent <- extent(x = salamanderDataSpatialPts)
#Found geographic extent of the salamanders

set.seed(45) # seed set so we get the same background points each time we run this code 
backgroundPoints <- randomPoints(mask = mask, n = nrow(salamanderDataNotCoords),
                                 ext = geographicExtent, 
                                 extf = 1.25, # draw a slightly larger area than where our sp was found (ask katy what is appropriate here)
                                 warn = 0)
colnames(backgroundPoints) <- c("longitude", "latitude")
#Generates random pseudoabsence points for MAXENT to use (it requires absence points), by 
#creating a bunch of random points within the mask we created, and also where salamanders aren't
#Names columns longitude and latitude to keep consistent


occEnv <- na.omit(raster::extract(x = clim, y = salamanderDataNotCoords))
absenceEnv<- na.omit(raster::extract(x = clim, y = backgroundPoints))
#Creates rasters where the x value is the climate data and the y values are occurrence and absence points

presenceAbsenceV <- c(rep(1, nrow(occEnv)), rep(0, nrow(absenceEnv)))
presenceAbsenceEnvDf <- as.data.frame(rbind(occEnv, absenceEnv)) 
#Create a vector where occurance is 1 and absence is 0, creates data frame out of those two vectors smushed together

salamanderSDM <- dismo::maxent(x = presenceAbsenceEnvDf, ## env conditions
                         p = presenceAbsenceV,   ## 1:presence or 0:absence
                         path=paste("output/maxent_outputs"))
#Creates an SDM Model using MAXENT using input of the Data frame for environmental data and the vector for occurance data
response(salamanderSDM)
#shows graphs for each variables impact on the SDM


predictExtent <- 2 * geographicExtent #Chooses how big the area we where predict our species is
geographicArea <- crop(clim, predictExtent, snap = "in") #Crops climate data to the prediction area


salamanderPredictPlot <- raster::predict(salamanderSDM, geographicArea) 
raster.spdf <- as(salamanderPredictPlot, "SpatialPixelsDataFrame")
salamanderPredictDf <- as.data.frame(raster.spdf)
#Uses SDM to predict salamander extent within our area based on the climate data in that area
#Turns that prediction into a spatial pixels data frame, turns that SPDF into a regular data frame

wrld <- ggplot2::map_data("world")

xmax <- max(salamanderPredictDf$x)
xmin <- min(salamanderPredictDf$x)
ymax <- max(salamanderPredictDf$y)
ymin <- min(salamanderPredictDf$y)
#downloads map data, sets x/y mins and maxes based on the prediction area

dev.off()#???
ggplot() +
  geom_polygon(data = wrld, mapping = aes(x = long, y = lat, group = group), #Plots world map
               fill = "grey75") +
  geom_raster(data = salamanderPredictDf, aes(x = x, y = y, fill = layer)) + #Plots predicted values on map
  scale_fill_gradientn(colors = terrain.colors(10, rev = T)) + #Changes colors to visualize the predicted values 
  coord_fixed(xlim = c(xmin, xmax), ylim = c(ymin, ymax), expand = F) + # Sets limits, expand = F fixes weird margin
  scale_size_area() +
  borders("state") + #Shows country and state borders
  borders("world")+
  labs(title = "SDM of R.cascadae Under Current Climate Conditions",
       x = "longitude",
       y = "latitude",
       fill = "Environmental \nSuitability") + # \n is a line break
  theme(legend.box.background=element_rect(),legend.box.margin=margin(5,5,5,5)) #Adds labels and a legend box

ggsave(filename="salamanderSDMCurrent.jpg", scale=2, path="output") #Saves map to a jpg 
