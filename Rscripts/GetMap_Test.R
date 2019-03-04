library("ggmap")
#ggMap = get_map (c(14.0,44.0,26,50),
#                maptype = "roadmap",
#                 source = "google",
#                 filename = "ggmapTemp",
#                 color = "color",
#                 messaging = FALSE,
#                 language = "en-EN")
setwd("/Users/balazs/Desktop/Analysis/LaTeX")
fileName=paste("Figures/Fig_",2,'_GoogleMap.png',sep="")
ggMap = get_googlemap (center = c(19.5,47.0),
                size  = c(640,640),
                zoom  = 7,
                scale = 2,
                maptype  = "roadmap",
                language = "en-EN",
                sensor   = FALSE,
                messaging = FALSE,
                filename = fileName,
                color = "color",
                region = ".hu")

#ggmap (ggMap)
