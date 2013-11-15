%bacteriaDifferentialGrowthRate: Calculate the growth rate of bacteria in
%the gut for regions that are highly populated and regions that aren't
%
% USAGE popDiffReg = bacteriaDifferentialGrowthRate(pop, cutoff, plotData)
%
% INPUT pop: cell array containing the population of bacteria in the gut
% (cell array elements: {scan Number, color Number}). Data comes from
% combining the course and fine analysis.
%       cutoff: population size cutoff to consider a region a "cluster" or
%       not.
%       plotData: (optional, default: false) Plot the result of separating
%       the growth rate of the different regions of the gut.
%
% OUTPUT popDiffReg: 
%
% AUTHOR Matthew Jemielita

function popDiffReg = bacteriaDifferentialGrowthRate(pop, cutoff, plotData, plotTitle)

minS = 1;
maxS = size(pop,1);

numColor = size(pop,2);
popDiffReg = zeros(maxS-minS+1, numColor, 2);




for nS=minS:maxS
   for nC= 1:numColor;
       %data will be binned to hopefully make the transition from no
       %clusters to clusters less abrupt.
       binSize = 5;
       line = 1:5: length(pop{nS, nC});
       
       for i=1:length(line)-1
          thisPop(i) = mean(pop{nS, nC}(line(i):line(i+1))); 
       end

       ind = thisPop>cutoff;
       %Find total population above and below this cutoff
       popDiffReg(nS, nC,1) = sum(thisPop(~ind));
       popDiffReg(nS, nC,2) = sum(thisPop(ind));
   end
end


if(plotData==true)
    figure;
    
%     subplot(2,1,1); semilogy(popDiffReg(:,1,1));
%     hold on
%     semilogy(popDiffReg(:,1,2), 'k');
%     axis square
%     subplot(2,1,2);
    
    semilogy(popDiffReg(:,2,1));
    hold on
    semilogy(popDiffReg(:,2,2), 'k');
    axis square
%     
%     subplot(2,2,3); plot(popDiffReg(:,1,1));
%     hold on
%     plot(popDiffReg(:,1,2), 'k');
%     
%     subplot(2,2,4);
%     
%     plot(popDiffReg(:,2,1));
%     hold on
%     plot(popDiffReg(:,2,2), 'k');
%     
    set(gcf, 'Name', plotTitle)
end