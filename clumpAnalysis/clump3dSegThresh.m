%clump3dSegThresh: Calculate properties of each clump found in this
%particular scan
%
% USAGE cc = clump3dSegThresh(param, maskAll, imMIP,ind, saveVal)
% AUTHOR Matthew Jemielita, April 2, 2014

function varargout = clump3dSegThresh(param, scanNum, colorNum, maskAll, imMIP,ind, saveVal, varargin)

%% Find properties of this component


switch nargin 
    case 7
        
        cc = clumpClass(scanNum, colorNum, param,ind);
    case 8
        cc = varargin{1};
end
mask = maskAll==ind;


if(sum(mask(:))<9)
    fprintf(1, 'Region too small! Skipping\n');
    return
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

cc.cropRect = cropRect;
cc.intenCutoff = cutoff;

cc.volume = sum(vol(:)>cutoff);
temp = vol(:);
cc.totalInten = sum(temp(temp>cutoff));

[~, ~,zRange] = getZRange(param, 'cropRect', cropRect);

r = sum(sum(vol>cutoff,1),2); r = squeeze(r);
if(sum(vol(:)>cutoff)==0)
    %If the spot isn't actually brighter than it's immediate
    %surroundings it's probably falsely labelled.
    cc.removeObj = true;
    return;
else
    cc.removeObj = false;
end

zMin = find(r~=0, 1, 'first') + zRange(1)-1;
zMax = find(r~=0, 1, 'last') + zRange(1)-1;

cc.zRange = [zMin, zMax];

%Find the point on the center gut line closest to the centroid of the clump
rp = regionprops(mask, 'Centroid');rp = rp.Centroid;
cl = param.centerLineAll{scanNum};

d = sqrt((cl(:,1)-rp(1)).^2 + (cl(:,2)-rp(2)).^2);
[~,cc.sliceNum] =  min(d);
cc.gutRegion  = find(cc.sliceNum > param.gutRegionsInd(cc.scanNum,:),1, 'last');


cc.save;

if(nargout==1)
    varargout{1} = cc;
end
end