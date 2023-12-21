###Obtaining and Formatting Occurrence / Climate Data ### 

# read occurrence data
tortoiseDataNotCoords <- clean.tortoise %>% dplyr::select(longitude,latitude)

# convert to spatial points, necessary for modelling and mapping
tortoiseDataSpatialPts <- SpatialPoints(tortoiseDataNotCoords, proj4string = CRS("+proj=longlat"))

# obtain climate data: use get data only once
currentEnv <- getData("worldclim", var="bio", res=2.5, path="data/") # current data
# see what each variable is here: https://www.worldclim.org/data/bioclim.html#:~:text=The%20bioclimatic%20variables%20represent%20annual,the%20wet%20and%20dry%20quarters).
#?raster::getData

# create a list of the files in wc2-5 filder so we can make a raster stack
climList <- list.files(path = "data/wc2-5/", pattern = ".bil$", 
                       full.names = T)  # '..' leads to the path above the folder where the .rmd file is located

# stack the bioclim variables to process them at one go
clim <- raster::stack(climList)

### Adding Pseudo-Absence Points ### 
# Create pseudo-absence points (making them up, using 'background' approach)
# first we need a raster layer to make the points up on, just picking 1 arbitrarily
mask <- raster(clim[[1]]) # mask is the raster object that determines the area where we are generating pts

# determine geographic extent of our data (so we generate random points reasonably nearby)
geographicExtent <- extent(x = tortoiseDataSpatialPts)

# Make random points for background (same number as our observed points we will use )

#determine how zoomed in (low numbers) or out (higher numbers) the map will be. We recommend 1.5.
  #set the zoom variable to 1.5 to zoom the map into Northern Mexico, California, Arizona. 
  #the max zoom we recommend is 4 which will show the whole US and Mexico. 
zoom <- 1.5
set.seed(45) # seed set so we get the same background points each time we run this code 
backgroundPoints <- randomPoints(mask = mask, 
                                 n = nrow(tortoiseDataNotCoords), #n needs to be at least 1000, which we have!
                                 ext = geographicExtent, 
                                 extf = zoom,
                                 warn = 0) # don't complain about not having a coordinate reference system

# add column names (can click and see right now they are x and y)
colnames(backgroundPoints) <- c("longitude", "latitude")

### Section 3: Collate Environmental Data and Point Data into Proper Model Formats ### 
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


### Plot the Model ###
#adjust the size (extent) of the model
predictExtent <- zoom*geographicExtent 
# crop clim to the extent of the map you want
geographicArea <- crop(clim, predictExtent, snap = "in") # 

# Make the predictive raster model over that area 
tortoisePredictPlot <- raster::predict(tortoiseSDM, geographicArea) 

# for ggplot, we need the prediction to be a data frame 
raster.spdf <- as(tortoisePredictPlot, "SpatialPixelsDataFrame")
tortoisePredictDf <- as.data.frame(raster.spdf)

# plot the model in ggplot
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
  scale_fill_gradientn(colors = terrain.colors(10, rev = T), limits = c(0,1)) +
  coord_fixed(xlim = c(xmin, xmax), ylim = c(ymin, ymax), expand = F) + # expand = F fixes weird margin
  scale_size_area() +
  borders("state") +
  labs(title = "SDM of G. morafkai\nUnder Current Climate\nConditions",
       x = "longitude",
       y = "latitude",
       fill = "Environmental \nSuitability") +# \n is a line break
  theme(legend.box.background=element_rect(),legend.box.margin=margin(5,5,5,5)) 

#save plot to file using ggsave
#(more on ggsave here: https://ggplot2.tidyverse.org/reference/ggsave.html )

ggsave(filename="currentSDM.jpg", plot=last_plot(),path="output", width=1600, height=800, units="px")

