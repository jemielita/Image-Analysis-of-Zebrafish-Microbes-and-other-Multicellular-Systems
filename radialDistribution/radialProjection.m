%radialProjection: Calculate a projection perpendicular to the center line
%through the gut down the entire length of the gut. This will be used to
%calculate the radial distribution of bacteria in the gut and also how the
%size of bacterial clusters changes down the length of the gut.
%
%USAGE radIm =  radialProjection(imStack, line, mask)
%      [radIm, origIndAll, rotIndAll, regWidth, regDepth] =
%      radialProjection(imStack, line, mask)
%       [radIm, ....]  = radialProjection(..., radIm, origIndAll,
%       rotIndAll, regWidth, regDepth);
%
%INPUT imStack: large array that contains a particular region of the gut
%      line: line through the center of the gut. The radial projection
%      will be done at at each point along this gut, with a depth equal to
%      the distance between points on this line. Note: because of this
%      indexing the first entry in this line won't be used (maybe want to
%      change this in the future)
%      mask: label matrix contains all the differen regions that we are
%      calculating the radial projections for.
%OUTPUT radIm: cell array containing the radial projection at each point
%       along the line
%      origIndAll: (optional) cell array containing the indices of all the
%      points in the original image that will be mapped onto the rotated
%      image, for calculating the projection
%      rotIndAll: (optional) cell array containing indices in the rotated
%      frame
%      regWidth: (optional) width of each of the regions
%      regDepth: (optional) depth of each of the regions.
% Note: origIndAll, rotIndAll, regWidth, and regDepth can be passed as
% input arguments to radialProjection to speed the code up.
%
% AUTHOR: Matthew Jemielita, August 12, 2012

function varargout = radialProjection(imStack, line, mask,varargin)
%Initialize arrays that we'll use for calculating the radial distribution.
maxZ = size(imStack,3);

if nargin==3
   if (nargout == 5)
       [radIm, origIndAll, rotIndAll,regWidth, regDepth] = getRegionIndices(line, mask, maxZ);
    
       radIm = getRegionMean(radIm, imStack, origIndAll, rotIndAll,regWidth, regDepth);
   elseif( nargout==1)
       radIm = getOnlyRegionMean(imStack, line, mask, maxZ);
       
   end
elseif nargin==8
    radIm = varargin{1};
    origIndAll = varargin{2};
    rotIndAll = varargin{3};
    regWidth = varargin{4};
    regDepth = varargin{5};
    %All arrays have been preallocated and indices calculated
    radIm = getRegionMean(radIm, imStack, origIndAll, rotIndAll,regWidth, regDepth);
else
    disp('Radial Projection must be called with either 3 or 6 inputs!');
    return
end

if nargout ==1
    varargout{1} = radIm;
elseif nargout ==5
    varargout{1} = radIm;
    varargout{2} = origIndAll;
    varargout{3} = rotIndAll;
    varargout{4} = regWidth;
    varargout{5} = regDepth;
end

end

function [radIm, origIndAll, rotIndAll,regWidth, regDepth] = getRegionIndices(line, mask, maxZ)
minL = 2;
maxL = size(line,1);

%Depth in z of our array
minZ = 1;
fprintf(1, 'Getting pixel information for radial distribution.');
parfor nL = minL:maxL
    
    fprintf(1, '.');
    xx = line(:,1);
    yy = line(:,2);
    
    x = xx(nL)-xx(nL-1);
    y = yy(nL)-yy(nL-1);
    
    %Get the angle this region makes with the y-axis
    theta = atan(y/x);
    theta = rad2deg(theta);
    
    %Let's do a fast rotation of points: find indices in the original region
    %that map onto the rotated region. This isn't entirely accurate at the
    %single pixel level, but it's quick.
    thisMask = mask==nL;
    thisMask = sum(thisMask,3); %Collapsing the mask to 2D
    
    %If this particular mask doesn't exist continue
    if(sum(thisMask(:))==0)
        continue
    end
    
    [y,x] = find(thisMask>0);
    minYo = min(y); maxYo = max(y);
    minXo = min(x); maxXo = max(x);
    
    %Find pixel indices in the original, uncropped image-we will use this to
    % pull the appropriate pixels when we want to do our averagin.
    ind = find(thisMask~=0);
    
    thisMask(:) = NaN;
    thisMask(ind) = ind;
    height = size(thisMask,1); width = size(thisMask,2);
    
    thisMask = thisMask(minYo:maxYo, minXo:maxXo);
    
    rotMask = imrotate(thisMask, theta);
    rotMask(rotMask==0) = NaN; %Because of padding around the rotated image
    
    rotInd = find(~isnan(rotMask));
    
    zList = (minZ:maxZ)-1;
    heightR = size(rotMask,1); widthR = size(rotMask,2);
    
    %Getting the indices in the rotated and unrotated frame for this mask
    rotOffset = repmat(heightR*widthR*zList, [length(rotInd),1]);
    
    rotIndAll{nL} = repmat(rotInd, [1 length(zList)])+rotOffset;
    
    origOffset = repmat(height*width*zList, [length(rotInd),1]);
    origIndAll{nL} = repmat(rotMask(rotInd), [1 length(zList)]) + origOffset;
   
    %Preallocating memory for radIm
    radIm{nL} = zeros(size(rotMask,1), maxZ-minZ+1);
    
    regWidth{nL} = size(rotMask,1);
    regDepth{nL} = size(rotMask,2);
    
