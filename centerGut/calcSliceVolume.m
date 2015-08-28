%calcSliceVolume: Calculate the approximate volume in each slice of the
%gut. 
%
% USAGE vol = calcSliceVolume(param, scanNum, gutoutline, smoothRng)
%
% INPUT scanNum: which scan to calculate the volume for
%       gutOutline: Array of manually outlined gut volumes
%       smoothRng: range of points to use when smoothing volume.
% OUTPUT vol: volume in each slice num
%
% AUTHOR Matthew Jemielita, June 3, 2015

function slicevol = calcSliceVolume(param, scanNum, smoothRng)

%Load in gut outline
inputVar = load([param.dataSaveDirectory filesep 'manualGutOutlining.mat']);
gutoutline = inputVar.entireGutOutline;

mask = maskFish.getGutFillMask(param, scanNum);
mask = 0*mask; %Just get a blank mask the size of the entire gut volume

%Load in slice mask
inputVar = load([param.dataSaveDirectory filesep 'masks', filesep 'maskUnrotated_', num2str(scanNum), '.mat']);
gutMask = inputVar.gutMask;

rng = 0;%Range between slices that are outlined.


%Find non-empty outlines
ind = ~cellfun(@(x)isempty(x), gutoutline);
ind = ind(scanNum,:);
ind = find(ind==1);

depth = 0;

numslc = unique(gutMask(:)); numslc(numslc==0) = []; numslc = length(numslc);
slicevol = zeros(numslc,1);

for i=1:length(ind)
    j = ind(i);
    mask = poly2mask(gutoutline{scanNum,j}(:,1),gutoutline{scanNum,j}(:,2), size(mask,1),size(mask,2));

    
    if(i<length(ind))
        %The last slice will use the depth of the previous slice
        depth = ind(i+1)-ind(i);
    end
    
    %Find overlaps with slice masks and update 
    for k=1:size(gutMask,3)
        volmask = gutMask(:,:,k).*mask;
        slc = unique(volmask);
        slc(slc==0) = [];
        inten = arrayfun(@(x)sum(volmask(:)==x), slc);
        
        %Normalizing voxels
        inten = (depth*0.1625*0.1625)*inten;
        slicevol(slc) = slicevol(slc)+inten;
    end
    i
end
    
    



 end