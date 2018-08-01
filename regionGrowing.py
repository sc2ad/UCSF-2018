import numpy as np
import cv2

def get8n(x, y, shape):
    out = []
    maxx = shape[1]-1
    maxy = shape[0]-1

    #top left
    outx = min(max(x-1,0),maxx)
    outy = min(max(y-1,0),maxy)
    out.append((outx,outy))

    #top center
    outx = x
    outy = min(max(y-1,0),maxy)
    out.append((outx,outy))

    #top right
    outx = min(max(x+1,0),maxx)
    outy = min(max(y-1,0),maxy)
    out.append((outx,outy))

    #left
    outx = min(max(x-1,0),maxx)
    outy = y
    out.append((outx,outy))

    #right
    outx = min(max(x+1,0),maxx)
    outy = y
    out.append((outx,outy))

    #bottom left
    outx = min(max(x-1,0),maxx)
    outy = min(max(y+1,0),maxy)
    out.append((outx,outy))

    #bottom center
    outx = x
    outy = min(max(y+1,0),maxy)
    out.append((outx,outy))

    #bottom right
    outx = min(max(x+1,0),maxx)
    outy = min(max(y+1,0),maxy)
    out.append((outx,outy))

    return out

def get4n(x, y, shape):
    out = []
    maxx = shape[1]-1
    maxy = shape[0]-1

    #top center
    outx = x
    outy = min(max(y-1,0),maxy)
    out.append((outx,outy))

    #left
    outx = min(max(x-1,0),maxx)
    outy = y
    out.append((outx,outy))

    #right
    outx = min(max(x+1,0),maxx)
    outy = y
    out.append((outx,outy))

    #bottom center
    outx = x
    outy = min(max(y+1,0),maxy)
    out.append((outx,outy))

    return out
# Performs seeded region growing, growing with all values below 'upperVal'.
# If type='8n', the 8 surrounding pixels for each pixel will be grown from
# If type='4n', the 4 'cross' pixels for each pixel will be grown from. Defaults to 4n
def region_growing(img, seed, upperVal, type='4n', animation=False):
    list = []
    outimg = np.zeros_like(img)
    list.append((seed[0], seed[1]))
    processed = []
    while(len(list) > 0):
        pix = list[0]
        outimg[pix[0], pix[1]] = 1
        surrounding = get4n(pix[0], pix[1], img.shape)
        if type=='4n':
            surrounding = get4n(pix[0], pix[1], img.shape)
        elif type=='8n':
            surrounding = get8n(pix[0], pix[1], img.shape)

        for coord in surrounding:
            if img[coord[0], coord[1]] < upperVal:
                outimg[coord[0], coord[1]] = 1
                if not coord in processed:
                    list.append(coord)
                processed.append(coord)
        list.pop(0)
        if animation:
            cv2.imshow("progress",outimg)
            cv2.waitKey(1)
    return outimg

class Region:
    def __init__(self, img):
        self.img = img
        self.shape = img.shape
        self.maxx = self.shape[1]-1
        self.maxy = self.shape[0]-1
        self.output = np.zeros_like(img)

        self.marked = []
    def inBounds(self, x, y):
        return x>0 and x<self.maxx and y>0 and y<self.maxy
    def canMove(self, x, y, upperVal):
        for i in range(-1,2,1):
            for j in range(-1,2,1):
                if self.inBounds(y+i,x+j) and not (y+i,x+j) in self.marked:
                    if self.img[y+i,x+j] < upperVal:
                        # This pixel can be moved to!
                        # Mark it and check to see if we can move from there.
                        self.marked.append((y+i,x+j))
                        self.output[y+i,x+j] = 1
                        self.canMove(x+j, y+i, upperVal) # Do i need to check something here? like a return condition?
        # We have exhausted all of our options. Stop.


    def region_growing_recursive(self, seed, upperVal):
        self.marked = [seed]
        self.canMove(seed[0], seed[1], upperVal)
