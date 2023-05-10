import arcpy
import os


DSM_NoVeg_DIR = "/dsm_no_vegtation/"
file_names = os.listdir(DSM_NoVeg_DIR)
arcpy.env.workspace = r"/dsm_no_vegtation/"

# output folder
raster_point_folder = "/raster_to_point/"
DTM_folder = "/dtm/"

for fi in file_names:
    if(fi.endswith('.tif')):
        print(fi)
        p = fi.find('.')
        point_shp_name = raster_point_folder+fi[0:p]+'_point.shp'
        q = arcpy.conversion.RasterToPoint(fi, point_shp_name)

        inPointFeatures = point_shp_name
        dtm_name = DTM_folder+fi[0:8]+'_dtm.tif'
        zField = "grid_code"
        cellSize = 0.01
        power = 2
        arcpy.CheckOutExtension("GeoStats")
        arcpy.LocalPolynomialInterpolation_ga(
            inPointFeatures, "grid_code", "outLPI", dtm_name, "0.01", "", arcpy.SearchNeighborhoodSmooth(20, 0.1, 0, 1), "EXPONENTIAL",
            "", "", "", "", "PREDICTION")
