install.packages("dismo")
install.packages("maptools")
install.packages("tidyverse")
install.packages("rJava")
install.packages("maps")

library(dismo)
library(maptools)
library(tidyverse)
library(rJava)
library(maps)


currentEnv <- clim


futureEnv <- raster::getData(name = 'CMIP5', var = 'bio', res = 2.5,
                             rcp = 45, model = 'IP', year = 70, path="data") 


geographicAreaFutureC5 <- crop(futureEnv, predictExtent)

GophPredictPlotFutureC5 <- raster::predict(GophSDM, geographicAreaFutureC5)  


raster.spdfFutureC5 <- as(GophPredictPlotFutureC5, "SpatialPixelsDataFrame")
GophPredictDfFutureC5 <- as.data.frame(raster.spdfFutureC5)


wrld <- ggplot2::map_data("world")


xmax <- max(GophPredictDfFutureC5$x)
xmin <- min(GophPredictDfFutureC5$x)
ymax <- max(GophPredictDfFutureC5$y)
ymin <- min(GophPredictDfFutureC5$y)


ggplot() +
  geom_polygon(data = wrld, mapping = aes(x = long, y = lat, group = group),
               fill = "grey75") +
  geom_raster(data = GophPredictDfFutureC5, aes(x = x, y = y, fill = layer)) + 
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

ggsave(filename = "futureSDM.jpg", plot=last_plot(),path="output", width=2000, height=900, units="px")

HOMEWORK 4

install.packages("spocc")
install.packages("tidyverse") #includes ggplot
library(spocc)
library(tidyverse)

occ_options('gbif')

Tortoise <- occ(query='Gopherus morafkai', from=c('gbif'), limit=4000)
Tortoise

Gopherus <- Tortoise$gbif$data$Gopherus_morafkai
Gopherus

ggplot()+
  geom_point(data=Gopherus, mapping=aes(x=longitude, y=latitude), show.legend=FALSE) +
  labs(title = "species occurences", x="longitude", y="latitude")

wrld <- ggplot2::map_data("world")

ggplot()+
  geom_polygon(data=wrld, mapping=aes(x=long, y=lat, group=group), fill="grey75", color = "grey60")+
  geom_point(data=Gopherus, mapping=aes(x=longitude, y=latitude), show.legend=FALSE) +
  labs(title = "species occurences", x="longitude", y="latitude")


cleanTortoise2 <- Gopherus %>% 
  filter(longitude <= 0) %>% 
  filter(latitude != "NA", longitude != "NA") %>% 
  filter(occurrenceStatus == "PRESENT") %>%
  mutate(location = paste(latitude, longitude, dateIdentified, sep = "/"))%>%
  distinct(location, .keep_all=TRUE)
#only filtered NAs and duplicates because map didn't show any extreme outliers, 
#all occurrences were located in southern US and Mexico.  

xmax <- max(noDuplicates$longitude)
xmin <- min(noDuplicates$longitude)
ymax <- max(noDuplicates$latitude)
ymin <- min(noDuplicates$latitude)

ggplot()+
  geom_polygon(data=wrld, mapping=aes(x=long, y=lat, group=group), fill="burlywood1", color = "grey9")+
  geom_point(data=cleanTortoise, mapping=aes(x=longitude, y=latitude), show.legend=FALSE) +
  labs(title = "species occurences of Gopherus morafkai 1968-2022", x="longitude", y="latitude") +
  coord_fixed(xlim = c(xmin, xmax), ylim = c(ymin,ymax))+
  scale_size_area()+
  borders("state")

range(as.Date(na.omit(cleanTortoise$dateIdentified)))

#The occurrence points are where the species was noted as existing,
#meaning there was evidence that the species was located in that specific area. 

#attempting to add state names 
state.abb

ggplot()+
  geom_polygon(data=wrld, mapping=aes(x=long, y=lat, group=group), fill="burlywood1", color = "grey9")+
  geom_point(data=cleanTortoise, mapping=aes(x=longitude, y=latitude), show.legend=FALSE) +
  labs(title = "species occurences of Gopherus morafkai 1968-2022", x="longitude", y="latitude") +
  coord_fixed(xlim = c(xmin, xmax), ylim = c(ymin,ymax))+
  scale_size_area()+
  borders("state")
