% Pipeline to analyze the results of several fish from the same
% experimental setup and collect together the results

%% Load in parameters

%hard coded in for now, but should be a prompt at some point
pAll = {p1};


pAll = {param};
sAll = {scanParam};
sAll = {scanParam, scanParam, scanParam, scanParam};

numColor = length(pAll{1}.color);

%% Get histogram of bacterial intensities

%Ideally these are set by the distribution itself...
stepInten = 25; %Step size for the bacterial intensity histogram
maxInten = 5000; %Maximum intensity for bacterial intensity histogram
%If plotResults == true we can verify the number of bacteria in each of
%these images and adjust the results accordingly.
plotResults = true; 

%Update pAll with any corrected bacteria intensities.
[bacSum,bacInten, bacCutoff,bacMat, bacScan,bacHist,pAll] = ...
    bacteriaIntensityAll(pAll, maxInten, stepInten,numColor, plotResults);

%Need to show evidence that the individual bacterial intensity doesn't
%change over time...

%% Parameters for this particular series of fish
timeData = {[3 0], [3 0], [3 0]};
baseTitle = 'Fish '; rootTitle = '0 GFP, 3 RFP';

%% Get the background estimation for all the fish
%bkgInten gives the estimated background at each point along the gut,
%threshCutoff gives the appropriate index to plot in plot_gut
%Format: bkgInten{nP}{nC}{nS}
bkgInten = estimateBkg(pAll);
%threshCutoff = findCutoffIndex(bkgInten);
%% Plot background intensity
%Need to move this to it's own folder


%mlj: need to fix up this code
for nC=1:2
    bkgFig = figure;
    set(bkgFig, 'Position', [289 184 1074 774]);
    for nP = 1:length(pAll)
        
        NtimePoints = size(bkgInten{nP}{nC},2);
        
        cData{1} = summer(ceil(2*NtimePoints));
        cData{2} = hot(ceil(2*NtimePoints));
        
        h(nP)  = subplot(2,2,nP);
        hold on;
       
        for nS=1:NtimePoints
            sLength = size(bkgInten{nP}{nC}{nS},2);
            plot3(1:sLength,nS*ones(sLength,1),bkgInten{nP}{nC}{nS}(1,:)  ,'Color', cData{nC}(nS,:));
            
        end
        set(h(nP), 'CameraPosition', [1494.37 -229.649 3909.55]);
        title([pAll{nP}.directoryName]);
        xlabel('Distance down gut');
        ylabel('Scan #');
        zlabel('Intensity');
        hold off 
    end
    
end

%% Get the green/red intensity estimate for each fish

%Note: this intensity ratio should change as a function of time because of
%the background
%format: bacRatio{p_i}(nS,nD) = green/red intensity for scan n (nS), and a
%number of standard deviations above background (nD).

%mlj: not used anymore
bacRatio = estimateBacteriaInten(bkgInten, bacInten, bacCutoff,30);

%% Plot the red/green intensity ratios for each fish
figure; 
for nP = 1:length(pAll)
    
    cM = colormap(autumn(size(bacRatio{nP},1)));
    
    subplot(2,2,nP); hold on
 for nS=1:size(bacRatio{nP},1) 
     plot(bacRatio{nP}(nS,:,2), 'Color',cM(nS,:) );
 end
 title(pAll{nP}.directoryName);
 xlabel('Number of standard deviations above background');
 ylabel('Green/red ratio');
 hold off
end

%% Plot all bacteria total intensities above a given threshold
figure;
hold on
cutoff = 5; %This is a cutoff of 350plo

for nC=1:2
   subplot(2,1,nC);
   val = bacMat{nC}(cutoff,:);
   val(isnan(val)) = [];
   hist(val,20);
   
   title(['All bacteria intensity:  ', pAll{1}.color{nC}]);
end

%Check that the ratio is reasonable for all the fish. It should be less
%than 10ish.

%Check that the ratio is good over a range of thresholds above background
%intensity

%% Assemble 1D information
bkgOffsetRatio = 1.18;%First estimate
popTot = cell(length(pAll),1); popXpos = cell(length(pAll),1); bkgDiff = cell(length(pAll),1);
for nP = 1:length(pAll)
    minS = 1;
    maxS =pAll{nP}.expData.totalNumberScans;
    [~, ~, bkgDiff{nP}] = ...
        assembleDataGutTimeSeries(pAll{nP}, 1, maxS, bacMean, bkgInten{nP}, bkgOffsetRatio);
end
for nP=1:length(pAll)
    %   Estimate the background to subtract
    maxScan = [15,1,15,10,1]; %Maximum scan before the channel that's ~empty shows up
    emptyColor = 2;
    minS = 1;
    maxS =pAll{nP}.expData.totalNumberScans;
   % bkgOffsetRatio = getBackgroundRatio(bkgDiff, maxScan, emptyColor);
   bkgOffsetRatio = 1.18;
    [popTot{nP}, popXpos{nP}, bkgDiff{nP}] = ...
        assembleDataGutTimeSeries(pAll{nP}, minS, maxS, bacMean, bkgInten{nP}, bkgOffsetRatio);
end
%% Plot/output data for 1D analysis
nplist = 1:3;
for nP1=1:length(nplist)
 nP = nplist(nP1);
%    thisTitle = [pAll{nP}.directoryName '   ', rootTitle];
thisTitle = pAll{nP}.outputName; 
%thisTitle =  '';

printData = true; %Save the results as both a .png and .fig file

plotGutData({'totalintensityLog'}, popTot{nP},popXpos{nP}, bkgDiff{nP}, thisTitle, timeData{nP},printData, thisTitle);
    plotGutData({'linePlots'}, popTot{nP},popXpos{nP}, bkgDiff{nP}, thisTitle, timeData{nP1},true, thisTitle);
   
   pause 
end


