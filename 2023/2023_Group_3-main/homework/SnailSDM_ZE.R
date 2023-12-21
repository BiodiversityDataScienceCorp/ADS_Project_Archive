install.packages("spocc")
install.packages("tidyverse") #includes ggplot
install.packages("dismo")
install.packages("maptools")
install.packages("tidyverse")
install.packages("rJava")
install.packages("maps")
library(spocc)
library(tidyverse)
library(dismo)
library(maptools)
library(tidyverse)
library(rJava)
library(maps)



snailquery<-occ(query = "Ashmunella levettei", from = "gbif", limit = 4000)
snailquery

snail<-snailquery$gbif$data$Ashmunella_levettei

cleanSnail <- snail%>% 
  filter(latitude !="NA", longitude !="NA") %>% 
  mutate(location = paste(latitude, longitude,dateIdentified, sep = "/" ))%>% 
  distinct(location, .keep_all = TRUE)

write_csv(cleanSnail, file="snaildata.csv")

snailData<- read_csv("snaildata.csv")

snailDataNotCoords<- snailData %>% select(longitude, latitude)

snailDataSpatialPts<- SpatialPoints(snailDataNotCoords, proj4string = CRS ("+proj=longlat"))

currentEnv <- getData("worldclim", var="bio", res=2.5, path="data/")

climList <- list.files(path = "data/wc2-5/", pattern = ".bil$", 
                       full.names = T)

clim <- raster::stack(climList)

plot(clim[[12]])
plot(snailDataSpatialPts, add = TRUE)

mask <- raster(clim[[1]]) 

geographicExtent <- extent(x = snailDataSpatialPts)

set.seed(45) 
backgroundPoints <- randomPoints(mask = mask, 
                                 n = nrow(snailDataNotCoords), 
                                 ext = geographicExtent, 
                                 extf = 2.25, 
                                 warn = 0)

colnames(backgroundPoints) <- c("longitude", "latitude")


occEnv <- na.omit(raster::extract(x = clim, y = snailDataNotCoords))
absenceEnv<- na.omit(raster::extract(x = clim, y = backgroundPoints))

presenceAbsenceV <- c(rep(1, nrow(occEnv)), rep(0, nrow(absenceEnv)))
presenceAbsenceEnvDf <- as.data.frame(rbind(occEnv, absenceEnv)) 

snailSDM <- dismo::maxent(x = presenceAbsenceEnvDf,
                         p = presenceAbsenceV,   
                         path=paste ("output/maxent_outputs"))

predictExtent <- 2.25 * geographicExtent
geographicArea <- crop(clim, predictExtent, snap = "in")

snailPredictPlot <- raster::predict(snailSDM, geographicArea) 

raster.spdf <- as(snailPredictPlot, "SpatialPixelsDataFrame")

snailPredictDf <- as.data.frame(raster.spdf)


wrld <- ggplot2::map_data("world")

xmax <- max(snailPredictDf$x)
xmin <- min(snailPredictDf$x)
ymax <- max(snailPredictDf$y)
ymin <- min(snailPredictDf$y)

dev.off()
ggplot() +
  geom_polygon(data = wrld, mapping = aes(x = long, y = lat, group = group),
               fill = "grey75") +
  geom_raster(data = snailPredictDf, aes(x = x, y = y, fill = layer)) + 
  scale_fill_gradientn(colors = terrain.colors(10, rev = T)) +
  coord_fixed(xlim = c(xmin, xmax), ylim = c(ymin, ymax), expand = F) + 
  scale_size_area() +
  borders("state") +
  labs(title = "SDM of A. levettei Under \nCurrent Climate Conditions",
       x = "longitude",
       y = "latitude",
       fill = "Environmental \nSuitability") + # \n is a line break
  theme(legend.box.background=element_rect(),legend.box.margin=margin(5,5,5,5)) 

ggsave(filename = "snailSDM.jpg", plot=last_plot(), path="output", width = 2000, 
       height = 1000, units = "px")


                        
                         

