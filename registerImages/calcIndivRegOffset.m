%calcIndivRegOffset: Calculate the (x,y) location in the whole gut
%reference frame that individual cropped regions map to
%
% USAGE: param = calcIndivRegOffset(param, updateParam)
%
% INPUT: param: gut parameter file
%        updateParam: true/false: Save the param file with the region
%        offsets
%        
% OUTPUT: param (optional): updated parameter file
%         param file will be updated to include the following field:
%         param.regionExtent.indivReg(nS,nR, xOffSet,yOffset): the x, y
%         offset for each scan and region

function varargout = calcIndivRegOffset(param, updateParam)

%Get number of scans and regions
minS = 1;
maxS = param.expData.totalNumberScans;


if(isfield(param.expData.Scan, 'isScan'))
    totalNumRegions = unique([param.expData.Scan.region].*[strcmp('true', {param.expData.Scan.isScan})]);
else
    totalNumRegions = unique([param.expData.Scan.region]);
end
totalNumRegions(totalNumRegions==0) = [];

totalNumRegions = length(totalNumRegions);

height = param.regionExtent.regImSize{1}(1);
width = param.regionExtent.regImSize{1}(2);

fprintf(1, 'Calculating indvidual region offset');
for nS=minS:maxS
    
    %Make gut masks
    
    polyX = param.regionExtent.polyAll{nS}(:,1);
    polyY = param.regionExtent.polyAll{nS}(:,2);
    gutMask = poly2mask(polyX, polyY, height, width);
    
    for nR=1:totalNumRegions
        thisRegion = param.regionExtent.XY{1};
        xOutI = thisRegion(nR,1);
        xOutF = thisRegion(nR,3)+xOutI-1;
        
        yOutI = thisRegion(nR,2);
        yOutF = thisRegion(nR,4)+yOutI -1;
        
        thisMask = gutMask(xOutI:xOutF, yOutI:yOutF);

        %Find smallest cropping region
        xMin = find(sum(thisMask,2)~=0,1,'first');
        xMax = find(sum(thisMask,2)~=0, 1, 'last');
        
        yMin = find(sum(thisMask,1)~=0, 1, 'first');
        yMax = find(sum(thisMask,1)~=0, 1, 'last');
        
        thisMask = thisMask(xMin:xMax, yMin:yMax);
       
        param.regionExtent.indivReg(nS,nR,1:4) = [xMin+xOutI, yMin+yOutI, xMin, yMin];
        
    end
    
    
    fprintf(1, '.');
end
fprintf(1, '\n');

if(updateParam==true)
    fprintf(1, 'Parameter file updated!\n');
    save([param.dataSaveDirectory filesep 'param.mat'], 'param');
else
   fprintf(1, 'Not updating parameter file.\n'); 
end

if nargout==1
    varargout{1} = param;
end

end