%estimateBkg: the estimated background at all point along the gut and at
%every time point for all fish.
%
% USAGE bkgInten = estimateBkg(pAll,smoothWindow)
%
% INPUT pAll: cell array of param files for different fish to estimate
% background for
% OUTPUT bkgInten: bkgInten{p_i}{nC,nS,nT} the mean background along the
%        entire length of the gut for scan nS, color nC, and time nT.
%
% AUTHOR: Matthew Jemielita, November 13, 2012


function bkgInten = estimateBkg(pAll)

totNumP = length(pAll);

for nP = 1:totNumP
    param = pAll{nP};
    numColor = length(param.color);
    numScan = param.expData.totalNumberScans;
    
    fileDir = [param.dataSaveDirectory filesep 'bkgEst'];
    if(isdir(fileDir))
       cd(fileDir);
        for nC=1:numColor
            
           temp = smoothBkgData(param,nC,false, 1, numScan, [50,100]);
           bkgInten{nP,nC}= temp;
        end
        
    end
    
end


end