end
fprintf(1, 'done!\n');

end

function radIm = getRegionMean(radIm, imStack,origIndAll, rotIndAll,regWidth, regDepth)
minL = 2;
maxL = length(radIm);

%Depth in z of our array
minZ = 1;maxZ = size(imStack,3);
fprintf(1, 'Calculating radial projection of masks.');
for nL = minL:maxL
    %mlj: NOTE: we're reallocating every single time...very inefficient!!
    thisRegion = NaN*zeros(regWidth{nL}, maxZ-minZ+1,regDepth{nL});
    thisRegion(rotIndAll{nL}(:)) = imStack(origIndAll{nL}(:));
    
    radIm{nL} = squeeze(nanmean(thisRegion,2));
    
    fprintf(1, '.');
end

fprintf(1, 'done!\n');

end


function  radIm = getOnlyRegionMean(imStack, line, mask, maxZ)

minL = 2;
maxL = size(line,1);

%Depth in z of our array
minZ = 1;
fprintf(1, 'Getting pixel information for radial distribution.');
for nL = minL:maxL
    
    fprintf(1, '.');
    xx = line(:,1);
    yy = line(:,2);
    
    x = xx(nL)-xx(nL-1);
    y = yy(nL)-yy(nL-1);
    
    %Get the angle this region makes with the y-axis
    theta = atan(y/x);
    theta = rad2deg(theta);
    
    %Let's do a fast rotation of points: find indices in the original region
    %that map onto the rotated region. This isn't entirely accurate at the
    %single pixel level, but it's quick.
    thisMask = mask==nL;
    thisMask = sum(thisMask,3); %Collapsing the mask to 2D
    
    %If this particular mask doesn't exist continue
    if(sum(thisMask(:))==0)
        continue
    end
    
    [y,x] = find(thisMask>0);
    minYo = min(y); maxYo = max(y);
    minXo = min(x); maxXo = max(x);
    
    %Find pixel indices in the original, uncropped image-we will use this to
    % pull the appropriate pixels when we want to do our averagin.
    ind = find(thisMask~=0);
    
    thisMask(:) = NaN;
    thisMask(ind) = ind;
    height = size(thisMask,1); width = size(thisMask,2);
    
    thisMask = thisMask(minYo:maxYo, minXo:maxXo);
    
    rotMask = imrotate(thisMask, theta);
    rotMask(rotMask==0) = NaN; %Because of padding around the rotated image
    
    rotInd = find(~isnan(rotMask));
    
    zList = (minZ:maxZ)-1;
    heightR = size(rotMask,1); widthR = size(rotMask,2);
    
    %Getting the indices in the rotated and unrotated frame for this mask
    rotOffset = repmat(heightR*widthR*zList, [length(rotInd),1]);
    
    rotIndAll = repmat(rotInd, [1 length(zList)])+rotOffset;
    
    origOffset = repmat(height*width*zList, [length(rotInd),1]);
    origIndAll = repmat(rotMask(rotInd), [1 length(zList)]) + origOffset;
   
    regWidth = size(rotMask,1);
    regDepth = size(rotMask,2);
   
    thisRegion = NaN*zeros(regWidth, maxZ-minZ+1,regDepth);
    thisRegion(rotIndAll(:)) = imStack(origIndAll(:));
    
    radIm{nL} = squeeze(nanmean(thisRegion,2));
    
    fprintf(1, '.');
    
end
fprintf(1, 'done!\n');

end