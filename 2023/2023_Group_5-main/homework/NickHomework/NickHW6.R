## Some useful notes:
# Requirements for posit.cloud
# expand allowed RAM use to at least 5GB
# In project file, select NO for all fields in General

#~~Section A: packages+misc.~~#
# step one: installing packages:
install.packages("dismo")
install.packages("maptools")
install.packages("tidyverse")
install.packages("rJava")
install.packages("maps")
install.packages("spocc")
# Step two: calling them into library
library(dismo)
library(maptools)
library(tidyverse)
library(rJava)
library(maps)
library(spocc)

## Heading:
# animal: Sonoran Desert Tortoise
# scientific name: Gopherus morafkai

#~~Section B: occurrence data~~#
## Step one: getting the occurence data from gbif
# searching gbif:
myquery <- occ(query='Gopherus morafkai', from=c('gbif'), limit=4000)
myquery
# drilling down in the data --ignoring the other databases:
morafkai<-myquery$gbif$data$Gopherus_morafkai

## Step two: cleaning occurrence data:
# removing N/A points:
noNApoints <- morafkai %>% filter (latitude != "NA", longitude !="NA")
#making all occurrence points be the "present" ones:
occurrencePresent <- filter(noNApoints, occurrenceStatus == "PRESENT")
# deleting duplicates, but making a new column first (not sure why is necessary):
# making new column:
noDuplicates <- occurrencePresent %>% mutate(location = paste 
                                             (latitude, longitude, dateIdentified, sep = "/") )
# getting rid of duplicates (not really sure why, but now i need --
#... a new noDuplicates variable, but still using this column):
cleanTortoise <- noDuplicates %>% distinct(location, .keep_all = TRUE)

#~~Section C: SDMs (prep, calculations, and mapping)~~#
#Part i: current SDM~~

## Step one: bringing in that previous data --just in case?
# (not sure if I need to do this if the occurrence query/cleaning,
#... CurrentSDM, and FutureSDM are all on the same Rscript file, but just in case):
# read occurrence data, do long/lat stuff:
tortoiseDataNotCoords <- cleanTortoise %>% dplyr::select(longitude,latitude)
# convert to spatial points, (necessary for modelling and mapping):
tortoiseDataSpatialPts <- SpatialPoints(tortoiseDataNotCoords, proj4string = CRS("+proj=longlat"))

## Step two: climate data --obtaining, formatting
# obtain climate data (note: use "get data" only once):
currentEnv <- getData("worldclim", var="bio", res=2.5, path="data/") 
# ^^this is the current climate data and we've named it with a new variable
# data should have been directed to the new "data" folder
# create a list of the files in wc2-5 folder, so as to make a raster stack:
climList <- list.files(path = "data/wc2-5/", pattern = ".bil$",
                       full.names = T)  
# stacking the bioclim variables to process them at one go
clim <- raster::stack(climList)

## Step three: preparing for making the current SDM
# adding pseudo-absence points: we are making them up, using 'background' approach)
# (first we need a raster layer to make the points up on, just picking 1 for example)
# (mask is used for reasons i don't quite understand but it doesn't matter)
mask <- raster(clim[[1]]) 
# determining geographic extent of our data-- 
#this is so the random points generated are reasonably nearby...
geographicExtent <- extent(x = tortoiseDataSpatialPts)
#Random points for background should be same number as our observed points 
#There should be at least 1000 background points.
#If your data set has fewer than 1000 background points, replace 'n'
# ...below, so it reads 'n=1000' (i didn't need to do this though)
set.seed(45) # seed set so the same background points are used... 
#...each time this code is run.
#making these background points now:
backgroundPoints <- randomPoints(mask = mask,
                                 n = nrow(tortoiseDataNotCoords), # n should be at least 1000 (even if sp has fewer than 1000 pts)
                                 ext = geographicExtent,
                                 extf = 1.25, #slightly larger area than where morafkai is found
                                 warn = 0) 
