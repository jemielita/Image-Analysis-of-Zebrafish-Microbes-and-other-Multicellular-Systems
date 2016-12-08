%% Program which calculates parameters of interest from gut motility data
% To do: -Change parameters to velocity magnitude rather than longitudinal
% component (or both)
%        -Vorticity calculations

function fishDataAccurate = analyzeGutData(gutMesh, gutMeshVelsPCoords, fps, scale, imPath, savePath)

cd(imPath);
% cd .. % Uncomment when running gutMotility(Single) program(s), comment when manually running this program
dataDir=strcat(savePath,filesep,'Data');
mkdir(dataDir);
retryBool = true;
translateMarkerNumToMicron=scale*round(mean(diff(squeeze(gutMesh(1,:,1,1))))); % Units of Micron/Marker

%% Initialize variables
% nV=size(gutMeshVels,1);
% nU=size(gutMeshVels,2);
% nT=size(gutMeshVels,4);
totalTimeFraction=1; % Use 1 if all
fractionOfTimeStart=size(gutMeshVelsPCoords,4); % Use size(gutMeshVelsPCoords,4) if all
markerNumStart=1;
markerNumEnd=size(gutMesh,2); % Use size(gutMesh,2) if all
% timeToStartSearchFreq=4; % Units of seconds. I highly suggest NOT using 1, since autocorrelations at 1 are the highest. Suggested: > 4seconds
% timeToSearchFreq=50; % Units of seconds
pulseWidthLargestDecayTime=50; % Units of frames... I feel that's easier

%% Longitudinal Motion as a surface
erx=int16(size(gutMeshVelsPCoords,4)/fractionOfTimeStart:(size(gutMeshVelsPCoords,4)/(fractionOfTimeStart)+size(gutMeshVelsPCoords,4)/totalTimeFraction-1));
surfL=squeeze(-mean(gutMeshVelsPCoords(:,markerNumStart:markerNumEnd,1,erx),1));

