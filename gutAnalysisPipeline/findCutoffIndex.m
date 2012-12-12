

function threshCutoff = findCutoffIndex(bkgInten)

%Should be inputs!!!!!!!!!!(*!&(
histBin = 1:2:2000;
bkgList =1:25:2000;

numFish = size(bkgInten,1);
numColor = size(bkgInten,2);

for nP=1:numFish
    for nC=1:numColor
        maxS = size(bkgInten{nP,nC},2);
        for nS=1:maxS
            thisBkg = bkgInten{nP}{nC}{nS}(1,:);
            
            for nL=1:length(thisBkg)
                [~,thisThresh(nL)] = min(abs(bkgList-thisBkg(nL)));
            end
            threshCutoff{nP}{nC,nS} = thisThresh;
        end
    end



end