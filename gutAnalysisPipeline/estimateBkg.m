%estimateBkg: return mean and standard deviation for all input fihs
%
% USAGE bkgInten = estimateBkg(pAll,smoothWindow)
%
% INPUT pAll: cell array of param files for different fish to estimate
% background for
%       smoothWindow: window over which to smooth the background intensity
% OUTPUT bkgInten: bkgInten{p_i}{nS, nC,:} mean and standard deviation for
% the ith fish, on scan nS and color nC
%
% AUTHOR: Matthew Jemielita, November 13, 2012


function bkgInten = estimateBkg(pAll,smoothWindow)

totNumP = length(pAll);

for nP = 1:totNumP
    param = pAll{nP};
    
    for nC=1:size(param.bkgIntenAll,2)
        for nS=1:size(param.bkgIntenAll,1)
            thisBkgVal = param.bkgIntenAll(nS,nC,:);
            
            %If background wasn't set on this scan then extrapolate from
            %previous points
            if(isnan(sum(thisBkgVal)))
                indAll = find(~isnan(param.bkgIntenAll(:,nC,1)));
                [~,ind] = min(abs(indAll-nS));
                ind  = ind(1);
                thisBkgVal = param.bkgIntenAll(indAll(ind), nC,:);
            end
            bkgInten{nP}(nS,nC,:) = thisBkgVal;
            
        end
        
        figure; plot(bkgInten{nP}(:,nC,1));
        %Smoothing out the data
        bkgInten{nP}(:,nC,1) = smooth(bkgInten{nP}(:,nC,1),smoothWindow);
        bkgInten{nP}(:,nC,2) = smooth(bkgInten{nP}(:,nC,2),smoothWindow);
        hold on
        plot(bkgInten{nP}(:,nC,1), '-k');
        pause
        
    end
    
    
    
end


end