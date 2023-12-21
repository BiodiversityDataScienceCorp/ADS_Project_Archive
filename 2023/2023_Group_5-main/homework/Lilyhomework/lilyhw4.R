#installing required packages
install.packages("spocc")
install.packages("tidyverse") #includes ggplot
library(spocc)
library(tidyverse)



#Query for Gopherus morafkai (Sonoran desert tortoise) data from GBIF, with a limit of 4000.
tortoiseQuery <- occ(query = "Gopherus morafkai", from="gbif", limit = 4000)
tortoiseQuery

tortoise <- tortoiseQuery$gbif$data$Gopherus_morafkai



#Cleaning data...
#Removing where lat/long are NA
clean.tortoise <- tortoise %>%
  filter(latitude != "NA", longitude != "NA") %>%
  #Removing duplicates
  mutate(location = paste(latitude, longitude, dateIdentified, sep = "/")) %>%
  distinct(location, .keep_all = TRUE) %>%
  filter(occurrenceStatus == "PRESENT")
#We did not feel the need to remove any illogical data points,
#because we felt that all of our occurrence data was very localized.
#We also do not know about the species distribution enough to cut off the outlying points near TX and NM.


#Create a map of the occurrence points...

#load in world map data
wrld <- ggplot2::map_data("world")

#set x and y max/min values to zoom in on our map
xmax <- max(clean.tortoise$longitude)
xmin <- min(clean.tortoise$longitude)
ymax <- max(clean.tortoise$latitude)
ymin <- min(clean.tortoise$latitude)

#Create map with world data, load in our tortoise data, set title and axes labels, set x and y limits, and add state borders.
ggplot()+
  geom_polygon(data=wrld, mapping=aes(x=long, y=lat, group=group), fill="grey89", color = "grey60")+
  geom_point(data=clean.tortoise, mapping=aes(x=longitude, y=latitude), show.legend=FALSE) +
  labs(title = "Species Occurences of Gopherus Morafkai", x="Longitude", y="Latitude") +
  coord_fixed(xlim = c(xmin, xmax), ylim = c(ymin,ymax))+
  scale_size_area()+
  borders("state")

#Our occurrence points are locations, using x and y coordinates, where there is evidence of an occurrence of our tortoise species.