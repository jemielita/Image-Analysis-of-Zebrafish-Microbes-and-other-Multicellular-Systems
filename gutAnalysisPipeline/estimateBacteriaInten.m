% estimateBacteriaInten: Estimate the green/red intensity ratio for all fish in
% this series.
%
% USAGE bacRatio = estimateBacteriaInten(bkgInten, bacInten, bacCutoff, maxStdDev);
%
% INPUT bkgInten: output of estimateBkg. Mean and std. dev. for background
%                 in the gut.
%       bacInten: output of bacteriaIntensityAll. Intensity distribution
%       for all bacteria in our data set.
%       bacCutoff: values of intensities for distribution in bacInten
%       maxStdDev: number of standard deviations above background to go.
%       
% OUTPUT bacRatio: format: bacRatio{p_i}(nS,nD) = green/red intensity for scan n (nS), and a
%        number of standard deviations above background (0.1* nD).
%
% AUTHOR Matthew Jemielita, Nov. 13, 2012

function bacRatio = estimateBacteriaInten(bkgInten, bacInten, bacCutoff, maxStdDev)

totalNumP = length(bkgInten);

for nP=1:totalNumP

    totalNumScan = size(bkgInten{nP},1);
    totalNumColor = size(bkgInten{nP},2);
    
    for nS=1:totalNumScan
        for nD=1:maxStdDev
            for nC=1:totalNumColor
             minInten = bkgInten{nP}(nS,nC,1) + (0.1)*nD*bkgInten{nP}(nS,nC,2);
             % minInten = bkgInten{nP}(nS,nC,1);

                [~,ind] = min(abs(bacCutoff-minInten));
                
%                inten(nC) = bacInten{nC}(ind);
                inten(nC) = bacInten{nC}(ind) + minInten;
            end
            bacRatio{nP}(nS,nD,:) = [nD, inten(1)/inten(2)];
            
        end
    end

    
end




end