#This code creates a quick map of the distribution points pulled from gbif.

wrld<-ggplot2::map_data("world")
xmax<-max(noNASal$longitude)
xmin<-min(noNASal$longitude)
ymax<-max(noNASal$latitude).
ymin<-min(noNASal$latitude)

ggplot()+
  theme(panel.background = element_rect(fill = "#BFD5E3", colour = "#6D9EC1"))+
  geom_polygon(data=wrld, mapping=aes(x=long, y=lat, group=group), fill="grey75") +
  geom_point(data=noNASal, mapping=aes(x=longitude, y=latitude),show.legend = FALSE, color="darkgreen")+
  labs(title="species occurrences of Rhyacotriton \ncascadae from 1818-2023", x="longitude", y="latitude")+
  coord_fixed(xlim=c(xmin -2,xmax +2), ylim=c (ymin,ymax))+
  scale_size_area()+
  borders("state")
ggsave(filename="salamanderOccurrence.jpg", path="output", width=1600, height=1200, units = "px" )