function spotLoc = combineRegions(spotLoc, varargin)

if(isempty(spotLoc))
    return
end
%Calculate the distance of each region to the nearest one-remove regions
%that are dimmer than any regions within a given radius of this region

maxNumReg = length(spotLoc);
radCutoffH =40; %Combine together all regions within radCutoff microns of each other
radCutoffV = 3; %Vertical distance cutoff

switch nargin
    case 1
    radCutoff = 10;
    case 2
    radCutoff = varargin{1};
    otherwise
        fprintf(2, 'Wrong number of inputs to combineRegions!');
end

loc = [spotLoc(:).CentroidOrig];
loc = reshape(loc, 3,length(spotLoc));

loc(1:2,:) = (0.1625)*loc(1:2,:); %Resize in z direction

inten = [spotLoc(:).MeanIntensity];

val = [inten; loc];

%[val, ind] = sort(val,2);

%Calculate distance of all points to all other ones
distH = dist(val(2:3,:));
distV = dist(val(4,:));

distA = dist(val(2:4,:));

remInd = []; %Regions to cull out


%Get a ~ radius of each region by finding the maximum width of the bounding
%box

for nR=1:maxNumReg
    %Rescale bounding box
    spotLoc(nR).BoundingBox(4:5) = (0.1625)*spotLoc(nR).BoundingBox(4:5);
    spotLoc(nR).EffRadius = max([spotLoc(nR).BoundingBox(4:6)])/2;
end

for nR=1:maxNumReg
    
 %   thisD = distA(:,nR)-spotLoc(nR).EffRadius-[spotLoc(nR).EffRadius];
  thisD = distA(:,nR);
  closeD = find(thisD<radCutoff); closeD(closeD==nR) = [];
    %    thisDV = distV(:,nR);
    %   thisDH = distH(:,nR);
    %  closeD = find(thisDH<radCutoffH |thisDV<radCutoffV); closeD(closeD==nR) = [];
   
    if(~isempty(closeD))
        if(prod(double(val(1,nR)<val(1,closeD)))==0)
            remInd = [remInd, nR];
        end
    end
end

spotLoc(remInd) = [];
end