# add column names for the background points (since right now the names are x and y)... 
#...that are more descriptive --I said latitude and longitude for obvious reasons:
colnames(backgroundPoints) <- c("longitude", "latitude")

## Step 4: Collating Environmental Data and Point Data into Proper Model Formats.
# combining (?) data for observation sites (presence and background), with climate data:
# (gonna be honest, I don't really understand the next couple of lines.)
occEnv <- na.omit(raster::extract(x = clim, y = tortoiseDataNotCoords)) #uses the actual occurrence data
absenceEnv<- na.omit(raster::extract(x = clim, y = backgroundPoints)) #uses the background points
# that above will likely take a while, must be a lot of processing power going on there
# was it also omitting N/A points? seems like it must have been, given the "na.omit"

# create a data frame with presence training data and background points (0 = abs, 1 = pres)
presenceAbsenceV <- c(rep(1, nrow(occEnv)), rep(0, nrow(absenceEnv))) 
#reformatting and combining something --the occurrence and background points? 
#making 'em 0 or 1
presenceAbsenceEnvDf <- as.data.frame(rbind(occEnv, absenceEnv)) #making it a Data Frame
#the data frame is about environmental conditions, kinda.
#(where Df above stands for "data frame")

## step 5: Create SDM with Maxent (Maximum Entropy modelling). Future SDM also uses Maxent.
morafkaiSDM <- dismo::maxent(x = presenceAbsenceEnvDf, # env conditions
                             p = presenceAbsenceV,         # 1: presence or 0: absence
                             path=paste("output/maxent_outputs"))
# the last part above is directing results into a folder (maxent_outputs); it also...
#makes the folder if you didn't have one already

## step 6: Plot the Maxent-method current SDM Model 

#some final changes to the formatting of info...
#clim is huge and it isn't reasonable to predict over whole world
#so first we will make it smaller.
#choosing here what is reasonable for the pts (where you got background pts from); 
#use same extent thingy as before (here that is 1.25):
predictExtent <- 1.25 * geographicExtent 
# crop clim to the extent of the map you want:
geographicArea <- crop(clim, predictExtent, snap = "in")
#first part of plot --raster thing:
morafkaiPredictPlot <- raster::predict(morafkaiSDM, geographicArea) 
#below: some spacial pixel stuff related to the Df, idk:
raster.spdf <- as(morafkaiPredictPlot, "SpatialPixelsDataFrame") 
#making the result a data frame (has to be for ggplot to work):
morafkaiPredictDf <- as.data.frame(raster.spdf)

#preparations to plot...
#basic world layer thingy:
wrld <- ggplot2::map_data("world") #(doesn't plot per se, just makes a variable with...
#...world layer info things that help it plot the next part).
#setting x and y limits:
xmax <- max(morafkaiPredictDf$x)
xmin <- min(morafkaiPredictDf$x)
ymax <- max(morafkaiPredictDf$y)
ymin <- min(morafkaiPredictDf$y)

#plotting the whole thing finally with all the bells and whistles in ggplot!
ggplot() +
  geom_polygon(data = wrld, mapping = aes(x = long, y = lat, group = group),
               fill = "grey75") +
  geom_raster(data = morafkaiPredictDf, aes(x = x, y = y, fill = layer)) +
  scale_fill_gradientn(colors = terrain.colors(10, rev = T)) +
  coord_fixed(xlim = c(xmin, xmax), ylim = c(ymin, ymax), expand = F) + 
  scale_size_area() +
  borders("state") +
  labs(title = "SDM of G. morafkai Under Current Climate Conditions",
       x = "longitude",
       y = "latitude",
       fill = "Environmental \nSuitability") + 
  theme(legend.box.background=element_rect(),legend.box.margin=margin(5,5,5,5))

