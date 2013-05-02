function spotLoc = combineRegions(spotLoc)
%Calculate the distance of each region to the nearest one-remove regions
%that are dimmer than any regions within a given radius of this region

maxNumReg = length(spotLoc);
radCutoffH =40; %Combine together all regions within radCutoff microns of each other
radCutoffV = 3; %Vertical distance cutoff
loc = [spotLoc(:).Centroid];
loc = reshape(loc, 3,length(spotLoc));
loc(1:2,:) = (0.1625)*loc(1:2,:); %Resize in z direction

inten = [spotLoc(:).MeanIntensity];

val = [inten; loc];

%[val, ind] = sort(val,2);

%Calculate distance of all points to all other ones
distH = dist(val(2:3,:));
distV = dist(val(4,:));

remInd = []; %Regions to cull out
for nR=1:maxNumReg
    thisDV = distV(:,nR);
    thisDH = distH(:,nR);
    closeD = find(thisDH<radCutoffH |thisDV<radCutoffV); closeD(closeD==nR) = [];
    if(prod(val(1,nR)<val(1,closeD))==0)
        remInd = [remInd, nR];
    end 
end

spotLoc(remInd)= [];
end