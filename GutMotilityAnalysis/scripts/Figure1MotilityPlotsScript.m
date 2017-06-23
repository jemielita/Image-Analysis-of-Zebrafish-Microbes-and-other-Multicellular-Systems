% Gut motility plots for figure one of publication

%% Initialize variables
scale = 0.325;
fps = 5;
retryBool = true;
maxFreqToSeeInFFT = 9.1;
minFreqToSeeInFFT = 1;
largestPeriodToSeeInFFT = 60/minFreqToSeeInFFT; % Units of seconds, eventually 1/s
minPeriodToSeeInFFT = 60/maxFreqToSeeInFFT;
plusMinusAroundMeanFFTFreqPM = 0.25; % Units of per minute
translateMarkerNumToMicron=scale*round(mean(diff(squeeze(gutMesh(1,:,1,1))))); %Units of Micron/Marker
totalTimeFraction=4; % Use 1 if all
fractionOfTimeStart=size(gutMeshVelsPCoords,4); % Use size(gutMeshVelsPCoords,4) if all
markerNumStart=1;
markerNumEnd=size(gutMesh,2); % Use size(gutMesh,2) if all
pulseWidthLargestDecayTime=50; % Units of frames... I feel that's easier
mainFigureDirectory = '/Users/Ampere/Documents/Research/Papers/Gut Motility Analysis/Figures/';
overDir = 'Figure1Overview/';

%% Longitudinal Motion as a surface

% Define variables as a fraction of the longitudinal components of gutMeshVelsPCoords
abscissaValues=(markerNumStart-1)*translateMarkerNumToMicron:(markerNumEnd-1)*translateMarkerNumToMicron;
ordinateValues= int16((size(gutMeshVelsPCoords,4)/fractionOfTimeStart):(size(gutMeshVelsPCoords,4)/(fractionOfTimeStart)+size(gutMeshVelsPCoords,4)/totalTimeFraction-1));
surfaceValues=squeeze(-mean(gutMeshVelsPCoords(:,markerNumStart:markerNumEnd,1,ordinateValues),1));

