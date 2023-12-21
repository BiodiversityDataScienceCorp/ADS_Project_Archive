#run currentSDM.R first to
#load libraries and climate data
#map can changed based on when you load weather and marten data
#or possibly the computer processor

climList <- list.files(path = "data/wc2-5/", pattern = ".bil$", 
                       full.names = T) 
currentEnv <- raster::stack(climList)

futureEnv <- raster::getData(name = 'CMIP5', var = 'bio', res = 2.5,
                             rcp = 45, model = 'IP', year = 70, path="data")
names(futureEnv) = names(currentEnv)

mask <- raster(clim[[1]]) # mask is the raster object that determines the area where we are generating pts

# determine geographic extent of our data (so we generate random points reasonably nearby)
geographicExtent <- extent(x = martenDataSpatialPts)

predictExtent <- 1.25 * geographicExtent # choose here what is reasonable for your pts (where you got background pts from)

geographicAreaFutureC5 <- crop(futureEnv, predictExtent)
martenPredictPlotFutureC5 <- raster::predict(martenSDM, geographicAreaFutureC5)
raster.spdfFutureC5 <- as(martenPredictPlotFutureC5, "SpatialPixelsDataFrame")
martenPredictDfFutureC5 <- as.data.frame(raster.spdfFutureC5)

# plot in ggplot
wrld <- ggplot2::map_data("world")

# get our lat/lon boundaries
xmax <- max(martenPredictDfFutureC5$x)
xmin <- min(martenPredictDfFutureC5$x)
ymax <- max(martenPredictDfFutureC5$y)
ymin <- min(martenPredictDfFutureC5$y)

ggplot() +
  geom_polygon(data = wrld, mapping = aes(x = long, y = lat, group = group),
               fill = "grey75") +
  geom_raster(data = martenPredictDfFutureC5, aes(x = x, y = y, fill = layer)) + 
  scale_fill_gradientn(colors = terrain.colors(10, rev = T)) +
  coord_fixed(xlim = c(xmin, xmax), ylim = c(ymin, ymax), expand = F) +
  scale_size_area() +
  borders("world") +
  borders("state") +
  labs(title = expression(paste("Future SDM of " ,italic("M. caurina"), " Under CMIP 5 Climate Conditions")),
       x = "longitude",
       y = "latitude",
       fill = "Env Suitability") +
  theme(legend.box.background=element_rect(),legend.box.margin=margin(5,5,5,5)) 


#Live ggsave here:
ggsave(filename="futureSDM.jpg", plot=last_plot(), path="output", width=6.14, height=4.84, units="in")
