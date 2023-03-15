library(ggplot2)
library(Matrix)
library(grid)
library(Seurat)
library(dplyr)


# working space
setwd('/Users/ninasong/Desktop/spatialProject/literature_model/graph_convolutional_clustering/unsupervised-GCN/FFD1')

geom_spatial <-  function(mapping = NULL,
                          data = NULL,
                          stat = "identity",
                          position = "identity",
                          na.rm = FALSE,
                          show.legend = NA,
                          inherit.aes = FALSE,
                          ...) {

  GeomCustom <- ggproto(
    "GeomCustom",
    Geom,
    setup_data = function(self, data, params) {
      data <- ggproto_parent(Geom, self)$setup_data(data, params)
      data
    },

    draw_group = function(data, panel_scales, coord) {
      vp <- grid::viewport(x=data$x, y=data$y)
      g <- grid::editGrob(data$grob[[1]], vp=vp)
      ggplot2:::ggname("geom_spatial", g)
    },

    required_aes = c("grob","x","y")

  )

  layer(
    geom = GeomCustom,
    mapping = mapping,
    data = data,
    stat = stat,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(na.rm = na.rm, ...)
  )
}


sample_names <- c("FFD1 - label_GCN")
tissue_paths <- c("./annotation/pred_label_for_visualization.csv")
image_paths <- c("./spatial/tissue_hires_image.png") # been provided in "spatial folder"
scalefactor_paths <- c('./spatial/scalefactors_json.json') # been provided in spatial folder"

images_cl <- list()
for (i in 1:length(sample_names)) {
  images_cl[[i]] <- read.bitmap(image_paths[i])
}

height <- list()

for (i in 1:length(sample_names)) {
  height[[i]] <-  data.frame(height = nrow(images_cl[[i]]))
}

height <- bind_rows(height)

width <- list()

for (i in 1:length(sample_names)) {
  width[[i]] <- data.frame(width = ncol(images_cl[[i]]))
}

width <- bind_rows(width)


grobs <- list()
for (i in 1:length(sample_names)) {
  grobs[[i]] <- rasterGrob(images_cl[[i]], width=unit(1,"npc"), height=unit(1,"npc"))
}

images_tibble <- tibble(sample=factor(sample_names), grob=grobs)
images_tibble$height <- height$height
images_tibble$width <- width$width

scales <- list()

for (i in 1:length(sample_names)) {
  scales[[i]] <- rjson::fromJSON(file = scalefactor_paths[i])
}


bcs <- list()
for (i in 1:length(sample_names)) {
  bcs[[i]] <- read.csv(tissue_paths[i],col.names=c("barcode","tissue","row","col","imagerow","imagecol","Cluster"), header = FALSE)
  bcs[[i]]$imagerow <- bcs[[i]]$imagerow * scales[[i]]$tissue_hires_scalef    # scale tissue coordinates for highres image
  bcs[[i]]$imagecol <- bcs[[i]]$imagecol * scales[[i]]$tissue_hires_scalef
  bcs[[i]]$tissue <- as.factor(bcs[[i]]$tissue)
  bcs[[i]]$height <- height$height[i]
  bcs[[i]]$width <- width$width[i]
}

names(bcs) <- sample_names
bcs_merge <- bind_rows(bcs, .id = "sample")


## Plotting

## general color for visualizing
#scale_fill_manual(values = c("#b2df8a","#377eb8","#4daf4a","#ff7f00","gold", "#a65628", "#999999", "black", "#e41a1c", "grey", "white", "purple"))+

## Color for highlighting the sepcific area
#scale_fill_manual(values = c("#a6cee3","#cab2d6","#06592A","#33a02c","#ff7f00","#8F0038","#fb9a99","#fdbf6f","#997273","#db4c6c"))+
#plot_color=c("#a6cee3","#1f78b4","##b2df8a","#33a02c","#fb9a99","#e31a1c","#fdbf6f","#ff7f00","#cab2d6","#997273","#787878","#db4c6c","#9e7a7a","#554236","#af5f3c","#93796c","#f9bd3f","#dab370","#877f6c","#268785")

plots <- list()

for (i in 1:length(sample_names)) {

  plots[[i]] <- bcs_merge %>%
    filter(sample ==sample_names[i]) %>%
    filter(tissue == "1") %>%
    ggplot(aes(x=imagecol,y=imagerow,fill=factor(Cluster))) +
    geom_spatial(data=images_tibble[i,], aes(grob=grob), x=0.5, y=0.5)+
    geom_point(shape = 21, colour = "black", size = 1.75, stroke = 0.5)+
    coord_cartesian(expand=FALSE)+
    scale_fill_manual(values = c("#b2df8a","#377eb8","#4daf4a","#ff7f00","gold" ,"black", "#999999",  "#a65628", "#e41a1c", "grey", "white", "purple"))+
    xlim(0,max(bcs_merge %>%
                 filter(sample ==sample_names[i]) %>%
                 select(width)))+
    ylim(max(bcs_merge %>%
               filter(sample ==sample_names[i]) %>%
               select(height)),0)+
    xlab("") +
    ylab("") +
    ggtitle(sample_names[i])+
    labs(fill = "Cluster")+
    guides(fill = guide_legend(override.aes = list(size=4)))+
    theme_set(theme_bw(base_size = 12))+
    theme(panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          panel.background = element_blank(),
          axis.line = element_line(colour = "black"),
          axis.text = element_blank(),
          axis.ticks = element_blank())
}

plot_grid(plotlist = plots)

