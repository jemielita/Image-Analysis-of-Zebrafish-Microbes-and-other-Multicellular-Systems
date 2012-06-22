%After finding the approximate correct registration, go through pixel
%values near the optimal position to find the optimal registration-as given
%by the registration that minimizes the square of the difference of pixel
%intensities 
%Code to load in different regions lifted from registerSingleImage.m

function param = optimalRegistration(regNum1, regNum2,nScan, zNum, colorType,param)

%Base directory for image location
baseDir = [param.directoryName filesep 'Scans' filesep];
%Going through each scan
scanDir = [baseDir, 'scan_', num2str(nScan), filesep];
%And each color (in the debugging phase, we'll restrict ourselves
%to one color

imNum = param.regionExtent.Z(zNum,:);
%Load in the associated images

im = zeros(param.regionExtent.regImSize);
im = uint16(im); %To match the input type of the images.

images = cell(2,1);
regions = [regNum1, regNum2];

for i=1:2
    regNum = regions(i);
    
    %Get the range of pixels that we will read from and read out to.
    xOutI = param.regionExtent.XY(regNum,1);
    xOutF = param.regionExtent.XY(regNum,3)+xOutI-1;
    
    yOutI = param.regionExtent.XY(regNum,2);
    yOutF = param.regionExtent.XY(regNum,4)+yOutI -1;
    
    xInI = param.regionExtent.XY(regNum,5);
    xInF = xOutF - xOutI +xInI;
    
    yInI = param.regionExtent.XY(regNum,6);
    yInF = yOutF - yOutI +yInI;
    
    if(imNum(regNum)~=-1)
        imFileName = ...
            strcat(scanDir,  'region_', num2str(regNum),filesep,...
            colorType, filesep,'pco', num2str(imNum(regNum)),'.tif');
        
        images{i} = imread(imFileName,...
            'PixelRegion', {[xInI xInF], [yInI yInF]});
        
    end
    
    offsetX(i,1) = xOutI; offsetX(i,2) = xOutF; 
    offsetY(i,1) = yOutI; offsetY(i,2) = yOutF;
    
end



%Get the region of overlap between these pictures for a given offset of the
%images

%Hold the first region still and move the second one around
offsetXInit = offsetX;  offsetYInit = offsetY;
n=1;

oR1 = images{1};
oR2 = images{2};
for xD=-200:5:0
    for yD= -200:5:200
        offsetX(2,:) = offsetXInit(2,:)+xD;
        offsetY(2,:) = offsetYInit(2,:)+yD;
        
        width = offsetY(1,2)-offsetY(2,1);
        height = min(offsetX(1,2),offsetX(2,2))-max(offsetX(1,1),offsetX(2,1));
        
       
        xI2 = max(1,offsetX(1,1)-offsetX(2,1));
        % oR2 = oR2(xI:xI+height,1:width);
        
        xI1 = max(1,offsetX(2,1)-offsetX(1,1));
        %oR1 = images{1};
        %oR1 = oR1(xI:xI+height,end-width+1:end);
        
        temp =(oR2(xI2:xI2+height,1:width)-...
            oR1(xI1:xI1+height,end-width+1:end)).^2;
        temp = sqrt(double(temp));
        error = sum(sum(temp));
        
        regVal(n,:) = [offsetX(2,1), offsetY(2,1), error];
        
        n = n+1;
    end
 
end




end