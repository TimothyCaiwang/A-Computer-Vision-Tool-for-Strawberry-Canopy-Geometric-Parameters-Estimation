library(ForestTools)
library(raster)
library(rgdal)
library(sp)
library(pacman)
library(EBImage)
library(sf)

# input folder and file
img_folder = '/ortho_samples'
dsm_folder = '/dem_samples'

top_beds_boundary = '/Top_Beds_UTM_Boundary_2020_to_2021.shp' # optional file
top_beds_shp <- st_read(top_beds_boundary)


# centroid point shp file
in_Can_Pts = "/centroid"
in_Can_Pts_baseName = "20202021_ortho_samples_UTM_center"
ttops <- readOGR(dsn = in_Can_Pts, layer = in_Can_Pts_baseName)
t_pos <- coordinates(ttops)


# output folder
ndvi_folder = '/ndvi'
vm_folder = '/veg_mask'
lm_folder = '/local_maximum'
dsm_vm_folder = '/dsm_vm' # only canopy dsm file
fishnet_folder = '/fishnet'


img_path = list.files(path=img_folder,pattern = ".tif$", full.names = FALSE, ignore.case = TRUE)
dsm_path = list.files(path=dsm_folder,pattern = ".tif$", full.names = FALSE, ignore.case = TRUE)


# NDVI calculation
NDVICalc <- function(x){
  ndvi<-(x[[4]]-x[[3]])/(x[[3]]+x[[4]])
  return(ndvi)
}



