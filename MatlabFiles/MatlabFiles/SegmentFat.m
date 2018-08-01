clear all; close all; clc
%load images
current_dir = pwd;

%input = readidf_file_pc(current_file, current_dir);
%See help for options, esp for different operating systems
%image data will be stored in input.img

%Pre Diet 
current_file = 'data/suc047_4_S10';
%strcat(current_file, '_In')
VATslice = 30;  %15 if counting from first slice, 30 if counting from superior end
Inr = read_idf_image_pc(strcat(current_file, '_In'), current_dir, 0);
Outr = read_idf_image_pc(strcat(current_file, '_Out'), current_dir, 0);
Fatr = read_idf_image_pc(strcat(current_file, '_F'), current_dir, 0);
Wr = read_idf_image_pc(strcat(current_file, '_W'), current_dir, 0);

%Post Diet
current_file = 'data/suc047_2_S21';
VATslice = 27;   %18 if counting from first slice (inferior), 27 if counting
%from superior end
%Inr = read_idf_image_pc(strcat(current_file, '_In'), current_dir, 0);
%Outr = read_idf_image_pc(strcat(current_file, '_Out'), current_dir, 0);
%Fatr = read_idf_image_pc(strcat(current_file, '_F'), current_dir, 0);
%Wr = read_idf_image_pc(strcat(current_file, '_W'), current_dir, 0);

%record image size parameters
img_size = size(Inr.img(:,:,:))
img_rl = img_size(1);
img_ap = img_size(2);
num_slices = img_size(3);
%other methods of collecting information: im.data, im.img

%Rotate and Flip the images to be in matlab-style format
for j=1:num_slices
    Fat(:,:,j) = flipud(imrotate(Fatr.img(:,:,j),90));
    W(:,:,j) = flipud(imrotate(Wr.img(:,:,j),90));
    In(:,:,j) = flipud(imrotate(Inr.img(:,:,j),90));
    Out(:,:,j) = flipud(imrotate(Outr.img(:,:,j),90));
end

%Get max of scanned image - In-phase MRI
maxIn = max(max(max(Inr.img)))

%display the image by slice
figure('Name', strcat('Original Image: ', current_file))
for j=1:img_size(3)
    imagesc(In(:,:,j),[0,maxIn]/4)
    axis image
    title({'In Phase: Slice',j});
    colormap gray
    pause(0.1)
end

%Calculate Fat Fraction Map in [%]
%Set FF dynamic range
maxFF=100;
FF= (maxFF * Fat) ./ (Fat+W);

%Create Body/Good SNR Mask
%Threshold an image set
Inmask = In>100;
%Apply a 2D filter to the mask
for j=1:num_slices
    BodyMask(:,:,j)=medfilt2(Inmask(:,:,j), [2,2]);
end

%Evaluate filter
figure('name','Body/ SNR Mask')
subplot(1,2,1);
imagesc(In(:,:,VATslice));
title('In Phase');
subplot(1,2,2);
imagesc(BodyMask(:,:,VATslice));
title('Body/SNR Mask');
colormap gray;

%Apply this Body/SNR Mask to the FF map
mFF = BodyMask .* FF;

%Select Slice of Interest
FFv=FF(:,:,VATslice);
Inv=In(:,:,VATslice);
Fatv=Fat(:,:,VATslice);
BodyMaskv = BodyMask(:,:,VATslice);
mFFv = mFF(:,:,VATslice);

%Part II-6 - Display FF, Body/SNR mask, mFF
figure('name','FF, Body Mask, mFF')
subplot(1,3,1);
imagesc(FFv);
title('FF');
subplot(1,3,2);
imagesc(BodyMask(:,:,VATslice));
title('Body/SNR Mask');
colormap gray;
subplot(1,3,3);
imagesc(mFFv);
title('masked FF');
colormap gray;

%%

%Manually Draw Visceral Fat ROI
figure('name','FF')
%imagesc(FFv,[0,maxFF]);
imagesc(FFv);
title('Manually Draw ROI of VAT');
colormap gray
tic
freehandroi=imfreehand(gca);
manVATmask=createMask(freehandroi);
manVATtime=toc
%%
%Part III - A2 - Save image w/ drawn ROI

%Characterize VAT ROI - histogram, size in pixels, mean, median, std
figure('name','Manual VAT FF')
histogram(FFv(manVATmask));
sizemanVATmask = sum(sum(manVATmask)),
manVATmean = mean(FFv(manVATmask)),
manVATmedian = median(FFv(manVATmask)),
manVATsd = std(FFv(manVATmask))

%Semiautomatically Generate VAT ROI - 