figure;
%surf(time,markerNum,surfL,'LineStyle','none');
%imshow(surfL,[],'InitialMagnification','fit');
%truesize;
%h=gca;
erx=[erx(1), erx(end)];
whyr=[(markerNumStart-1)*translateMarkerNumToMicron,(markerNumEnd-1)*translateMarkerNumToMicron];
imshow(surfL',[], 'InitialMagnification', 'fit','XData', whyr, 'YData', 1/fps*erx);
set(gca,'YDir','normal')
colormap('Jet');
axis square;
h=gcf;
%set(h, 'Position', get(0,'Screensize')); % Maximize figure.
title('Anterior-Posterior velocities down the gut','FontSize',20,'FontWeight','bold');
ylabel('Time (s)','FontSize',20);
xlabel('x (\mum)','FontSize',20);
%axes('FontSize',15);
set(findall(h,'type','axes'),'fontsize',15,'fontWeight','bold');
% Save image
cd(dataDir);
% formatOut = 'mm_dd_yy';
% dDate=datestr(now,formatOut);
% dName=strcat('QSTMap_X_',dDate,'_FX');
dName='QSTMap';
print( gcf, '-dpng', dName );
cd(imPath);

% print('-dtiff','-r300','WT_7_22_Fish2_Marker_Tracks');

%% Transverse Motion as a surface

% surfL=squeeze((mean(gutMeshVelsPCoords(1:end/2,:,2,1:end/totalTimeFraction),1)-mean(gutMeshVelsPCoords((end/2+1):end,:,2,1:end/totalTimeFraction),1))/2); % Transverse components will be opposite sign across gut line
% 
% figure;
% surf(time,markerNum,surfL,'LineStyle','none');
% colormap('Jet');
% %caxis([-numSTD*stdFN,numSTD*stdFN]);
% 
% title('Transverse velocities down the gut','FontSize',12,'FontWeight','bold');
% xlabel('Time (s)','FontSize',20);
% ylabel('Marker number','FontSize',20);
% % axes('FontSize',15);
% % set(findall(h,'type','axes'),'fontsize',15,'fontWeight','bold')
% % print('-dtiff','-r300','WT_7_22_Fish2_Marker_Tracks');
%  cd(curDir);

%% Tau Autocorrelations of wave propagations
tauSubdiv=1;
erx=int16(size(gutMeshVelsPCoords,4)/fractionOfTimeStart:(size(gutMeshVelsPCoords,4)/(fractionOfTimeStart)+size(gutMeshVelsPCoords,4)/totalTimeFraction-1));
surfL=squeeze(-mean(gutMeshVelsPCoords(:,markerNumStart:markerNumEnd,1,erx),1));

% Surface
arr=xcorr(surfL(1,:),'unbiased');
endRByTwo=floor(length(arr)/2);
arr=arr(endRByTwo+1:end);
arr=zeros(size(arr,2),size(surfL,1));
erx=1:tauSubdiv:size(surfL,1);

figure
%hold all;
for i=1:tauSubdiv:size(surfL,1)
    r=xcorr(surfL(i,:),'unbiased');
    x=0:size(r,2)/2;
    dt=x/fps;
    endRByTwo=floor(length(r)/2);
    %plot(dt,r(end/2:end),'Color',[sin(3.1415/(2*colorSize)*(i-1)),0,cos(3.1415/(2*colorSize)*(i-1))]);
    arr(:,i)=r(endRByTwo+1:end);
end
surf(erx,dt,arr,'LineStyle','none');
colormap('Jet');
figure;
%plot(dt,zeros(1,size(dt,2)),'k-');
%hold off;
erx=[dt(1), dt(end)];
whyr=[(markerNumStart-1)*translateMarkerNumToMicron,(markerNumEnd-1)*translateMarkerNumToMicron];
imshow(arr,[], 'InitialMagnification', 'fit','XData', whyr, 'YData', erx);
set(gca,'YDir','normal')
colormap('Jet');
axis square;
h=gcf;
%set(h, 'Position', get(0,'Screensize')); % Maximize figure.
title('Autocorrelations of anterior-posterior velocities over time','FontSize',20,'FontWeight','bold');
ylabel('\tau (s)','FontSize',20);
xlabel('x (\mum)','FontSize',20);
zlabel('Correlation','FontSize',20);
set(findall(h,'type','axes'),'fontsize',15,'fontWeight','bold');
% Save image
cd(dataDir);
% formatOut = 'mm_dd_yy';
% dDate=datestr(now,formatOut);
% dName=strcat('QSTMACorr_X_',dDate,'_FX');
dName='QSTMACorrs';
print( gcf, '-dpng', dName );
cd(imPath);

%% Cross Correlations of wave propagations
erx=int16(size(gutMeshVelsPCoords,4)/fractionOfTimeStart:(size(gutMeshVelsPCoords,4)/(fractionOfTimeStart)+size(gutMeshVelsPCoords,4)/totalTimeFraction-1));
surfL=squeeze(-mean(gutMeshVelsPCoords(:,markerNumStart:markerNumEnd,1,erx),1));
nCorrs=size(surfL,1)-1;
dummyR=xcorr(surfL(1,:),surfL(2,:),'unbiased'); % dummy because I'm lazy
endRByTwo=floor(length(dummyR)/2);
fullXCorr=zeros(size(dummyR(1:endRByTwo),2),nCorrs);
figure
%hold all;
for i=1:nCorrs
    for j=(i+1):size(surfL,1)
        r=xcorr(surfL(i,:),surfL(j,:),'unbiased');
        fullXCorr(:,j-i)=fullXCorr(:,j-i)+r(1:size(fullXCorr,1))'/(nCorrs-j+i+1); % The normalization on r is an easy way to average each difference in marker distances 
        %plot(dt,r(end/2:end),'Color',[sin(3.1415/(2*(size(surfL,1)-2))*dc),0,cos(3.1415/(2*(size(surfL,1)-2))*dc)]);
        
    end
end
%hold off;
x=0:size(r,2)/2-1;
dt=x/fps;
trueXCorr=flipud(fullXCorr);% The flip is due to how cross correlation interpretations are symmetric about the tau=0 and matlab's representation of that at a non zeros in vectors (and then sets of dx turning it into a surface)
surf(1:nCorrs,dt,trueXCorr,'LineStyle','none');
colormap('Jet');
figure;
erx=[dt(1), dt(end)];
whyr=[translateMarkerNumToMicron,(nCorrs-1)*translateMarkerNumToMicron];
imshow(trueXCorr,[], 'InitialMagnification', 'fit','XData', whyr, 'YData', erx);
set(gca,'YDir','normal')
% colormap('Jet');
axis square;
h=gcf;
%set(h, 'Position', get(0,'Screensize')); % Maximize figure.
title('Global cross correlations between anterior-posterior velocities over time','FontSize',20,'FontWeight','bold');
ylabel('\tau (s)','FontSize',20);
xlabel('\Delta x (\mum)','FontSize',20);
zlabel('Correlation','FontSize',20);
set(findall(h,'type','axes'),'fontsize',15,'fontWeight','bold');
imcontrast( h );
gutMotileBool = menu('Is the gut reliably motile? You will have another chance to say no later if you choose yes now: ','Yes','No');
% Save image
cd(dataDir);
% formatOut = 'mm_dd_yy';
% dDate=datestr(now,formatOut);
% dName=strcat('QSTMXCorr_X_',dDate,'_FX');
dName='QSTMXCorrs';
print( gcf, '-dpng', dName );
cd(imPath);

%% Find wave pulse width from autocorrelation decay
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

waveAverageWidth=2*mean(decayTimes)/fps; %#ok % Outputs will be saved. The factor of 2 for the whole wave. In units of seconds!
goodData=0;

%% Process data if gut appears to be motile
if(gutMotileBool==1)
    while(retryBool)
        % Find peristaltic frequency, wave speed from cross-correlation
        [waveFrequency, waveSpeedSlope, BByFPS, sigB, waveFitRSquared, xCorrMaxima, analyzedDeltaMarkers] = gutFreqWaveSpeedFinder( gutMesh, trueXCorr, fps, scale ); %#ok % Outputs will be saved
        
        % Find wave amplitude from FFT peaks
        [fftPowerPeak, fftPowerPeakSTD, fftPowerPeakMin, fftPowerPeakMax, fftPeakFreq] = gutFFTPeakFinder( gutMeshVelsPCoords, fps, waveFrequency/60); %#ok % Outputs will be saved % waveFrequency/60 to change from min^-1 to s^-1
        fitInfo = sprintf('\nWave Period (s) = %.2f \n Slope (s/marker) = %.2f \n Wave Fit R-Squared = %.2f%% \n Wave Speed Variation = %.2f \n FFT Peak Power = %.2f',...
            60/waveFrequency,BByFPS,100*waveFitRSquared,sigB, fftPowerPeak);
        retryPrompt = menu(strcat('Does everything look good?',fitInfo),'Yes','No');
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
end
if(gutMotileBool~=1||goodData~=1)
    
    fishDataAccurate = false;
    waveFrequency = NaN; %#ok %Outputs saved, warning suppressed on all variables in else
    waveSpeedSlope = NaN; %#ok
    sigB = NaN; %#ok
    waveFitRSquared = NaN; %#ok
    xCorrMaxima = NaN; %#ok
    analyzedDeltaMarkers = NaN; %#ok
    % Prompt user for variables
    freqMeanSearch=inputdlg({'What frequency (min^-1) should fft search around for gut amplitudes (as of 11-20-15, fish often have well defined peristalsis freqs from about 2.75 min^-1 at 5dpf to 2.0 min^-1 at 7dpf, though consult the xCorr plot for further hints)?'}, 'Title',1,{'2.1'});
    freqMeanSearch=str2double(freqMeanSearch);
    % Find wave amplitude from FFT peaks
    [fftPowerPeak, fftPowerPeakSTD, fftPowerPeakMin, fftPowerPeakMax, fftPeakFreq] = gutFFTPeakFinder( gutMeshVelsPCoords, fps, freqMeanSearch/60); %#ok
    
else
    
    fishDataAccurate = true;
    
end

close all;

%%
% Save various parameters
mkdir(strcat(dataDir));
save(strcat(dataDir,filesep,'GutParameters',date),'fftPowerPeak','fftPowerPeakSTD', 'fftPowerPeakMin', 'fftPowerPeakMax', 'fftPeakFreq', 'waveAverageWidth', 'waveFrequency', 'waveSpeedSlope', 'waveFitRSquared', 'sigB', 'analyzedDeltaMarkers', 'xCorrMaxima');
save(strcat(dataDir,filesep,'allParameters',date));

% Let user look at pictures if wanted, or close all
% close all;

end