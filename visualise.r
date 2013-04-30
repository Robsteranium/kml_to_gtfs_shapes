library(ggplot2)
library(rgeos)
library(rgdal)
route <- readOGR("fixtures/loop.kml","Layer #0")
stops <- read.csv("fixtures/gtfs_loop/stops.txt", header=T)

options(device="png")

route_df = as.data.frame(coordinates(route))
stops_df = as.data.frame(stops[,c("stop_lat","stop_lon")])
colnames(route_df) <- c("x","y")
colnames(stops_df) <- c("x","y")

#simple.plot <- 
ggplot() + geom_path(data=route_df,aes(x=x,y=y),colour="blue",size=2) + geom_point(data=stops_df,aes(x=x,y=y),colour="red") + geom_path(data=stops_df,aes(x=x,y=y),colour="red") + theme_bw() + labs(title="Simple Route/ Stops") + geom_text(data=stops_df,aes(x=x,y=y,label=1:26))

dev.off()
