%regionOverlap: Get the regions in our image that are contained within a
%given cropping rectangle
%
%USAGE [regList, overlap] = regionOverlap(param, cropRect)
%
%AUTHOR Matthew Jemielita, April 2, 2014

function [regList, overlap] = regionOverlap(param, cropRect)
colorNum = 1;%To deal with oldish code
    totalNumRegions = size(param.regionExtent.XY{colorNum},1);
    %Get a list of the regions contained in this cropping rectangle
    overlap = zeros(totalNumRegions,2);
    
    for nR=1:totalNumRegions
        %x position
        regOverlap(nR,1,1) = param.regionExtent.XY{colorNum}(nR,1);
        regOverlap(nR,1,2) = regOverlap(nR,1,1)+param.regionExtent.XY{colorNum}(nR,3);
        
        %y position
        regOverlap(nR,2,1) = param.regionExtent.XY{colorNum}(nR,2);
        regOverlap(nR,2,2) = regOverlap(nR,2,1)+param.regionExtent.XY{colorNum}(nR,4);
        
        
        %See if the position that we clicked on is in the range of one of
        %these regions.
        if(cropRect(2)>regOverlap(nR,1,1) &&...
                cropRect(2)<regOverlap(nR,1,2))
            overlap(nR,1) = 1;
        end
        
        if(cropRect(1)>regOverlap(nR,2,1) &&...
                cropRect(1)<regOverlap(nR,2,2))
            overlap(nR,2) = 1;
        end
    end
    
    %Save a list of all the regions that are in the region clicked on. If we
    %clicked outside of all regions then don't update anything
    overlap = sum(overlap,2);
    regList = find(overlap==2);
end