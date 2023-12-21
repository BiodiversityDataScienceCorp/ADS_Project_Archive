## HW 4
install.packages("spocc")
install.packages("tidyverse") #includes ggplot
library(spocc)
library(tidyverse)
#animal: Sonoran Desert Tortoise
#scientific name: Gopherus morafkai
#let's try searching gbif:
myquery <- occ(query='Gopherus morafkai', from=c('gbif'), limit=4000)
myquery
#drilling down in the data --ignoring the other databases:
morafkai<-myquery$gbif$data$Gopherus_morafkai
#let's try a rudimentary map now: you have to run the wlrd one first, and then the ggplot string...
wrld <- ggplot2::map_data("world")
ggplot() + geom_point(data=morafkai, mapping=aes(x=longitude, y=latitude), show.legend=FALSE) + 
  labs(title="species occurences", x="longitude", y="latitude")
#this doesn't have borders or anything, just lat/long, hope it's right...
#now let's try a REAL plot! (cooler looking, more stuff in the argument)
ggplot()+
  geom_polygon(data=wrld, mapping=aes(x=long, y=lat, group=group), fill="grey75", color="grey60")+ 
  geom_point(data=morafkai, mapping=aes(x=longitude, y=latitude), show.legend=FALSE)+
  labs(title="Species occurences of G. morafkai", x="longitude", y="latitude")
#that's great and all, but the data hasn't been cleaned.
#i should probably try doing some basic cleaning, like last week.
#removing N/A points:
noNApoints <- morafkai %>% filter (latitude != "NA", longitude !="NA")
#making all occurrence points be the "present" ones:
occurrencePresent <- filter(noNApoints, occurrenceStatus == "PRESENT")
#deleting duplicates, but making a new column first (not sure why is necessary):
#making new column:
noDuplicates <- occurrencePresent %>% mutate(location = paste 
                                             (latitude, longitude, dateIdentified, sep = "/") )
#getting rid of duplicates (not really sure why, but now i need --
#...con'td. --a new noDuplicates variable, but still using this column;
#I would call it noDuplicates2, but apparently its version for my groupmates --
#...is instead called "CleanTortoise", and consistency is important... so:
cleanTortoise <- noDuplicates %>% distinct(location, .keep_all = TRUE)
#now we just ignore "noDuplicates2", which I made earlier but just renamed on 3/5
#getting x and y limits, in preparation for the map 
#we want it "zoomed in" to the edges of the occurrence data, not showing the whole world
xMax <- max(cleanTortoise$longitude)
xMin <- min(cleanTortoise$longitude)
yMax <- max(cleanTortoise$latitude)
yMin <- min(cleanTortoise$latitude)
#let's also get a date range:
range(as.Date(na.omit(occurrencePresent$dateIdentified)))
#so these occurrences date from 1968 to 2023. (That will go in the title of the map)
#Now to make the map:
ggplot()+
  geom_polygon(data=wrld, mapping=aes(x=long, y=lat, group=group), fill="grey75", color="grey60")+ 
  geom_point(data=noDuplicates2, mapping=aes(x=longitude, y=latitude), show.legend=FALSE)+
  scale_size_area()+ 
  coord_fixed(xlim = c(xMin, xMax), ylim = c(yMin, yMax))+ 
  borders("state")+
  labs(title="Species occurrences of G. morafkai, 1968-2022", x="longitude", y="latitude")
#Perfect!

