% Pipeline to analyze the results of several fish from the same
% experimental setup and collect together the results


%% Load in parameters

%hard coded in for now, but should be a prompt at some point
pAll = {p1, p3,p4,p5};

sAll = {scanParam, scanParam, scanParam, scanParam};

numColor = length(pAll{1}.color);

%% Get histogram of bacterial intensities

%Ideally these are set by the distribution itself...
stepInten = 25; %Step size for the bacterial intensity histogram
maxInten = 5000; %Maximum intensity for bacterial intensity histogram
%If plotResults == true we can verify the number of bacteria in each of
%these images and adjust the results accordingly.
plotResults = false; 

%Update pAll with any corrected bacteria intensities.
[bacInten, bacCutoff,bacMat, bacScan,paramAll] = ...
    bacteriaIntensityAll(pAll, maxInten, stepInten,numColor, plotResults);

%Need to show evidence that the individual bacterial intensity doesn't
%change over time...

%% Get the background estimation for all the fish
%format: bkgInten{p_i}(nS,nC,:) = mean and standard deviation of background
smoothWindow = 5;%Window over which to smooth data
bkgInten = estimateBkg(pAll, smoothWindow);


%% Plot background intensity

%Need to move this to it's own folder
figure; 
for nP = 1:length(pAll)
    subplot(2,2,nP); 
    hold on; 
    plot(bkgInten{nP}(:,1,1), 'Color', [0 1 0]); 
    
    plot(bkgInten{nP}(:,2,1), 'Color', [1 0 0]);
    title(pAll{nP}.directoryName);
    xlabel('Scan Number');
    ylabel('Intensity');
   hold off
end

%% Get the green/red intensity estimate for each fish

%Note: this intensity ratio should change as a function of time because of
%the background
%format: bacRatio{p_i}(nS,nD) = green/red intensity for scan n (nS), and a
%number of standard deviations above background (nD).
bacRatio = estimateBacteriaInten(bkgInten, bacInten, bacCutoff,20);

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
cutoff = 100;

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

%% Produce plots of 1D bacterial intensity for all the fish

