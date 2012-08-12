function radIm = radialDist2(imStack, line, mask, radIm)
%Initialize arrays that we'll use for calculating the radial distribution.

minL = 2;
maxL = size(line,1);


%mlj: preallocating array slightly increases speed, but not by much (~1-2
%seconds)
%radIm = cell(maxL-minL+1,1);

maxZ = size(imStack,3);
[radIm, origIndAll, rotIndAll] = getRegionIndices(line, mask, maxZ);
    
radIm = getRegionMean(radIm, imStack, origIndAll, rotIndAll);
end

function [radIm, origIndAll, rotIndAll] = getRegionIndices(line, mask, maxZ)
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
    radIm{nL} = zeros(size(rotMask,1), size(rotMask,2));
    
end
fprintf(1, 'done!\n');

end

function radIm = getRegionMean(radIm, imStack,origIndAll, rotIndAll)
minL = 2;
maxL = length(radIm);

%Depth in z of our array
minZ = 1;maxZ = size(imStack,3);
fprintf(1, 'Calculating radial projection of masks.');
parfor nL = minL:maxL
    %mlj: NOTE: we're reallocating every single time...very inefficient!!
    thisRegion = NaN*zeros(size(radIm{nL},1),size(radIm{nL},2), maxZ-minZ+1);
    thisRegion(rotIndAll{nL}(:)) = imStack(origIndAll{nL}(:));
    
    radIm{nL} = squeeze(nanmean(thisRegion,2));
    
    fprintf(1, '.');

end
fprintf(1, 'done!\n');

end