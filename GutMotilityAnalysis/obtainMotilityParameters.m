% Function which...
%
% To do:

function [fftPowerPeak, fftPeakFreq, fftRPowerPeakSTD, fftRPowerPeakMin, fftRPowerPeakMax, waveFrequency, waveSpeedSlope, BByFPS, sigB, waveFitRSquared, xCorrMaxima, analyzedDeltaMarkers, waveAverageWidth] = obtainMotilityParameters(curDir, analysisVariables, interpolationOutputName, GUISize)

%% Load data, initialize variables
loadedInterpFile = load(strcat(curDir, filesep, interpolationOutputName,'_Current.mat'));

% Initialize variables
scale = str2double(analysisVariables{4});
fps = str2double(analysisVariables{3});
retryBool = true;
maxFreqToSeeInFFT = str2double(analysisVariables{6});
minFreqToSeeInFFT = str2double(analysisVariables{7});
largestPeriodToSeeInFFT = 60/minFreqToSeeInFFT; % Units of seconds, eventually 1/s
minPeriodToSeeInFFT = 60/maxFreqToSeeInFFT;
plusMinusAroundMeanFFTFreqPM = 0.25; % Units of per minute
gutMesh = loadedInterpFile.gutMesh;
gutMeshVelsPCoords = loadedInterpFile.gutMeshVelsPCoords;
translateMarkerNumToMicron=scale*round(mean(diff(squeeze(gutMesh(1,:,1,1))))); %Units of Micron/Marker
totalTimeFraction=1; % Use 1 if all
fractionOfTimeStart=size(gutMeshVelsPCoords,4); % Use size(gutMeshVelsPCoords,4) if all
markerNumStart=1;
markerNumEnd=size(gutMesh,2); % Use size(gutMesh,2) if all
pulseWidthLargestDecayTime=50; % Units of frames... I feel that's easier
widthGUI = GUISize(3);
heightGUI = GUISize(4);

%% Initialize main figure
f = figure('Visible', 'off', 'Position', GUISize, 'Resize', 'off'); % Create figure
set(f, 'name', 'Motility Analysis GUI', 'numbertitle', 'off'); % Rename figure
a = axes; % Define figure axes
set(a, 'Position', [0, 0, 1, 1]); % Stretch the axes over the whole figure
set(a, 'Xlim', [0, widthGUI], 'YLim', [0, heightGUI]); % Switch off autoscaling
set(a, 'XTick', [], 'YTick', []); % Turn off tick marks

% Display figure
hold on;
f.Visible = 'on';

%% Longitudinal Motion as a surface

% Define variables as a fraction of the longitudinal components of gutMeshVelsPCoords
abscissaValues=(markerNumStart-1)*translateMarkerNumToMicron:(markerNumEnd-1)*translateMarkerNumToMicron;
ordinateValues= int16((size(gutMeshVelsPCoords,4)/fractionOfTimeStart):(size(gutMeshVelsPCoords,4)/(fractionOfTimeStart)+size(gutMeshVelsPCoords,4)/totalTimeFraction-1));
surfaceValues=squeeze(-mean(gutMeshVelsPCoords(:,markerNumStart:markerNumEnd,1,ordinateValues),1));

