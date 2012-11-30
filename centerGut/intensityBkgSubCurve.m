%intensityBkgSubCurve: Calculate the total pixel intensity above
%background.
%
% USAGE intenL = intensityCurve(im, regionMask,centerLine, bkgList)
%
% INPUT regionMask: n x m x p mask containing integers. n x m is the same
% dimension as im and p is the number of different layers of region masks
% (allowing us to calculate statistics for regions that are overlaping).
%       im: n x m double image or image stack.
%       centerLine: Line along with we are calculating the intensity
%       bkgList: List of background values to subtract from the image region
%       (Make large enough that we don't have to reanalyze this data later
%       
% OUTPUT intenL: n x 2 array where n is the number of unique regions in
% regionMask
% AUTHOR: Matthew Jemielita, revised August 3, 2012

function intenL = intensityBkgSubCurve(im,regionMask,centerLine,bkgList)

totalNumMask = size(regionMask,3);
maxNumReg = 60; %Maximum number of regions to calculate properties of at the same time
%Duplicate the mask.
regionMask =uint16(regionMask);

allReg = unique(regionMask(:));
intenL = zeros(length(centerLine),length(bkgList));

fprintf(1, '\n');
for numMask = 1:totalNumMask
    %Get regions in this particular mask.
    
    regNum = unique(regionMask(:,:,numMask));
    regNum(regNum==0) = [];
    
    
    %This is something of a cludge: we'll truncate down the number of
    %regions that will be simultaneously analyzed with regionprops to 30-if
    %this doesnt' work we'll use a catch statement to run through this code
    %serially
    
    if(length(regNum)<maxNumReg)
        rMaskBig = repmat(regionMask(:,:,numMask), [1 1 size(im,3)]);
        fprintf(1, ['Getting intensity for mask: ', num2str(numMask), '\n']);
        inten = regionprops(rMaskBig, im,'PixelValues');
        
        for i=1:length(regNum)
            thisReg  = regNum(i);
            
            thisInten = arrayfun(@(x)sum(inten(thisReg).PixelValues-x),...
                bkgList, 'UniformOutput', false);
            intenL(thisReg,:) = cell2mat(thisInten);
            
        end
        
    else
       fprintf(1, 'Number of regions is too great: subdividing regionmask');
       
       numCuts = ceil(length(regNum)/maxNumReg);
       
       for cN=1:numCuts
           fprintf(1, ['Analyzing sub region: ', num2str(cN), ' ']);
           minN=(cN-1)*30 +1; maxN = min([length(regNum),cN*30]);
           subRegNum = regNum(minN:maxN);
           
           %Remove all other regions from this max
           origReg = regionMask(:,:,numMask);
           ind = find(ismember(origReg(:), setdiff(origReg(:),subRegNum)));
           
           subRegionMask = regionMask(:,:,numMask);
           subRegionMask(ind) = NaN;
           fprintf(1, '.');
           rMaskBig = repmat(subRegionMask, [1 1 size(im,3)]);
           fprintf(1, '.');
           inten = regionprops(rMaskBig, im,'PixelValues');
           fprintf(1, '.');
           for i=1:length(subRegNum)
               thisReg  = subRegNum(i);
               
               thisInten = arrayfun(@(x)sum(inten(thisReg).PixelValues-x),...
                   bkgList, 'UniformOutput', false);
               intenL(thisReg,:) = cell2mat(thisInten);
               
           end
           fprintf(1, '.\n');
           
       end
       
        
    end
    

       
end
clear rMaskBig
fprintf(1, 'All intensities found! \n');

% 
% allReg = unique(regionMask(:));
% intenL = zeros(length(centerLine),2);
% fprintf(1, '\n');
% for nR = 1:length(allReg)
%     thisRegion = regionMask(regionMask(:) ==allReg(nR));
%     intenL(nR,1) = mean(thisRegion);
%     intenL(nR,2) = max(thisRegion);
% fprintf(1,'.');
% end
% 
% fprintf(1, 'All intensities found! \n');

end