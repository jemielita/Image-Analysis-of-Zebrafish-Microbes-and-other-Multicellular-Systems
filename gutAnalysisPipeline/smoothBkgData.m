%smoothBkgData: For a given set of background data, estimate the
%contribution from background along the length of the gut. Data is smoothed
%out to reduce the noise in the background estimation. A threshold is
%applied on the time series so that large jumps in intensities are not
%allowed-these are indicative of a signal arising from bacteria.
%Note: futher tweaking with this algorithm may be necessary. This code
%needs to be stress tested so that we have an idea of how sensitive it is
%to the parameters used to smooth out the data.
%
%AUTHOR: Matthew Jemielita

function locMaster = smoothBkgData(param,colorNum, plotData, minS, maxS,timeCut)

window= 10;

% for line-by-line plots
cData = summer(ceil(2*(maxS-minS+1)));


if(plotData==true)
    figure;
end

fprintf(1, 'Estimating background for this time series');

for nS=minS:maxS
fprintf(1, '.');

load(['Analysis_Scan', num2str(nS), '.mat']);
regT = regFeatures;
clear regFeatures;
regFeatures{1} = regT{1,1};
regFeatures{2} = regT{2,1};

minL = 1;
maxL = size(regFeatures{colorNum},1);

locAll = [];pksAll = [];indAll= [];
for i=minL:maxL

  %  data = regFeatures{colorNum,1}(i,3:1000);
  data = regFeatures{colorNum}(i,3:1000); 
  ind = 1:2:2000;
    ind = ind(3:end);

pkh = 10; 

%smth = smooth(ind,data, 0.05, 'loess');
smth = smooth(ind,data, 51, 'sgolay',3);
if(sum(smth)==0)
    if(i==maxL)
        maxL = i;
    end
    continue; %This region is blank (often happens at the beginning...should fix code at that point!
end
minP = data(end)+ 1500;
[pks,loc] = findpeaks(smth, 'MINPEAKHEIGHT', minP,...
    'MINPEAKDISTANCE', 20);

%Remove all peaks that are not a local maximum in a window of a certain
%size

pksOut =[]; locOut = [];
for j=1:length(pks)
   xMin= max([1,loc(j)-window]);
   xMax = min([length(smth), loc(j)+window]);
   
   if(pks(j)==max(smth(xMin:xMax)))
       pksOut = [pksOut; pks(j)];
       locOut = [locOut; loc(j)];
   end
end

plotDataHist=false;
if(plotDataHist==true)
    figure; plot(ind,smth);hold on
    %figure; semilogy(smth);hold on
    
    hold on
    plot(ind(loc), pks, '*');
    plot(ind(locOut), pksOut, 'square');
    pause
    close all
    i
end

if(~isempty(locOut))
    locAll = [locAll; locOut*2];
    indAll = [indAll; i*ones(size(locOut,1),1)];
    pksAll = [pksAll; pksOut];
end

end

if(isempty(locAll))
    if(i==maxL)
        maxL= i;
        continue;
    end
end
%Smooth out the time series of background signals
origInd = indAll; origLoc = locAll;
indAll=[]; locAll=[];

for i=minL:maxL
    thisL = find(origInd==i);    
    val = max(origLoc(thisL));
    if(isempty(val))
        val = -1;%We'll fill this in the next step.
    end
    indAll = [indAll;i];
    locAll = [locAll; val];    
end

%Replace empty entries with the value of the closest point.
nonEmpty = find(locAll~=-1);
for i=minL:maxL
   if(locAll(i)==-1)
      [~,repInd] = min(abs(nonEmpty-i));
      locAll(i) = locAll(nonEmpty(repInd));
   end
end
%Now smooth out the data along the length of the gut
locAll = smooth(indAll,locAll, 51, 'sgolay',3);
%If the smoothing give negeative values, replace the with the closest
%one-should only be an issue near the beginning of the gut
nonEmpty = find(locAll>00);
for i=minL:maxL
   if(locAll(i)<0)
      [~,repInd] = min(abs(nonEmpty-i));
      locAll(i) = locAll(nonEmpty(repInd));
   end
end
locMaster{nS}(1,:) = locAll;
locMaster{nS}(2,:) = indAll;
%And compare to previous time points.
%If the signal at a given point in the gut differs from the background at a
%different time point by more than a given amount then use the previous
%timepoint for the intensity at this point.

%Smooth out the signal in the posterior of the gut-we know that the
%background at the vent is ~ the same as the signal further in-if the
%predicted background is too high it is likely because of a large bacterial
%signal


if(nS~=1)
   for i=minL:maxL
     
       %This isn't the best way to compare time points, because the fish
       %often drift-unavoidable for now, but keeep in mind.
       if(i>size(locMaster{nS-1},2))
          ind = size(locMaster{nS-1},2);
           valDiff(i) = (0.01)*(locMaster{nS-1}(1,ind)-locMaster{nS}(1,i))/locMaster{nS}(1,i);
       else
           valDiff(i) = (0.01)*(locMaster{nS-1}(1,i)-locMaster{nS}(1,i))/locMaster{nS}(1,i);
       end
     %Different cutoffs, for percentage of difference in signal, for going
     %positive and negative from previous points. Might also want to have
     %different cutoffs for increasing/decreasing intensity differences
     if(valDiff(i)>0)
         if(valDiff(i)>timeCut(1))
             locMaster{nS}(1,i) = locMaster{nS-1}(1,i);
         end
     elseif(valDiff(i)<0)
         if(valDiff(i)>timeCut(2))
             locMaster{nS}(1,i) = locMaster{nS-1}(1,i);
         end
     end
     
   end
end

%Set every point after the minimum value to be equal to the 

%Resmooth out line after replacing entries
locMaster{nS}(1,:) = smooth(indAll,locMaster{nS}(1,:), 51, 'sgolay',3);
locMaster{nS}(2,:) = indAll;

if(plotData==true)
    figure;
    plot(locMaster{nS}(2,:), locMaster{nS}(1,:), '.','MarkerSize', 6, 'Color', cData(nS,:));
    hold on
    if(nS>3)
        plot(locMaster{nS-1}(2,:), locMaster{nS-1}(1,:), '.','MarkerSize', 6, 'Color', cData(nS-1,:));
        plot(locMaster{nS-2}(2,:), locMaster{nS-2}(1,:), '.','MarkerSize', 6, 'Color', cData(nS-2,:));
        
    end
    pause
    close all
end

end

fprintf(1, 'done!\n');




end