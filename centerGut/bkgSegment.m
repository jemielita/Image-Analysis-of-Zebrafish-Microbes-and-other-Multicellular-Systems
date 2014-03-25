%bkgSegment: Calculate the approximate mask that will be used to do our
%course grained analysis of the gut
%
% USAGE segMask = bkgSegment(centerLine, scanNum, colorNum, param)
%
% INPUT: scanNum and colorNum: which color and scan to calculate the
%         background estimator for.
%        
%        param: This fish's parameter file
% OUTPUT segMask: binary mask for 

function segMask = bkgSegment(scanNum, colorNum, param)
%Load in all the masks
inputVar =  load([param.dataSaveDirectory filesep 'masks' filesep 'maskUnrotated_' num2str(scanNum) '.mat']);
gutMask = inputVar.gutMask;

%Load in estimated background
inputVar = load([param.dataSaveDirectory filesep 'bkgEst' filesep 'bkgEstAll.mat']);
bkgEst = inputVar.bkgEstAll{colorNum}{scanNum};

segMask = zeros(size(gutMask,1), size(gutMask,2));

for nM = 1:size(gutMask,3)
    thisMask = gutMask(:,:,nM);
    uniqEl = unique(thisMask);
    uniqEl = setdiff(uniqEl, 0);
    for i=1:length(uniqEl)
        segMask(thisMask==uniqEl(i))= bkgEst(uniqEl(i));
    end
end

%Quick and dirty filling in here of the blank spots-this code should be
%moved to the main gut mask making code
poly = param.regionExtent.polyAll{scanNum};
gutOutline = poly2mask(poly(:,1), poly(:,2), size(segMask,1), size(segMask,2));

%Find all points on the edge of the wedges we found
regEdge =bwperim(segMask>0);
[x,y] = find(regEdge==1);
%Find all points inside the gut that we haven't assigned to a region
[x2,y2] = find((gutOutline- (segMask>0))==1);

%For each unassigned point find the closest wedge
for i=1:length(x2)
   distM = sqrt((x2(i)-x ).^2 +(y2(i)-y).^2); 
   [~,ind] = min(distM);
   segMask(x2(i), y2(i)) = segMask(x(ind), y(ind));
end







end