% Display surface plot
h = figure;
imshow(surfaceValues',[], 'InitialMagnification', 'fit','XData', [abscissaValues(1), abscissaValues(end)], 'YData', 1/fps*ordinateValues);
set(gca,'YDir','normal')
colormap('Jet');
axis square;
% title('QSTMap','FontSize',20,'FontWeight','bold');
% ylabel('Time (s)','FontSize',20);
% xlabel('x (\mum)','FontSize',20);
set(findall(h,'type','axes'),'fontsize',15,'fontWeight','bold');
set(findall(h,'type','axes'),'fontsize',20, 'FontName',...
        'Arial', 'TickDir', 'out','box','off');
set(h, 'Units', 'Inches');
pos = get(h, 'Position');
set(h, 'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)]);
curfileName = 'QSTMap.pdf';
print(h, strcat(mainFigureDirectory, overDir, curfileName), '-dpdf', '-r0'); % Fileseps already included in name

%% Cross Correlations of wave propagations
ordinateValues=int16(size(gutMeshVelsPCoords,4)/fractionOfTimeStart:(size(gutMeshVelsPCoords,4)/(fractionOfTimeStart)+size(gutMeshVelsPCoords,4)/totalTimeFraction-1));
surfaceValues=squeeze(-mean(gutMeshVelsPCoords(:,markerNumStart:markerNumEnd,1,ordinateValues),1));
nCorrs=size(surfaceValues,1)-1;
dummyR=xcorr(surfaceValues(1,:),surfaceValues(2,:),'unbiased'); % Easiest way of finding the dimensions to use... dummy because I'm lazy
endRByTwo=floor(length(dummyR)/2);
fullXCorr=zeros(size(dummyR(1:endRByTwo),2),nCorrs);
for i=1:nCorrs
    for j=(i+1):size(surfaceValues,1)
        r=xcorr(surfaceValues(i,:),surfaceValues(j,:),'unbiased');
        fullXCorr(:,j-i)=fullXCorr(:,j-i)+r(1:size(fullXCorr,1))'/(nCorrs-j+i+1); % The normalization on r is an easy way to average each difference in marker distances 
    end
end
trueXCorr=flipud(fullXCorr);% The flip is due to how cross correlation interpretations are symmetric about the tau=0 and matlab's representation of that at a non zeros in vectors (and then sets of dx turning it into a surface)

% Display surface plot
g = figure;
abscissaValues=[translateMarkerNumToMicron,(nCorrs-1)*translateMarkerNumToMicron];
ordinateValues=[0, (size(r,2)/2-1)/fps];
imshow(trueXCorr,[], 'InitialMagnification', 'fit','XData', abscissaValues, 'YData', ordinateValues);
set(gca,'YDir','normal')
%colormap('Jet');
axis square;
% title('XCorr','FontSize',20,'FontWeight','bold');
% ylabel('\tau (s)','FontSize',20);
% xlabel('\Delta x (\mum)','FontSize',20);
% %zlabel('Correlation','FontSize',20);
% set(findall(g,'type','axes'),'fontsize',15,'fontWeight','bold');
set(findall(g,'type','axes'),'fontsize',15,'fontWeight','bold');
set(findall(g,'type','axes'),'fontsize',20, 'FontName',...
        'Arial', 'TickDir', 'out','box','off');
set(g, 'Units', 'Inches');
pos = get(g, 'Position');
set(g, 'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)]);
curfileName = 'XCorr.pdf';
print(g, strcat(mainFigureDirectory, overDir, curfileName), '-dpdf', '-r0'); % Fileseps already included in name

%% Perform a FFT on the QSTMap
% Find wave amplitude from FFT peaks
gutMeshVals=squeeze(mean(gutMeshVelsPCoords(:,:,1,:),1)); % Average longitudinal component of transverse vectors down the gut, resulting dimension [xPosition, time]
NFFT = 2^nextpow2(size(gutMeshVals,2));
fftGMV=zeros(size(gutMeshVals,1),NFFT);
for i=1:size(gutMeshVals,1)
    fftGMVCur=fft(gutMeshVals(i,:) - mean(gutMeshVals(i,:)),NFFT);
    fftGMV(i,:)=fftGMVCur;
end
fftRootPowerGMV=abs(fftGMV);

% Collapse data onto one mean curve
singleFFTRPGMV=mean(fftRootPowerGMV);
f = fps/2*linspace(0,1,NFFT/2+1); % Units of per second

% Create a subset of the FFT
subsetFFTBeginningF = floor(2*(NFFT/2+1)/(fps*largestPeriodToSeeInFFT));
subsetFFTEndingF = floor(2*(NFFT/2+1)/(fps*minPeriodToSeeInFFT));
subsetF = [f(subsetFFTBeginningF), f(subsetFFTEndingF)];
% subsetSingleFFT=singleFFTRPGMV(1:subsetFFTEndingF);
subsetFullFFT = fftRootPowerGMV(:,subsetFFTBeginningF:subsetFFTEndingF);
plusMinusAroundMeanFFTFreq = round(2*(NFFT/2 + 1)*plusMinusAroundMeanFFTFreqPM/(60*fps)); % Translates the search from plus or minus per minutes to plus or minus index numbers

% Plot the fft
translateMarkerNumToMicron=scale*round(mean(diff(squeeze(gutMesh(1,:,1,1))))); % Should be units of microns/marker
h = figure;
imshow(subsetFullFFT',[], 'InitialMagnification', 'fit','XData', [1, size(subsetFullFFT,1)*translateMarkerNumToMicron], 'YData', subsetF*60);
set(gca,'YDir','normal')
colormap('Jet');
axis square;
% title('FFT','FontSize',20,'FontWeight','bold');
% ylabel('Frequency (min^{-1})','FontSize',20);
% xlabel('X (\mum)','FontSize',20);
% zlabel('Correlation','FontSize',20);
set(findall(h,'type','axes'),'fontsize',15,'fontWeight','bold');
set(findall(h,'type','axes'),'fontsize',20, 'FontName',...
        'Arial', 'TickDir', 'out','box','off');
set(h, 'Units', 'Inches');
pos = get(h, 'Position');
set(h, 'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)]);
curfileName = 'FFT.pdf';
print(h, strcat(mainFigureDirectory, overDir, curfileName), '-dpdf', '-r0'); % Fileseps already included in name