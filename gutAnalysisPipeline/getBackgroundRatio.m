%getBackgroundRatio: Estimate the offset of the true background from the
%real background based on visual inspection of where scans are relatively
%blank.

function bkgOffsetRatio = getBackgroundRatio(bkgDiff, maxScan, emptyColor)

%% Collect all the background differences
bkgAll = cell(length(bkgDiff),1);
maxP = length(bkgDiff);

for nP=1:maxP
   
    %Should be more than enough padding
    bkgAll{nP} = NaN*zeros(maxScan(nP),500);
    
    for nS=1:maxScan(nP)
       bkgAll{nP}(nS,1:length(bkgDiff{nP}{nS,emptyColor}(10:120)))=...
           bkgDiff{nP}{nS,emptyColor}(10:120);
        
    end
    
end

%% Calculate the mean background offset
for nP=1:maxP
    allMean(nP) = nanmean(bkgAll{nP}(:))+nanstd(bkgAll{nP}(:));
end
bkgOffsetRatio = nanmean(allMean);

%% Plot features of the background estimate

% need to write!





end