%Manually Draw Visceral ROI
figure('name','FF-Viscera>50')
imagesc(FFv);
title('Manually Draw ROI of entire visceral region');
colormap gray
%start timer
tic
freehandroi=imfreehand(gca);
viscmask=createMask(freehandroi);
%end timer
visctime=toc

%A-Full dataset
viscFF = viscmask .* FFv;

figure('name','Viscera');
histogram(FFv(viscmask));
title('Viscera FF Histogram, on FF');

VATmask = viscFF>50;
figure('name','VAT in Viscera, Full FF');
histogram(FFv(VATmask));
title('VAT ROI Histogram, on FF');

sizeVATmask = sum(sum(VATmask))
VATmean = mean(FFv(VATmask))
VATmedian = median(FFv(VATmask))
VATsd = std(FFv(VATmask))


%Semiautomatically generate VAT on masked FF map

%B-Use masked FF map - add following code
viscmFF = viscmask .* mFFv;

figure('name','Viscera on Masked FF');
histogram(FFv(viscmask));
title('Viscera mFF Histogram, on masked FF');

mVATmask = viscmFF>50;
figure('name','VAT on Masked FF');
histogram(mFFv(mVATmask));
title('VAT ROI Histogram, on masked FF');

sizemVATmask = sum(sum(mVATmask))
mVATmean = mean(FFv(mVATmask))
mVATmedian = median(FFv(mVATmask))
mVATsd = std(FFv(mVATmask))

%%
%Use Manually Draw Visceral ROI * masked FF

%Display Masks
figure('name','VAT Masks')
subplot(2,3,1);
imagesc(FFv,[0,maxFF]);
title('Fat Fraction');
subplot(2,3,2);
imagesc(manVATmask);
title('Manual VAT ROI');
subplot(2,3,3);
imagesc(viscmask);
colormap gray
title('Manual Viscera ROI');
subplot(2,3,4);
imagesc(VATmask)
title('VAT ROI on FF');
colormap gray
subplot(2,3,5)
imagesc(mVATmask)
title('VAT ROI on mFF');
colormap gray
subplot(2,3,6)
imagesc(BodyMask(:,:,VATslice))
title('Body/SNR Mask');
colormap gray

%Dice
combine=VATmask+manVATmask;
intersect = combine > 1;
union = combine > 0;
sizeintersect = sum(sum(intersect));
sizeunion = sum(sum(union));
dice = 2* sizeintersect / (sizeunion +sizeintersect) ;
percdiff = 100 * (sizeVATmask - sizemanVATmask) / (sizemanVATmask);


%Scale for display purposes
VATmask= 2 * VATmask;
combine=VATmask+manVATmask;
figure('name','ROI Analyses')
subplot(1,3,1)
imagesc(manVATmask);
title('Manual VAT ROI');
subplot(1,3,2)
imagesc(VATmask);
title('Semiautomatic VAT ROI');
subplot(1,3,3)
imagesc(combine);
title('VAT ROI Overlap');

%Summary of Results
disp(sprintf('Parameter        Manual VAT        Semiauto VAT'))
disp(sprintf('Size(#pixels)    %10.0f            %10.0f',sizemanVATmask, sizeVATmask))
disp(sprintf('Mean VAT:          %8.2f               %8.2f',manVATmean, VATmean))
disp(sprintf('SD VAT:            %8.2f               %8.2f',manVATsd, VATsd))
disp(sprintf('Median VAT:        %8.2f               %8.2f',manVATmedian, VATmedian))
disp(sprintf('Dice = %5.1f',dice))
disp(sprintf('Size semiauto VAT as Percent Difference of Manual VAT Size = %5.1f',percdiff))

%%
%Total Fat - Here just calculating on visceral fat slice
TFFv = FFv>50;
TFF3v = mFFv>50;
%figure('name','Total FF')
%imagesc(TFFv)
%colormap gray
figure('name','Total masked FF')
imagesc(TFF3v)
colormap gray
sizetotalfat=sum(sum(TFFv))
sizetotalfat3=sum(sum(TFF3v))

Allmask = TFF3v - VATmask;
SATmask = Allmask > 0;
sizeSAT = sum(sum(SATmask));
disp(sprintf('Size SAT (#pixels) = %5.1f',sizeSAT))

figure('name','FAT masks')
subplot(2,2,1)
colormap gray
imagesc(FFv,[0,maxFF])
title('Fat Fraction')
subplot(2,2,2)
imagesc(VATmask)
title('VATmask')
subplot(2,2,3)
imagesc(SATmask)
title('SAT mask')
subplot(2,2,4)
imagesc(Allmask)
title('All masks')


