install.packages("spocc")
install.packages("tidyverse") 
library(spocc)
library(tidyverse)
#Install Packages for data collection



rawData<-occ(query="Rhyacotriton cascadae", from="gbif", limit=4000)
salamanderData<-rawData$gbif$data$Rhyacotriton_cascadae
#Query gbif for occurance data points

noDoopSal <- salamanderData %>% mutate(location = paste(latitude, longitude, dateIdentified, sep = "/")) %>% 
  distinct(location, .keep_all = TRUE)
noNASal <- noDoopSal %>% filter(latitude != "NA", longitude != "NA")
#Get rid of duplicate entries and N/A latitude and longitude points. 

write_csv(noNASal, path="data/salamanderData.csv")
#Write data to a CSV File to access later. 
