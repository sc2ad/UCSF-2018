import skimage.data
import skimage.io
import skimage.filters
import skimage.morphology
import skimage.transform
import skimage.color
from skimage import feature
from skimage import img_as_int
from skimage import img_as_uint
import numpy as np
import scipy
from scipy import ndimage, misc
import matplotlib.pyplot as plt

import regionGrowing as rg

import cv2

def show(image, final):
	fig, axes = plt.subplots(ncols=2, figsize=(8, 3))
	ax = axes.ravel()

	ax[0].imshow(image, cmap=plt.cm.gray)
	ax[0].set_title('Original image')

	ax[1].imshow(final, cmap=plt.cm.gray)
	ax[1].set_title('Result')

	for a in ax:
	    a.axis('off')

	plt.show()

def readUInt2(filename, size=[256,256]):
	im = np.fromfile(filename, dtype='uint16', sep="")
	im = im.newbyteorder()
	try:
		im = im.reshape(size) # This is the size of the images... if it isn't, fail
	except ValueError:
		# The image is an unexpected size!
		# Throw an error!
		raise ValueError("Image did not meet expected size: "+str(size))
	return im
def readInt2(filename, size=[256,256]):
	im = np.fromfile(filename, dtype='int16', sep="")
	im = im.newbyteorder()
	try:
		im = im.reshape(size) # This is the size of the images... if it isn't, fail
	except ValueError:
		# The image is an unexpected size!
		# Throw an error!
		raise ValueError("Image did not meet expected size: "+str(size))
	return im
def showFig(image, title):
	plt.figure()
	plt.title(title)
	plt.imshow(image, cmap='gray')
"""
FF_map   Threshold = Total_Fat
FF-edge_map Dilate erode + FF map (scaled?)  median filter?
3D? region grow in right ¼ of image, 5 pixels up from edge?   Get SAT

Total_Fat – SAT = VAT + bone
Midline up from SAT? assume region? Mask out….

ML –
Use SHINE, Tien, NAFLD, SUCRE ?? Data???
Tien + other covers thin & fat
"""

# image = skimage.io.imread("suc047_2_S21_F.int2")

# print(skimage.io.find_available_plugins())

# imageF = open("suc047_2_S21_F.int2", "rb")
# b = imageF.read()

# image = skimage.io.imread(imageF)
# imageF.close()

# skimage.io.imshow(image)

"""
Fatimage --> thresholded ~mean/10, fatimage > threshold = body mask
read new FF image --> body mask * FF image = body Fat Fraction
threshold body fat fraction with 50 --> create a total body fat fraction mask
read edge Fat Fraction --> edge detect --> dilate --> erode --> region grow (may need to add in edge Fat Fraction original image)
region grown creates mask (cause it works like that) --> called SAT Mask
Total body fat fraction mask - SAT mask = VAT mask
VAT = VAT Mask * body FF
"""

# PARAMS
fatimageThreshMeanFactor = 1 # Multiplied by mean to get thresholded image for fatimage
fatimageThreshValue = 70
useMean = False
# Edge Detection Parameters
EDGE_LOW = 130
EDGE_HIGH = 1000
EDGE_FF_THRESHOLD = 80
# Dilation and Erosion iterations
DILATION_ITERATIONS = 2
EROSION_ITERATIONS = 2

INTENSITY_SCALE = 105. # Intensity Scalar for edgemap
EFF_INTENSITY_SCALE = 2. # Intensity Scalar for eFF
# Seed [Y,X]
SEED = [176, 96]
REGION_GROWING_MAX = 103.


fatimage = readUInt2("Images/suc047_4_S10_F_I30.int2") # Negative values in here?
ffimage = readInt2("Images/suc047_4_S10_FF_I30.int2")
effimage = readInt2("Images/suc047_4_S10_eFF_I30.int2")

# Convert - signs in eFF to 0s
effimage[effimage < 0] = 0


showFig(fatimage, "Fat Original")
showFig(ffimage, "FF Original")
showFig(effimage, "eFF Original")

medianFat = ndimage.median_filter(fatimage, 3)

showFig(medianFat, "Median filtered Fat")

fatimageAvg = np.average(medianFat)
threshVal = fatimageAvg * fatimageThreshMeanFactor
if not useMean:
	# Uhhhhh
	# print("Something has gone terribly wrong. There are probably some outrageously high values in fatimage")
	# print(str(max(fatimage.any())))
	print("Using failsafe threshold of: "+str(fatimageThreshValue))
	threshVal = fatimageThreshValue
print(fatimageAvg)
bodyMask = medianFat > threshVal

showFig(bodyMask, "Body mask")

bodyFF = ffimage * bodyMask

showFig(bodyFF, "Body FF")

bodyFFMask = bodyFF > 50.

showFig(bodyFFMask, "Body FF Mask")

misc.imsave('temp.jpg', effimage)
edgeEFFImage = ndimage.imread('temp.jpg', 0)

showFig(edgeEFFImage, "Reloaded eFF")

edgeEffThresh = edgeEFFImage > EDGE_FF_THRESHOLD

showFig(edgeEffThresh, "Thresholded eFF ("+str(EDGE_FF_THRESHOLD)+")")

effEdges = cv2.Canny(edgeEffThresh*edgeEFFImage, EDGE_LOW, EDGE_HIGH)

showFig(effEdges, "eFF Canny Edge Detection")

struct2 = ndimage.generate_binary_structure(2, 2) # Creates a circle to dilate with instead of a cross
dilated = ndimage.morphology.binary_dilation(effEdges, structure=struct2, iterations=DILATION_ITERATIONS)
erodedEff = ndimage.morphology.binary_erosion(dilated, structure=struct2, iterations=EROSION_ITERATIONS)

showFig(erodedEff, "Dilated + Eroded eFF (After Canny Detection)")

regionGrowable = erodedEff * INTENSITY_SCALE + effimage * EFF_INTENSITY_SCALE

showFig(regionGrowable, "ErodedEFF + Original EFF")

plt.show(block=False)

# reg = rg.Region(regionGrowable)
# reg.region_growing_recursive(SEED, REGION_GROWING_MAX)
# outImg = reg.output
SATMask = rg.region_growing(regionGrowable, SEED, REGION_GROWING_MAX, animation=False)


showFig(SATMask, "SATMask")

bodyFFMask[bodyFFMask==True] = 1
bodyFFMask[bodyFFMask==False] = 0

VATMask = np.subtract(bodyFFMask, SATMask)

showFig(VATMask, "VATMask")

VAT = VATMask * bodyFF

showFig(VAT, "VAT")

image = skimage.color.rgb2gray(skimage.data.camera())
thresh = skimage.filters.threshold_mean(image)
binary = image > thresh





edges = feature.canny(binary)

# struct2 = ndimage.generate_binary_structure(2, 2) # Creates a circle to dilate with instead of a cross
# dilated = skimage.morphology.binary_dilation(binary, structure=struct2, iterations=DILATION_ITERATIONS)
# eroded = skimage.morphology.binary_erosion(dilated, iterations=EROSION_ITERATIONS)

# print(binary.shape)

# skimage.transform.rescale(image,2.0)
plt.show()
# plt.close()

# show(image, eroded)