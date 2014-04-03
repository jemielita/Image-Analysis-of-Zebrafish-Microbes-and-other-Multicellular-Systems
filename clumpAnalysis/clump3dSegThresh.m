%clump3dSegThresh: Calculate properties of each clump found in this
%particular scan
%
% USAGE cc = clump3dSegThresh(param, scanNum, colorNum, saveVal)
% AUTHOR Matthew Jemielita, April 2, 2014

function cc = clump3dSegThresh(param, scanNum, colorNum, saveVal)

%% Load in variables
fileDir = param.dataSaveDirectory;

inputVar = load([fileDir filesep 'bkgEst' filesep 'fin_' num2str(scanNum) '_' param.color{colorNum} '.mat']);

maskAll = inputVar.segMask;

imMIP = imread([fileDir filesep 'FluoroScan_' num2str(scanNum) '_' param.color{colorNum} '.tiff']);

fprintf(1, ['Scan: ', num2str(scanNum) '  color: ', param.color{colorNum}]);
%% Finding connected components

%Find all connected components
cc = bwconncomp(maskAll);
numEl =cc.NumObjects;

%Get bounding box for each one of these objects

%Preallocating space for arrays to calculate
cc.cropRect = zeros(numEl,4);
cc.intenCutoff = zeros(numEl,1);
cc.volume = zeros(numEl,1);
cc.totalInten = zeros(numEl,1);

cc.zRange = zeros(numEl,2);
cc.gutLoc = zeros(numEl,3);

for i=1:numEl
    fprintf(1, '.');
    mask = zeros(size(maskAll));
    
    mask(cc.PixelIdxList{i}) = 1;
    
    if(sum(mask(:))<9)
        fprintf(1, 'Region too small! Skipping\n');
        continue
    end
    
    x = sum(mask,2)>1;
    xMin = find(x==1, 1, 'first');
    xMax = find(x==1, 1, 'last');
    
    y = sum(mask,1)>1;
    yMin = find(y==1, 1, 'first');
    yMax = find(y==1, 1, 'last');
    
    cropRect = [yMin, xMin, yMax-yMin+1, xMax-xMin+1];
    imVar.zNum = '';imVar.scanNum = scanNum; imVar.color= param.color{colorNum};
    vol = load3dVolume(param, imVar, 'crop', cropRect);
    
    b = bwperim(bwmorph(mask, 'dilate')-bwperim(mask)); b = imMIP(b(:));
    
    cutoff = mean(b(:));
    
    % for i=1:size(vol,3)
    % imshow(vol(:,:,i), [0 1000]); alphamask(vol(:,:,i)<cutoff, [1 0 0]);
    % title(num2str(i./size(vol,3)));
    % pause(0.1)
    % end
    
    %Set output values
    
    cc.cropRect(i,:) = cropRect;
    cc.intenCutoff(i) = cutoff;
    
    cc.volume(i) = sum(vol(:)>cutoff);
    temp = vol(:);
    cc.totalInten(i) = sum(temp(temp>cutoff));
    
    [~, ~,zRange] = getZRange(param, 'cropRect', cropRect);
    
    r = sum(sum(vol>cutoff,1),2); r = squeeze(r);
    if(sum(vol(:)>cutoff)==0)
        %If the spot isn't actually brighter than it's immediate
        %surroundings it's probably falsely labelled.
        cc.removeObj = true;
        continue;
    else
        cc.removeObj = false;
    end
    zMin = find(r~=0, 1, 'first') + zRange(1)-1;
    zMax = find(r~=0, 1, 'last') + zRange(1)-1;
    
    cc.zRange(i,:) = [zMin, zMax];
    
    %Find the point on the center gut line closest to the centroid of the clump
    rp = regionprops(mask, 'Centroid');rp = rp.Centroid;
    cl = param.centerLineAll{scanNum};
    
    d = sqrt((cl(:,1)-rp(1)).^2 + (cl(:,2)-rp(2)).^2);
    [~,cc.gutLoc(i)] =  min(d);
    
end
fprintf(1, '\n');

if(saveVal==true)
    save([fileDir filesep 'bkgEst' filesep 'cc.mat'], 'cc');
end


end