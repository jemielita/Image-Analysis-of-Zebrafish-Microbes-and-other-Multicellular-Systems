%This function applies bpass.m to a composite gut plane.  Take note that
%intensities may be scaled differently than in the original image.
%
%Dependencies:
%       bpass.m
%       registerSingleImages.m
%
%Inputs:
%       param: Data structure given by
%       nScan: scan number
%       colorType: excitation wavelength as a string, e.g. '488nm'
%       zNum: row of interest in param.regionExtent.Z
%       lnoise: length scale of pixel noise (try using 1)
%       lobject: length of object of interest (remember to include clumps)
%
%12-16-2011 Mike Taormina

function filteredImage = bpassRegisteredSinglePlane(bigImage,param,lnoise,lobject)

poly = param.regionExtent.poly;
compositeSize = size(param.mask(:,:,1));
innerMask = roipoly(ones(compositeSize),poly(:,1),poly(:,2));
innerMask = padarray(innerMask,[lobject,lobject]);
outerMask = ~innerMask;


%load z plane using registerSingleImage.m
%bigImage = registerSingleImage(nScan,colorType,zNum,param);
%compositeImage = bigImage;
bigImage = padarray(bigImage,[lobject,lobject]);


%Construct a version of the image padded with random numbers around the
%outside
pad = randi(10000,compositeSize(1)+2*lobject,compositeSize(2)+2*lobject);
outerPad = pad.*outerMask;
paddedImage = outerPad + double(bigImage).*innerMask;
innerPad = ismember(paddedImage,0);
innerRandi = innerPad.*pad;
paddedImage = paddedImage+innerRandi;


%Apply bpass and then crop back to initial size
filteredImage = bpass(double(paddedImage),lnoise,lobject);
finalMask = ~(innerMask - ~innerPad);
filteredImage = double(filteredImage).*finalMask;
filteredImage = filteredImage(1+lobject:lobject+compositeSize(1),1+lobject:lobject+compositeSize(2));
