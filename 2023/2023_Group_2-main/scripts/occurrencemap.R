install.packages("tidyverse") #includes ggplot
library(tidyverse)

marten <- read_csv("data/marten.csv")

#finding the bounds for the map
xmax <- max(marten$longitude)
xmin <- min(marten$longitude)
ymax <- max(marten$latitude)
ymin <- min(marten$latitude)


ggplot()+
  geom_polygon(data=wrld, mapping=aes(x=long, y=lat, group=group),fill="grey75",colour="grey60")+
  geom_point(data=marten, mapping=aes(x=longitude, y=latitude), show.legend = FALSE)+
  labs(title=expression(paste("Species occurences of " ,italic("M. caurina"))))+
  coord_fixed(xlim=c(xmin,xmax), ylim=c(ymin,ymax))+
  scale_size_area()+
  borders("state")

ggsave(filename="occurrencemap.jpg", plot=last_plot(), path="output", width=6.14, height=4.84, units="in")