% Display surface plot
subplot(2, 3, [1,4]);
imshow(surfaceValues',[], 'InitialMagnification', 'fit','XData', [abscissaValues(1), abscissaValues(end)], 'YData', 1/fps*ordinateValues);
set(gca,'YDir','normal')
colormap('Jet');
axis fill;
h=gcf;
title('QSTMap','FontSize',20,'FontWeight','bold');
ylabel('Time (s)','FontSize',20);
xlabel('x (\mum)','FontSize',20);
set(findall(h,'type','axes'),'fontsize',15,'fontWeight','bold');

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
subplot(2, 3, [2, 5]);
abscissaValues=[translateMarkerNumToMicron,(nCorrs-1)*translateMarkerNumToMicron];
ordinateValues=[0, (size(r,2)/2-1)/fps];
imshow(trueXCorr,[], 'InitialMagnification', 'fit','XData', abscissaValues, 'YData', ordinateValues);
set(gca,'YDir','normal')
colormap('Jet');
axis fill;
h=gcf;
title('XCorr','FontSize',20,'FontWeight','bold');
ylabel('\tau (s)','FontSize',20);
xlabel('\Delta x (\mum)','FontSize',20);
%zlabel('Correlation','FontSize',20);
set(findall(h,'type','axes'),'fontsize',15,'fontWeight','bold');

%% Find wave pulse width from autocorrelation decay

% Autocorrelations
tauSubdiv=1;
ordinateValues=int16(size(gutMeshVelsPCoords,4)/fractionOfTimeStart:(size(gutMeshVelsPCoords,4)/(fractionOfTimeStart)+size(gutMeshVelsPCoords,4)/totalTimeFraction-1));
surfaceValues=squeeze(-mean(gutMeshVelsPCoords(:,markerNumStart:markerNumEnd,1,ordinateValues),1));
arr=xcorr(surfaceValues(1,:),'unbiased');
endRByTwo=floor(length(arr)/2);
arr=arr(endRByTwo+1:end);
arr=zeros(size(arr,2),size(surfaceValues,1));
for i=1:tauSubdiv:size(surfaceValues,1)
    r=xcorr(surfaceValues(i,:),'unbiased');
    endRByTwo=floor(length(r)/2);
    arr(:,i)=r(endRByTwo+1:end);
end

typeOfFilt=designfilt('lowpassfir', 'PassbandFrequency', .15, ...
        'StopbandFrequency', .65, 'PassbandRipple', 1, ...
        'StopbandAttenuation', 60);
autoCorrDecays=arr(1:pulseWidthLargestDecayTime,:);
autoCorrDecaysTwo=autoCorrDecays;
decayTimes=zeros(1,size(autoCorrDecaysTwo,2));

for i=1:size(autoCorrDecays,2)
    autoCorrDecaysTwo(:,i)=filtfilt(typeOfFilt,autoCorrDecays(:,i));
    eFoldingTimes=find(autoCorrDecaysTwo(:,i)<=autoCorrDecaysTwo(1,i)/exp(1));
    if(~isempty(eFoldingTimes))
        decayTimes(i)=eFoldingTimes(1);
    else
        decayTimes(i)=NaN;
    end
end

waveAverageWidth=2*mean(decayTimes)/fps; % The factor of 2 for the whole wave. In units of seconds!
goodData=0;
%imcontrast( h );

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
subplot(2, 3, 3);
imshow(subsetFullFFT',[], 'InitialMagnification', 'fit','XData', [1, size(subsetFullFFT,1)*translateMarkerNumToMicron], 'YData', subsetF*60);
set(gca,'YDir','normal')
colormap('Jet');
axis square;
h=gcf;
title('FFT','FontSize',20,'FontWeight','bold');
ylabel('Frequency (min^{-1})','FontSize',20);
xlabel('X (\mum)','FontSize',20);
% zlabel('Correlation','FontSize',20);
    
%% Find motility parameters
while(retryBool)
    % Find peristaltic frequency, wave speed from cross-correlation
    [waveFrequency, waveSpeedSlope, BByFPS, sigB, waveFitRSquared, xCorrMaxima, analyzedDeltaMarkers, g] = gutFreqWaveSpeedFinder( gutMesh, trueXCorr, fps, scale );
    
    % Determine FFT peak powers and whatnot
    waveFreqPerSec = waveFrequency/60;
    [~, indMean]=min(abs(f-waveFreqPerSec));
    beginningIndex=(indMean-plusMinusAroundMeanFFTFreq)*(indMean-plusMinusAroundMeanFFTFreq>0)+(indMean-plusMinusAroundMeanFFTFreq<1);
    subsetFFT=singleFFTRPGMV(beginningIndex:indMean+plusMinusAroundMeanFFTFreq);
    [fftPowerPeak, whereQ]=max(subsetFFT);
    actualMaxPosition=(indMean-plusMinusAroundMeanFFTFreq+whereQ-1)*(indMean-plusMinusAroundMeanFFTFreq+whereQ-1>0)+(indMean-plusMinusAroundMeanFFTFreq+whereQ-1<=0);
    fftPeakFreq=f(actualMaxPosition);
    fftRPowerPeakSTD=std(fftRootPowerGMV(:,actualMaxPosition));
    fftRPowerPeakMin=min(fftRootPowerGMV(:,actualMaxPosition));
    fftRPowerPeakMax=max(fftRootPowerGMV(:,actualMaxPosition));
    
    fitInfo = sprintf('\nWave Period (s) = %.2f \nWave Period (FFT)(s) = %.2f \nSlope (s/marker) = %.2f \n Wave Fit R-Squared = %.2f%% \n Wave Speed Variation = %.2f \n FFT Peak Power = %.2f',...
        60/waveFrequency, 1/fftPeakFreq, BByFPS, 100*waveFitRSquared, sigB, fftPowerPeak);
    retryPrompt = menu(strcat('Does everything look good (figures will be saved after this)?',fitInfo),'Yes','No');
    if(retryPrompt==1)
        retryBool = false;
        goodData = 1;
    else
        goodData = menu(strcat('Would you like to retry or replace with mostly NaNs (freq and amplitude will be found another way)?',fitInfo),'Retry','Replace w/ NaNs');
        if(goodData~=1)
            retryBool = false;
        end
    end
end
if(goodData~=1)
    
    waveFrequency = NaN;
    waveSpeedSlope = NaN;
    sigB = NaN;
    waveFitRSquared = NaN;
    xCorrMaxima = NaN;
    analyzedDeltaMarkers = NaN;
    % Prompt user for variables
    freqMeanSearch=inputdlg({'What frequency (min^-1) should fft search around for gut amplitudes (as of 11-20-15, fish often have well defined peristalsis freqs from about 2.75 min^-1 at 5dpf to 2.0 min^-1 at 7dpf, though consult the xCorr plot for further hints)?'}, 'Title',1,{'2.1'});
    freqMeanSearch=str2double(freqMeanSearch)/60; % Units of per sec
    % Find wave amplitude from FFT peaks
    % [fftPowerPeak, fftPowerPeakSTD, fftPowerPeakMin, fftPowerPeakMax, fftPeakFreq] = gutFFTPeakFinder( gutMeshVelsPCoords, fps, freqMeanSearch/60); %#ok
    % Determine FFT peak powers and whatnot
    [~, indMean]=min(abs(f-freqMeanSearch));
    beginningIndex=(indMean-plusMinusAroundMeanFFTFreq)*(indMean-plusMinusAroundMeanFFTFreq>0)+(indMean-plusMinusAroundMeanFFTFreq<1);
    subsetFFT=singleFFTRPGMV(beginningIndex:indMean+plusMinusAroundMeanFFTFreq);
    [fftPowerPeak, whereQ]=max(subsetFFT);
    actualMaxPosition=(indMean-plusMinusAroundMeanFFTFreq+whereQ-1)*(indMean-plusMinusAroundMeanFFTFreq+whereQ-1>0)+(indMean-plusMinusAroundMeanFFTFreq+whereQ-1<=0);
    fftPeakFreq=f(actualMaxPosition);
    fftRPowerPeakSTD=std(fftRootPowerGMV(:,actualMaxPosition));
    fftRPowerPeakMin=min(fftRootPowerGMV(:,actualMaxPosition));
    fftRPowerPeakMax=max(fftRootPowerGMV(:,actualMaxPosition));
    
end

% Save the figure as both a png (with date) and as a .fig (only most recent
% since the file sizes may be large)
set(findall(h,'type','axes'),'fontsize',15,'fontWeight','bold');
saveas(h, strcat(curDir, filesep, 'Figures_',date), 'png')
saveas(h, strcat(curDir, filesep, 'Figures_Current'), 'fig');

close(h);
close(g);

end