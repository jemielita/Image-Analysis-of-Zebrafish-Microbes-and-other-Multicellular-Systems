%For a a given stack of images calculate the images in each region that
%overlap each other in the z direction. 
%SUMMARY: [data, param] = registerImagesZData(data,param);
%       Returns param.registerImZ which is a (N x number of regions) array,
%       where N is the total scan depth (over all regions) divided by the
%       step size. Each row contains the image number in each region that
%       is at that particular z depth. If no image in that region was found
%       at that z depth, the entry will be equal to -1.
function [data, param] = registerImagesZData(data,param)

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
end

%Now see which of these z positions overlap
overlapReg = -1*ones(length(posArray),totalNumRegions);

for regNum=1:totalNumRegions
    arr = imArray{regNum};
    for zIndex =1:length(arr)            
        overlapReg(find(posArray==arr(zIndex)),regNum) = zIndex-1;
        %-1 to deal w/ images syntax (starts at pco0.tif, because Rick was a CS major);
    end
end

param.registerImZ = overlapReg;

end