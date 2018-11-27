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
    
    if(nargout==1)
        varargout{1} = cc;
    end
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

%Sanity check our regions-if something went wrong just return
 b = bwperim(bwmorph(mask, 'dilate')-bwperim(mask)); 
 b = imMIP(b(:));

cutoff = mean(b(:));

cc.cropRect = cropRect;
cc.intenCutoff = cutoff;

cc.volume = sum(vol(:)>cutoff);
temp = vol(:);
cc.totalInten = sum(temp(temp>cutoff));

[~, ~,zRange] = getZRange(param, 'cropRect', cropRect);

bw = vol>cutoff;

rp = bwconncomp(bw);

if(length(rp)>1)
   b = 0; 
end

r = sum(sum(bw,1),2); r = squeeze(r);

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
%mlj:Note: this is a mildly goofy way to do this: one shouldn't calculate
%regionprops for the full image, but instead calculate the centroid of the
%volume and then add the x, y offset for this volume....will be changed in
%the future.
rp = regionprops(mask, 'Centroid');rp = rp.Centroid;
cl = param.centerLineAll{scanNum};
cc.centroid = rp;
d = sqrt((cl(:,1)-rp(1)).^2 + (cl(:,2)-rp(2)).^2);
[~,cc.sliceNum] =  min(d);
cc.gutRegion  = find(cc.sliceNum > param.gutRegionsInd(cc.scanNum,:),1, 'last');

%Calculate the intensity in each slice of the gut
gutMask = cc.loadGutMask;
cc = cc.calculateThisSliceInten(vol, gutMask);


%Calculate a 3d mesh for each region
%[node,elem,face]=v2m(bw,0.7,5,40);
%cc.mesh = struct('node', node, 'elem', elem, 'face',face);
% 
% imshow(max(vol,[],3),[]);
% pause
fprintf(1, '.');

if(saveVal==true)
    cc.save;
end

if(nargout==1)
    varargout{1} = cc;
else

    clear all
end

end