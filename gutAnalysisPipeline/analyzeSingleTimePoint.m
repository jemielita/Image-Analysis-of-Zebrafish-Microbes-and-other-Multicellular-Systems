%Plot and analyze a single time point

function [totRed, totGr] = analyzeSingleTimePoint(param, nStd,bacMat, bacCut,titleStr, plotData)
origDir = pwd;

cd(param.dataSaveDirectory);

load('Analysis_Scan1.mat');

NtimePoints = 1;
boxwidth = 5;
intensitybins = 100:100:4000;


[bkgCut(1),threshCutoff(1)] = min(abs(intensitybins-param.bkgInten(1,1) - nStd*param.bkgInten(1,2)));
[bkgCut(2),threshCutoff(2)] = min(abs(intensitybins-param.bkgInten(2,1) - nStd*param.bkgInten(2,2)));


%Find the relative intensity of the two channels when this threshold is
%used
[~,ind] = min(abs(bkgCut(1)-bacCut));
grBac = sum(bacCut(ind:end).*bacMat{1}(ind:end)');

[~,ind] = min(abs(bkgCut(2)-bacCut));
redBac = sum(bacCut(ind:end).*bacMat{2}(ind:end)');

grRedRatio = grBac/redBac;
['Green/red ratio ' num2str(grRedRatio)]

xpos = boxwidth*((1:length(regFeatures{1}))' - 0.5); % position along gut, microns (column vector)

gr_bincounts = regFeatures{1}(:,threshCutoff(1)+1:end);  % +1 since first element is mean
ibins_gr = repmat(intensitybins(threshCutoff(1):end), size(gr_bincounts,1),1);
thisLine_green = sum(gr_bincounts.*ibins_gr,2);  % total intensity at each position -- counts * bin values

red_bincounts = regFeatures{2}(:,threshCutoff(2)+1:end);
ibins_red = repmat(intensitybins(threshCutoff(2):end), size(red_bincounts,1),1);
thisLine_red   = grRedRatio*sum(red_bincounts.*ibins_red,2);

if(plotData==true)
hFig = figure; plot(thisLine_green, 'Color', [0 1 0]);
hold on
plot(thisLine_red, 'Color', [1 0 0])
xlabel('Distance down gut (microns)');
ylabel('Total Pixel intensity (a.u.)');



cd(origDir);

set(hFig, 'PaperPosition', [0.25 2.5 6 4])  % to get a decent aspect ratio
print(hFig, '-dpng', titleStr, '-r300')
end

totRed = sum(thisLine_red);
totGr = sum(thisLine_green);



end