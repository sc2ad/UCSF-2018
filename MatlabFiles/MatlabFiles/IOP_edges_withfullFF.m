%%Edge Detect and Region Fill to Segment SAT
%
clear all; close all; clc
%constants
edgedetectthreshold = 8;
current_dir = pwd;
current_file = '../MRFat/data/suc047_4_S10';
VATslice = 30;  %15 if counting from first slice, 30 if counting from superior end

%Load images
%input = readidf_file_pc(current_file, current_dir);
%See help for options, esp for different operating systems
%image data will be stored in input.img

Inr = read_idf_image_pc(strcat(current_file, '_In'), current_dir, 0);
Outr = read_idf_image_pc(strcat(current_file, '_Out'), current_dir, 0);
FullFFr = read_idf_image_pc(strcat(current_file, '_FF'), current_dir, 0);

%record image size parameters
img_size = size(Inr.img(:,:,:));
num_slices = img_size(3);

%Rotate and Flip the images to be in matlab-style format
for j=1:num_slices
    In(:,:,j) = flipud(imrotate(Inr.img(:,:,j),90));
    Out(:,:,j) = flipud(imrotate(Outr.img(:,:,j),90));
    FullFF(:,:,j) = flipud(imrotate(FullFFr.img(:,:,j),90));
end


%% Calculate Fat Fraction Map, based on In-phase and Out-of-phase images, in [%]
%Set FF dynamic range
maxFF=100;
FF = (maxFF/2) * (In - Out)./ In;

%Remove NaN, Inf, -Inf
for i = 1:img_size(1)
   for j=1:img_size(2)
       for k = 1:img_size(3)
        if isnan(FF(i,j,k)) 
        FF(i,j,k) = 0;
        elseif isinf(FF(i,j,k))
            FF(i,j,k) = 0;
        end
       end
   end
end

%% Edge Detect FF slice of interest
%Edge detect FFmap (with no NaN & no Inf)

%Use Slice of Interest
%>>>>>>>>>>

FF30=FF(:,:,VATslice);
%<<<<<<<<<<

%>>>>>>>>>>>>
%Edge detect, can use EdgeMap = edge(Image);
%see help edge
%The default uses 'sobel' and find a threshold. This threshold will likely
%be poor.  You can modify the automatic threshold or specify one.

%One method to find a threshold based on the image data
%[~, threshold] = edge(FF30, 'sobel')
%fudgeFactor = xxx;    %make a threshold relative to the automatically
%found one
%EdgeMap = edge(FF30,'sobel', threshold * fudgeFactor);

%Or use a specific threshold (constant listed at the top of the m-file.
%
%Edge detect FFmap (with no NaN & no Inf)
EdgeMap = edge(FF30,'sobel', edgedetectthreshold);

%<<<<<<<<<<<<


%Display FF map and Edge detected mask
%>>>>>>>>>>>>>>>
figure, imagesc(FullFF(:,:,VATslice),[0,100]), colormap gray, title('FullFF');

figure, imagesc(FF30,[0,50]), colormap gray, title('FF30');

figure, imagesc(EdgeMap), colormap gray, title('Edges Mask');
%<<<<<<<<<<<<<<<<

%Define structure elements -- basic shapes to identify in the image
%Here are lines, - can make vertical, horizontal, 2 diagonals (+45deg and -45deg)
%set the size of each element (can vary) and orientation:
%Can try other shapes, i.e. 'disk' (filled circle)

%>>>>>>>>>>>>>>

help strel
%e.g.  se90 = strel('line', size, degrees);
se90 = strel('line',3,90);
se0  = strel('line',2,0);
se45 = strel('line',3,45);
se135 = strel('line',3,-45);

%
%This element is a disk = filled circle:
sedisk = strel('disk',3);

%<<<<<<<<<<<<

%Dilate the FF slice and the edgemap using struct elements:
%>>>>>>>>>>>>>>>>>
help imdilate
%EdgeMapdil = imdilate(EdgeMap, [list of struct elements ]);
EdgeMapdil = imdilate(EdgeMap,sedisk);
%FFdil = imdilate(FF30,[se90,se0,se45,se135]);
FFdil = imdilate(FF30,sedisk);

%<<<<<<<<<<<<<<<<<<<<

%Display the dilated images
%>>>>>>>>>>>>>>>>>>
figure, imagesc(FFdil,[0,100]), title('Dilated FF'); colormap gray;

figure, imagesc(EdgeMapdil,[0,1]), colormap gray, title('Dilated edges mask');
%<<<<<<<<<<<<<

%%Erode the images and display
help imerode;
%>>>>>>>>>>>>>>>

FFdil = imerode(FFdil, sedisk);
%FFdil = imerode(FFdil,[se90,se0,se45,se135]);
figure, imagesc(FFdil,[0,100]); title('eroded, dilated FF'); colormap gray;
EdgeMapdil = imerode(EdgeMapdil,sedisk);
%BWsdil = imerode(BWsdil,[se90,se0,se45,se135]);
figure, imagesc(EdgeMapdil,[0,1]), colormap gray, title('eroded,dilated Edge Map');
%<<<<<<<<<<<<<<<<<<

%% Alternate working image method
%Create working image as a combination of the original FFmap + the dilated+eroded, edge
%detected image
EdgeMapdil = EdgeMapdil * 100;
workIm = EdgeMapdil + FF30;
figure('name','workIm=EdgeMap+FF'); imagesc(workIm); colormap gray;

%% Region Grow & Display the 2 eroded, dilated images
[SATpoly,SATmask] = regionGrowing(FFdil,[175,75],1,16);
figure('name','SATmask-FFdil'); imagesc(SATmask); colormap gray;

[SATpoly,SATmask] = regionGrowing(EdgeMapdil,[175,75],1,10);
figure('name','SATmask-erode/dilate Edges'); imagesc(SATmask); colormap gray;

[SATpoly,SATmask] = regionGrowing(workIm,[175,75],1,23);
figure('name','SATmask-workIm'); imagesc(SATmask); colormap gray;




%%


