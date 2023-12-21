#Create a map of the occurrence points...

#load in world map data
wrld <- ggplot2::map_data("world")

#set x and y max/min values to zoom in on focal area of map for g. morafkai
xmax <- max(clean.tortoise$longitude)
xmin <- min(clean.tortoise$longitude)
ymax <- max(clean.tortoise$latitude)
ymin <- min(clean.tortoise$latitude)

#Create map with world data, load in our tortoise data, set title and axis labels, set x and y limits, and add state borders.
ggplot()+
  geom_polygon(data=wrld, mapping=aes(x=long, y=lat, group=group), fill="grey89", color = "grey60")+
  geom_point(data=clean.tortoise, mapping=aes(x=longitude, y=latitude), show.legend=FALSE) +
  labs(title = "Species Occurences of \nGopherus Morafkai", x="Longitude", y="Latitude") +
  coord_fixed(xlim = c(xmin, xmax), ylim = c(ymin,ymax))+
  scale_size_area()+
  borders("state")

#Our occurrence points are locations, using x and y coordinates, 
# ...where there is evidence of an occurrence of our tortoise species.

#Save the map into the outputs file with ggsave method:
ggsave(filename = "occurrencemap.jpg", 
       plot = last_plot(), path = "output", 
       width = 1200, height = 800,
       units = "px")
