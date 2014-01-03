%neutrophilDist: Calculate properties of
% USAGE [spotDist, regList] = neutrophilDist(param, spotList, nC, nS)
function [spotDist, regList] = neutrophilDist(param, spotList, nC, nS)

scanNum = nS;

cL = param.centerLineAll{scanNum};

regList = [];

height = param.regionExtent.regImSize{1}(1);
width = param.regionExtent.regImSize{1}(2);

poly = param.regionExtent.polyAll{scanNum};
gutMask = poly2mask(poly(:,1), poly(:,2), height,width);


%From the gut masks find the regions in the total scanned image (incl.
%outside gut that are within different ~ regions of the gut.

%There are are three different regions that we want to count the number of
%neutrophils in:
% 1. Anterior of the EJ
% 2. Between the EJ and the end of the autofluorescent cells.
% 3. Past the autofluorescent cells.
% For the purposes of this analysis we will consider any neutrophils in
% region 1 & 3 to be outside the gut. There is often a large collection of
% neutrophils in region 3. even at the beginning of scans (this region of
% the fish is a reservoir of sorts for neutrophils) and region 1 is outside
% the gut proper (although it does contain neutrophils and large numbers of bacteria 
% in some examples and we should pay attention to the dynamics of this
% region more closely. 


%Find index corresponding to beginning and end of gut

pDist= dist(param.beginGutPos, cL');
[~, EJloc] = min(pDist);
if(EJloc==1)
    EJloc =2; %b.c getOrthVect uses the previous point in line to construct perp. vector.
end
pDist= dist(param.autoFluorEndPos, cL');
[~, gutEnd] = min(pDist);


%% Get mask for each of these three regions of the fish.
regionMask = zeros(size(gutMask,1), size(gutMask,2), 3);

%Region anterior of EJ
cutPosFinal = getOrthVect(cL(:,1), cL(:,2), 'rectangle', EJloc,2000);
pos = [[1,1];cutPosFinal(1,:);  cutPosFinal(2,:); [1,size(gutMask,1)]];

regionMask(:,:,1) = poly2mask(pos(:,1), pos(:,2), size(gutMask,1), size(gutMask,2));


%Gut proper
cutPosInit = getOrthVect(cL(:,1), cL(:,2), 'rectangle', EJloc, 2000);
cutPosFinal = getOrthVect(cL(:,1), cL(:,2), 'rectangle', gutEnd,2000);

pos = [cutPosInit(1,:); cutPosFinal(1,:); cutPosFinal(2,:); cutPosInit(2,:) ];

regionMask(:,:,2) = poly2mask(pos(:,1), pos(:,2), size(gutMask,1), size(gutMask,2));

%Posterior of the gut is everything not in the first two regions

regionMask(:,:,3) = ~(regionMask(:,:,1)+regionMask(:,:,2))>0;

%Region creation kind of clumsy, but works for now.

for i=1:3
    regionMask(:,:,i) = i* regionMask(:,:,i);
end


%% Find which spots are in different regions
nC = 1;

regLoc = zeros(size(spotList{nC},1),1);

for i=1:size(spotList{nC},1)
    thisPos = spotList{nC}(i,1:2);
    thisPos = round(thisPos);
   
    %Check to see which region its in
    for nR =1:3
        if( regionMask(thisPos(2), thisPos(1),nR)~=0)
            regLoc(i) = nR;
        end
    end
    
end

 
 %Testing code
 plotData = false;
 if(plotData==true)
     figure; imshow(gutMask+ 2*regionMask(:,:,1)+ 3*regionMask(:,:,2) + 6*regionMask(:,:,3), [])
     hold on
     plot(spotList{1}(regLoc==1,1), spotList{1}(regLoc==1,2), '*')
     plot(spotList{1}(regLoc==2,1), spotList{1}(regLoc==2,2), 'o')
     plot(spotList{1}(regLoc==3,1), spotList{1}(regLoc==3,2), '*')
end
    
%% Get distance of each of the neutrophils in the gut from the gut itself

ind = find(regLoc==2);

for i=1:length(ind)
    pDist= dist(spotList{nC}(ind(i),:), cL');
    [spotDist(i,1), spotDist(i,2)] = min(pDist);
    spotDist(i,1) = 0.1625*spotDist(i,1);
end


%% Get distance of neutrophil to the gut border.


end






