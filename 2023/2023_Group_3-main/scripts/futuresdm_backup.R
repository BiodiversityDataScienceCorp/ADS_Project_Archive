#Future SDM Model
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
snailDataNotCoords <- cleanSnail %>%  #select only longitude and latitude 
  dplyr::select(longitude,latitude)

#Convert to spatial points, this is necessary for modelling and mapping
snailDataSpatialPts <- SpatialPoints(snailDataNotCoords, 
                                     proj4string = CRS("+proj=longlat")) 

# load current climate data
if(file.exists("data")){
  dir.create("data/wc2-5")
}else{
  dir.create("data")
  dir.create("data/wc2-5")
}

url<-"https://climatedata.watzekdi.net/bio_2-5m_bil.zip"
destfile<-"data/wc2-5/bio_2-5m_bil.zip"

message("Downloading climate data from WorldClim")
download.file(url, destfile)
message("Extracting current climate data (this may take a moment)")
unzip(zipfile = "data/wc2-5/bio_2-5m_bil.zip", exdir="data/wc2-5/")
file.remove("data/wc2-5/bio_2-5m_bil.zip")

# load future climate data

future<-c("forecast1.zip","forecast2.zip","forecast3.zip","forecast4.zip")

#loops through the future vector, downloads and unzips each file
for (file in future){
  urlFuture<-paste("https://climatedata.watzekdi.net/",file, sep = "")
  destfileFuture<-file
  download.file(urlFuture, destfileFuture)
  message("Extracting future climate data (this may take a moment)")
  unzip(zipfile = file, exdir=".")
  file.remove(file)
}

climList <- list.files(path = "data/wc2-5/", pattern = ".bil$", 
                       full.names = T) #create a list of the files in wc2-5 folder so we can make a raster stack
                       
                       # Stacking the bioclim variables to process them at one go
                       clim <- raster::stack(climList) 
### SECTION 2: Create pseudo-absence points and generate geographic extent for future SDM model ###

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

colnames(backgroundPoints) <- c("longitude", "latitude") # add col names 

# Data for observation sites (presence and background), with climate data
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
predictExtent <- 1.75 * geographicExtent

### SECTION 3 : Use model to predict SDM of A. levettei under CMIP 5 Climate Conditions ###

# This model is prediciting in 70 years based on current greenhouse gas emission trendss 
futureEnv <- raster::getData(name = 'CMIP5', var = 'bio', res = 2.5,
                             rcp = 45, model = 'IP', year = 70, path="data") 

names(future) = names(clim)

# Crop clim to the extent of the map you want
geographicAreaFutureC5 <- crop(futureEnv, predictExtent)

# Predict  model onto future climate
snailPredictPlotFutureC5 <- raster::predict(snailSDM, geographicAreaFutureC5) 

# Convert to a data frame so ggplot can understand
raster.spdfFutureC5 <- as(snailPredictPlotFutureC5, "SpatialPixelsDataFrame")
snailPredictDfFutureC5 <- as.data.frame(raster.spdfFutureC5)

### SECTION 4 : Plot future SDM in ggplot ###
wrld <- ggplot2::map_data("world")

# Adding state variable from map_data to add state labels to SDM
states <- ggplot2::map_data("state")

state_label <- states %>%
  group_by(region) %>%
  summarize(mean_long = mean(range(long)),
            mean_lat = mean(range(lat)))

state_label$region <- str_to_title(state_label$region)

# Produce latitude and longitude boundaries
xmax <- max(snailPredictDfFutureC5$x)
xmin <- min(snailPredictDfFutureC5$x)
ymax <- max(snailPredictDfFutureC5$y)
ymin <- min(snailPredictDfFutureC5$y)

#create futuresdm using ggplot and save to jpg
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
  geom_text(data=state_label, aes(x=mean_long, y=mean_lat, label=region)) +
  theme(legend.box.background=element_rect(),legend.box.margin=margin(5,5,5,5)) 

ggsave(filename = "futureSnailSDM.jpg", 
       plot=last_plot(), 
       path = "output", 
       width=1600, 
       height=1000, 
       units="px")