for (i in seq(1, length(img_path), by=1)){
  print(img_path[i])
  img_pathi = file.path(img_folder, img_path[i])
  dsm_pathi = file.path(dsm_folder, dsm_path[i])
  
  dsm_o <- stack(dsm_pathi)
  dsm <- mask(dsm_o, top_beds_shp)
  dim_dsm = dim(dsm)
  dsm.array = as.array(dsm)
  
  img <- stack(img_pathi)
  dim_img = dim(img)
  img.array = as.array(img)
  
  dmr = min(dim_dsm[1], dim_img[1])
  dmc = min(dim_dsm[2], dim_img[2])
  
  # NDVI calculation and export
  NDVI <- NDVICalc(img)
  NDVI_f = gsub("ortho", "ndvi", img_path[i])
  NDVI_p = file.path(ndvi_folder, NDVI_f)
  
  writeRaster(x = NDVI,
              filename=NDVI_p,
              format = "GTiff", # save as a tif
              datatype='FLT4S', # save as a INTEGER rather than a float
              overwrite = TRUE)  # OPTIONAL - be careful. This will OVERWRITE previous files.
  
  NDVI.value = as.array(NDVI)
  t = otsu(NDVI.value, range = c(-1, 1), levels = 256)
  
  # Vegetation mask calculation and export
  m <- c(-1, t, 0,  t, 1, 255)
  m <- matrix(m, ncol = 3, byrow = T)
  veg_mask <- reclassify(NDVI, m, right = T)
  veg_mask.array = as.array(veg_mask)
  
  kern = makeBrush(3, shape='diamond')
  veg_mask.array = erode(veg_mask.array, kern)
  veg_mask.array = dilate(veg_mask.array, kern)
  
  veg_mask.array[is.na(veg_mask.array)] <- 0
  
  # Veg mask calculation and export
  vm_f = gsub("ortho", "vm", img_path[i])
  vm_p = file.path(vm_folder, vm_f)  
  
  writeRaster(x = veg_mask,
              filename = vm_p,
              format = "GTiff", # save as a tif
              datatype='INT2S', # save as a INTEGER rather than a float
              overwrite = TRUE)  # OPTIONAL - be careful. This will OVERWRITE previous files
  
  # fishnet generation
  fishnet = array(0, dim=c(dmr,dmc))
  rn = floor(dmr/100)
  cn = floor(dmc/100)
  for (rni in seq(1, rn, by=1)){
    for (cni in seq(1, cn, by=1)){
      dri = (rni-1)*100+1
      uri = rni*100
      lci = (cni-1)*100+1
      rci = cni*100
      if(rni==rn) {
        uri = dmr
      }
      
      if(cni==cn) {
        rci = dmc
      }
      
      dsm_partf <- dsm_o[dri:uri,lci:rci]
      dsm_partf[is.na(dsm_partf)] <- 17
      tq = quantile(dsm_partf, 0.02)
      fishnet[dri:uri,lci:rci] <- tq
    }
  }
  fishnet.matrix <- apply(fishnet,2,c)
  fishnet_output <-raster(
    fishnet.matrix,
    xmn=dsm@extent[1], xmx=dsm@extent[2],
    ymn=dsm@extent[3], ymx=dsm@extent[4], 
    crs=CRS("+proj=utm +zone=17 +datum=WGS84")
  )
  fishnet_f = gsub("ortho_samples", "fishnet", img_path[i])
  fishnet_p = file.path(fishnet_folder, fishnet_f) 
  writeRaster(x = fishnet_output,
              filename = fishnet_p,
              format = "GTiff", # save as a tif
              datatype='FLT4S', # save as a INTEGER rather than a float
              overwrite = TRUE)  # OPTIONAL - be careful. This will OVERWRITE previous files
  
  # local maximum point acquisition
  gdal_info = GDALinfo(img_pathi)
  llx = gdal_info['ll.x']
  lly = gdal_info['ll.y']
  
  rx = gdal_info['res.x']
  ry = gdal_info['res.y']
  
  rown = gdal_info['rows']
  clmn = gdal_info['columns']
  
  x <- vector(mode="numeric",length=0)
  y <- vector(mode="numeric",length=0)
  
  rr <- vector(mode="numeric",length=0)
  cc <- vector(mode="numeric",length=0)
  
  for (j in seq(1, nrow(t_pos), by=1)){
    print(i)
    xi = t_pos[j,1]
    yi = t_pos[j,2]
    ri = round(rown-((yi-lly)/(ry)))
    ci = round((xi-llx)/rx)
    
    rr[j] = ri
    cc[j] = ci
    
    if((ri-5)>0 && (ri+5)<dmr && (ci-5)>0 && (ci+5)<dmc) {
      dsm_part = dsm.array[(ri-5):(ri+5),(ci-5):(ci+5),1]
      dsm_part[is.na(dsm_part)]<-0
      p <- (which(dsm_part == max(dsm_part), arr.ind=TRUE)-6)
      
      xi_p = (ci+p[1,2])*rx+llx
      yi_p = (rown-(ri+p[1,1]))*(ry)+lly
      
      x[j] = xi_p
      y[j] = yi_p
    } else {
      x[j] = xi
      y[j] = yi
    }
  }
  local_mp <- SpatialPoints(cbind(x, y), proj4string=CRS(as.character("EPSG:32617")))
  lm_f = gsub("ortho_samples_UTM.tif", "local_maximum.shp", img_path[i])
  lm_p = file.path(lm_folder, lm_f)    
  shapefile(local_mp, lm_p)
  
  # DEM Mask no data generation and export
  dsm.array <- dsm.array[1:dmr,1:dmc,1]
  df <- (dsm.array<fishnet+0.17)
  veg_mask.array <- veg_mask.array[1:dmr,1:dmc,1]
  dsm.array[df] = NA
  dsm.array[veg_mask.array == 0] = NA
  dsm.matrix <- apply(dsm.array,2,c)
  dsm_nomask <-raster(
    dsm.matrix,
    xmn=dsm@extent[1], xmx=dsm@extent[2],
    ymn=dsm@extent[3], ymx=dsm@extent[4], 
    crs=CRS("+proj=utm +zone=17 +datum=WGS84")
  )
  
  dsmn_f = gsub("ortho_samples", "dsm_nomask", img_path[i])
  dsmn_p = file.path(dsm_vm_folder, dsmn_f)  
  
  writeRaster(x = dsm_nomask,
              filename = dsmn_p,
              format = "GTiff", # save as a tif
              datatype='FLT4S', # save as a INTEGER rather than a float
              overwrite = TRUE)  # OPTIONAL - be careful. This will OVERWRITE previous files
  
  
}