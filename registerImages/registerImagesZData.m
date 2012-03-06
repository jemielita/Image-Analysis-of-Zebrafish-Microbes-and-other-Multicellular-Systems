%For a a given stack of images calculate the images in each region that
%overlap each other in the z direction. 
%SUMMARY: [data, param] = registerImagesZData(data,param);
%       Returns param.registerImZ which is a (N x number of regions) array,
%       where N is the total scan depth (over all regions) divided by the
%       step size. Each row contains the image number in each region that
%       is at that particular z depth. If no image in that region was found
%       at that z depth, the entry will be equal to -1.
function [data, param] = registerImagesZData(type, data,param)

switch lower(type)
    case 'original'
        param = registerOriginalImage(param);
    case 'crop'
        param = registerCroppedImage(param);
end


end

function param = registerCroppedImage(param)
 zCropRange = param.regionExtent.crop.z;
 
 zRange = param.regionExtentOrig.Z;
 zOldCropRange = param.regionExtentOrig.crop.z;
 
 zDepth = size(zRange,1);
 
 totalNumRegions = length(unique([param.expData.Scan.region]));
 
 for numReg = 1:totalNumRegions
     zMin = max(zOldCropRange(numReg,1), zCropRange(numReg,1));
     zMax = min(zOldCropRange(numReg,2), zCropRange(numReg,2));
     
     if(zMin>1)
         zRange(1:zMin-1, numReg) = -1;
     end
     
     if(zMax<zDepth)
         zRange(zMax+1:zDepth, numReg) = -1;
     end
     
     %Update the cropping box
     zCropRange(numReg,1) = zMin;
     zCropRange(numReg,2) = zMax;
         
 end
 
%Check to see if any rows contain just -1's. If so remove them-salient when cropping the z stack.
index = [];

notRegion = sum(zRange');
index = find(notRegion==-1*totalNumRegions);
zRange(index,:) = [];
param.regionExtent.Z = zRange;

param.regionExtent.Z = zRange;
param.regionExtent.crop.z = zCropRange;

end

    
    
function param = registerOriginalImage(param)

%Forcing all z Begin to be at the nearest multiple of the step size (and
%divisible by it).
for i=1:length([param.expData.Scan.zEnd])
    param.expData.Scan(i).zBegin = param.expData.Scan(i).zBegin -mod(param.expData.Scan(i).zBegin, param.expData.Scan(i).stepSize);

end

%Get the maximum and minimum z value.
%Note: the camera control software always makes sure that .zBegin < .zEnd,
%but we'll check to make sure this is true anyway.
testZ = [param.expData.Scan.zEnd]<[param.expData.Scan.zBegin];
if(sum(testZ)>0)
    disp('Z End location must be greater than z Begin location!');
    return;
end

minZ = min([param.expData.Scan.zBegin]);
maxZ = max([param.expData.Scan.zEnd]);

%Probably not appropriate, but let's round minZ and maxZ to the nearest
%micron (to deal with a problem with previous data collection-we didnt'
%require that all scans were taken at the same planes).
minZ = 10*round(minZ/10);
maxZ = 10*round(maxZ/10);

stepZ = unique([param.expData.Scan.stepSize]);

if(length(stepZ)~=1)
   disp('This code assumes the step size was the same for all scans. It isnt!')
   return;
end


posArray = minZ:stepZ:maxZ+stepZ;

%Construct a cell array of all the positions in the z-direction that images
%were taken at.
totalNumRegions = length(unique([param.expData.Scan.region]));
imArray = cell(totalNumRegions,1);

for regNum=1:totalNumRegions
    regIndex = find([param.expData.Scan.region]==regNum,1);
    
    imArray{regNum} = param.expData.Scan(regIndex).zBegin: param.expData.Scan(regIndex).stepSize:...
        param.expData.Scan(regIndex).zEnd+ param.expData.Scan(regIndex).stepSize;
    
    %Again, we shouldn't be doing this
    imArray{regNum} = 10*round(imArray{regNum}/10);
    
    %Again a little bit sketchy-force all z heights to be in even steps of
    %microns-this is do deal with the step size being 2 microns for the
    %long term scan.
    imArray{regNum} = imArray{regNum} + mod(imArray{regNum},2);
end

%Now see which of these z positions overlap
overlapReg = -1*ones(length(posArray),totalNumRegions);

for regNum=1:totalNumRegions
    arr = imArray{regNum};
    for zIndex =1:length(arr)-1            
        overlapReg(find(posArray==arr(zIndex)),regNum) = zIndex-1;
        %-1 to deal w/ images syntax (starts at pco0.tif, because Rick was a CS major);
        %Also only go up to length(arr)-1 for the same reason.
    end
end

%Check to see if any rows contain just -1's. If so remove them (happens at the end sometimes.
index = [];

notRegion = sum(overlapReg');
index = find(notRegion==-1*totalNumRegions);
overlapReg(index,:) = [];
param.regionExtent.Z = overlapReg;

%Load in the range of z levels for each scan into an array-this will later
%be pruned down by the user.
rangeZ = zeros(totalNumRegions,2);

for numReg = 1:totalNumRegions
    minZ = find( overlapReg(:,numReg) ==0);
    maxZ = find(overlapReg(:,numReg) ==max(overlapReg(:,numReg)));

    rangeZ(numReg, 1) = minZ;
    rangeZ(numReg,2) = maxZ;
end

  param.regionExtent.crop.z= rangeZ;
  
end


   