## Step 7: Save your current model!
#Live code to ggsave (one saving method) the plot is below.
#made the width 2000 and height 900 and that worked pretty well.
ggsave(filename = "G.morafkai.currentSDM.jpg", plot=last_plot(),path="output", width=2000, height=900, units="px")

#Section C, portion ii: Future SDM

# First...get future climate data.
# But before I do... there's something about clarifying climate variables?
# directions say to rename clim to "currentEnv", I think, because clim isn't very specific.
# seems odd. does that not cause issues b/c there's already a "currentEnv"?
# i will call it not "currentEnv" but "currentEnv2", to distinguish it from...
# the previous variable "currentEnv". Now: renaming "clim" to "CurrentEnv2":
currentEnv2 <- clim 
#so that variable now has everything "clim" had; it is an exact copy.

# Step one: getting the cmip future environmental data. (This is a large file, may take a bit):
# this is the "middle-of-the-road" greenhouse gas prediction, 70 years from now.
# FYI: to see the specifics...
# ...in getData portion, you can specify with rcp, which is the greenhouse gas emission prediction,
# can also specify which model...
# use this link to see the models: https://rdrr.io/cran/raster/man/getData.html 
# ...and which year: 50 or 70 years from now--(with the "year=" part.)
futureEnv <- raster::getData(name = 'CMIP5', var = 'bio', res = 2.5,
                             rcp = 45, model = 'IP', year = 70, path="data")
#small bit of renaming...
#(question: what is the purpose of the line below... why do we need it?):
names(futureEnv) = names(currentEnv2)  #future names should be the same as current names 
#(hope that didn't mess up stuff when i put "currentEnv2" and not "currentEnv" but... 
#i think it wants the most *current*, current Env? and that's "currentEnv2".)

# step two: crop clim (now futureEnv) to the extent of the map you want. Same as before (with predictExtent).
geographicAreaFutureC5 <- crop(futureEnv, predictExtent)

# step three: making the future SDM, predicting  model onto future climate 70 years from now 
# Note: morafkaiSDM variable was made and defined already in the current SDM for the species 
morafkaiPredictPlotFutureC5 <- raster::predict(morafkaiSDM, geographicAreaFutureC5)  

# step four: turning the SDM information into a data frame
# for ggplot, we need the prediction to be a data frame. 
#Basically same code used here as in the current SDM.
raster.spdfFutureC5 <- as(morafkaiPredictPlotFutureC5, "SpatialPixelsDataFrame")
morafkaiPredictDfFutureC5 <- as.data.frame(raster.spdfFutureC5)

# step 5: final ggplotting stuff
# make the "world" layer:
wrld <- ggplot2::map_data("world")
# get our lat/long boundaries:
xmax <- max(morafkaiPredictDfFutureC5$x)
xmin <- min(morafkaiPredictDfFutureC5$x)
ymax <- max(morafkaiPredictDfFutureC5$y)
ymin <- min(morafkaiPredictDfFutureC5$y)

# tep 6: make the final future SDM plot
ggplot() +
  geom_polygon(data = wrld, mapping = aes(x = long, y = lat, group = group),
               fill = "grey75") +
  geom_raster(data = morafkaiPredictDfFutureC5, aes(x = x, y = y, fill = layer)) + 
  scale_fill_gradientn(colors = terrain.colors(10, rev = T)) +
  coord_fixed(xlim = c(xmin, xmax), ylim = c(ymin, ymax), expand = F) +
  scale_size_area() +
  borders("world") +
  borders("state") +
  labs(title = "SDM of G. morafkai Under CMIP 5 Climate Conditions",
       x = "longitude",
       y = "latitude",
       fill = "Env Suitability") +
  theme(legend.box.background=element_rect(),legend.box.margin=margin(5,5,5,5)) 
# well, even though the tortoise is probably screwed, given these projections...
# ...at least the graph worked!

# Step 7: save your future model!
ggsave(filename = "G.morafkai.futureSDM.jpg", plot=last_plot(),path="output", width=2000, height=900, units="px")




