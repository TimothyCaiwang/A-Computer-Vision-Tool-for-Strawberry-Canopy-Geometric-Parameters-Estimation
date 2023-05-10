library(ForestTools)
library(raster)
library(rgdal)
library(sp)
library(pacman)
library(EBImage)
library(Rvision)

# input folder
lm_folder = '/local_maximum'
dsm_vm_folder = '/dsm_vm'

# output folder
watershed_folder = '/water_shed'
contours_folder = '/contours'

dsm_vm_path = dir(dsm_vm_folder,pattern = ".tif$", full.names = FALSE, ignore.case = TRUE)

m = length(dsm_vm_path) # the number of data collections

area_all = vector()
for (i in 1:m){
  print(dsm_vm_path[i])
  dsm_vm_pathi = file.path(dsm_vm_folder, dsm_vm_path[i])
  dsm_vm <- raster(dsm_vm_pathi)
  
  lm_fi <- gsub("dsm_no_mask_clip.tif", "local_maximum", dsm_vm_path[i])
  ttops <- readOGR(dsn = lm_folder, layer = lm_fi)
  crowns <- mcws(treetops = ttops, CHM = dsm_vm, minHeight = 15.60, verbose = FALSE)
  
  crowns_fi <- gsub("dsm_no_mask_clip", "water_shed", dsm_vm_path[i])
  output_watershed = file.path(watershed_folder, crowns_fi)  
  x <- writeRaster(crowns, filename=output_watershed, format="GTiff", overwrite=TRUE)
  crowns.array = as.array(crowns)
  crowns.array[is.na(crowns.array)]<-0
  n = max(crowns.array) # the number of contours/plants
  
  gdal_info = GDALinfo(dsm_vm_pathi)
  llx = gdal_info['ll.x']
  lly = gdal_info['ll.y']
  
  rx = gdal_info['res.x']
  ry = gdal_info['res.y']
  
  rown = gdal_info['rows']
  clmn = gdal_info['columns']
  IDj = 1
  for (j in 1:n){
    print(j)
    mask.array <- array(0, dim(crowns.array))
    mask.array[crowns.array == j] = 255
    mask.image = Rvision::image(mask.array)
    mask.image = Rvision::changeBitDepth(mask.image, "8U")
    
    veg_contours <- findContours(mask.image, mode = "external", method = "simple", offset = c(0, 0))
    c <- veg_contours$contours
    x = c[,2]
    y = c[,3]
    c_area = contourArea(c[,2],c[,3])
    area_all[j] = c_area
    
    if(c_area<3000){
      gx = llx + x*rx
      gy = lly + (rown-y)*ry
      
      poly1 <- sp::Polygon(cbind(gx, gy))
      
      if(IDj == 1){
        polyall = list(sp::Polygons(list(poly1),ID = as.character(j))) # ,ID = as.character(t)
        IDj = IDj + 1
      } else {
        polyall = append(polyall,list(sp::Polygons(list(poly1),ID = as.character(j))), after = length(polyall))
        IDj = IDj + 1
      }
      
    }
  }
  
  c_fi <- gsub("dsm_no_mask_clip.tif", "contours.shp", dsm_vm_path[i])
  c_pathi = file.path(contours_folder, c_fi)
  SpatialPolys <- sp::SpatialPolygons(polyall, proj4string=CRS(as.character("EPSG:32617")))
  shapefile(SpatialPolys, c_pathi)
}

