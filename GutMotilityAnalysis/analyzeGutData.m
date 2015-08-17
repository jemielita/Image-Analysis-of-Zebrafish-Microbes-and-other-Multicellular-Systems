%% Program which calculates parameters of interest from gut motility data
% To do: -Change parameters to velocity magnitude rather than longitudinal
% component (or both)
%        -Vorticity calculations
%        -Get median pulse height from a median of a histogram of local
%        maxima from a soothed velocity vector field

function analyzeGutData(gutMesh, gutMeshVels, gutMeshVelsPCoords, fps, scale, imPath)

cd(imPath);
% cd .. % Uncomment when running gutMotility(Single) program(s), comment when manually running this program
dataDir='Data';
mkdir(dataDir);

%% Initialize variables
nV=size(gutMeshVels,1);
nU=size(gutMeshVels,2);
nT=size(gutMeshVels,4);
totalTimeFraction=1; % Use 1 if all
fractionOfTimeStart=size(gutMeshVelsPCoords,4); % Use size(gutMeshVelsPCoords,4) if all
markerNumStart=1;
markerNumEnd=size(gutMesh,2); % Use size(gutMesh,2) if all
time=1/fps:1/fps:nT/(fps*totalTimeFraction);
markerNum=1:nU;
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
whyr=[markerNumStart,markerNumEnd];
imshow(surfL',[], 'InitialMagnification', 'fit','XData', whyr, 'YData', 1/fps*erx);
set(gca,'YDir','normal')
colormap('Jet');
axis square;
h=gcf;
set(h, 'Position', get(0,'Screensize')); % Maximize figure.
title('Anterior-Posterior velocities down the gut','FontSize',20,'FontWeight','bold');
ylabel('Time (s)','FontSize',20);
xlabel('Marker number','FontSize',20);
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
arr=arr(end/2:end);
arr=zeros(size(arr,2),size(surfL,1));
erx=1:tauSubdiv:size(surfL,1);

figure
%hold all;
for i=1:tauSubdiv:size(surfL,1)
    r=xcorr(surfL(i,:),'unbiased');
    x=0:size(r,2)/2;
    dt=x/fps;
    %plot(dt,r(end/2:end),'Color',[sin(3.1415/(2*colorSize)*(i-1)),0,cos(3.1415/(2*colorSize)*(i-1))]);
    arr(:,i)=r(end/2:end);
end
surf(erx,dt,arr,'LineStyle','none');
colormap('Jet');
figure;
%plot(dt,zeros(1,size(dt,2)),'k-');
%hold off;
erx=[dt(1), dt(end)];
whyr=[markerNumStart,markerNumEnd];
imshow(arr,[], 'InitialMagnification', 'fit','XData', whyr, 'YData', erx);
set(gca,'YDir','normal')
colormap('Jet');
axis square;
h=gcf;
set(h, 'Position', get(0,'Screensize')); % Maximize figure.
title('Autocorrelations of anterior-aosterior velocities over time','FontSize',20,'FontWeight','bold');
ylabel('\tau (s)','FontSize',20);
xlabel('X','FontSize',20);
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

%% Global Tau Correlations of wave propagations
erx=int16(size(gutMeshVelsPCoords,4)/fractionOfTimeStart:(size(gutMeshVelsPCoords,4)/(fractionOfTimeStart)+size(gutMeshVelsPCoords,4)/totalTimeFraction-1));
surfL=squeeze(-mean(gutMeshVelsPCoords(:,markerNumStart:markerNumEnd,1,erx),1));
nCorrs=size(surfL,1)-1;
dummyR=xcorr(surfL(1,:),surfL(2,:),'unbiased'); % dummy because I'm lazy
fullXCorr=zeros(size(dummyR(1:end/2),2),nCorrs);
figure
%hold all;
for i=1:nCorrs
    for j=(i+1):size(surfL,1)
        r=xcorr(surfL(i,:),surfL(j,:),'unbiased');
        fullXCorr(:,j-i)=fullXCorr(:,j-i)+r(1:end/2)'/(nCorrs-j+i+1); % The normalization on r is an easy way to average each difference in marker distances 
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
whyr=[1,nCorrs];
imshow(trueXCorr,[], 'InitialMagnification', 'fit','XData', whyr, 'YData', erx);
set(gca,'YDir','normal')
colormap('Jet');
axis square;
h=gcf;
set(h, 'Position', get(0,'Screensize')); % Maximize figure.
title('Global cross correlations between anterior-posterior velocities over time','FontSize',20,'FontWeight','bold');
ylabel('\tau (s)','FontSize',20);
xlabel('\Delta x','FontSize',20);
zlabel('Correlation','FontSize',20);
set(findall(h,'type','axes'),'fontsize',15,'fontWeight','bold');
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

waveAverageWidth=2*mean(decayTimes)/fps; % The factor of 2 for the whole wave. In units of seconds!

%% Find peristaltic frequency, wave speed from cross-correlation
onlyShowFirstNSeconds=1:90*fps;
imH = imshow(trueXCorr(onlyShowFirstNSeconds,:),[], 'InitialMagnification','fit'); % Do not show this graph in seconds, must use frames!
set(gca,'YDir','normal')
axis square;
colormap('Jet');
% axis square;
% title('Global cross correlations between anterior-posterior velocities over time','FontSize',20,'FontWeight','bold');
% ylabel('\tau (s)','FontSize',20);
% xlabel('\Delta x','FontSize',20);
% zlabel('Correlation','FontSize',20);
% set(findall(imH,'type','axes'),'fontsize',15,'fontWeight','bold');

%imcontrast( imH ) ;
roughFitEstimate = impoly( 'Closed', false );
rFEPoly = getPosition( roughFitEstimate );
deltaTimeUser=(rFEPoly(2,2)-rFEPoly(1,2));
deltaMarkerUser=rFEPoly(2,1)-rFEPoly(1,1);
translateMarkerNumToMicron=scale*round(mean(diff(squeeze(gutMesh(1,:,1,1)))));
slopeUser=deltaTimeUser/deltaMarkerUser; % Note: x is in units of marker numbers, not pixels or microns
interceptUser=rFEPoly(1,2)-slopeUser*rFEPoly(1,1);
% waveSpeed=translateMarkerNumToMicron*deltaMarker/deltaTime; % CHANGE!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

% Ask for which ranges of x and t the user wants to search rather than
% using initialized variables, smoothing size
xTDlgAns=inputdlg({'What range of time should be searched around (s)? +-', ...
    'What range of x should we use? First x is at marker number ', ...
    'What range of x should we use? Last x is at marker number '}, 'Title',1,{'15','1','39'});

timeAroundToSearchForMax=str2double(xTDlgAns(1));
markerNumStartFreq=str2double(xTDlgAns(2));
markerNumEndFreq=str2double(xTDlgAns(3));

% Perform zero-phase digital filter to data
dMarker=(markerNumEndFreq-markerNumStartFreq);
%dTime=2*floor(fps*timeAroundToSearchForMax); % Always even
dTimeMin=round(min(slopeUser*(markerNumStartFreq:markerNumEndFreq)+interceptUser-timeAroundToSearchForMax));
dTimeMax=round(max(slopeUser*(markerNumStartFreq:markerNumEndFreq)+interceptUser+timeAroundToSearchForMax));
dTime=dTimeMax-dTimeMin;
reducedSmoothedVelocityMap=zeros(dMarker,dTime+1);
typeOfFilt=designfilt('lowpassfir', 'PassbandFrequency', .15, ...
        'StopbandFrequency', .65, 'PassbandRipple', 1, ...
        'StopbandAttenuation', 60);
    
for i=markerNumStartFreq:markerNumEndFreq
    %tAroundToSearch=round(fps*(slopeUser*i+interceptUser));
    subsetTrueXCorr=squeeze(trueXCorr(dTimeMin:dTimeMax,i));
    reducedSmoothedVelocityMap(i,:)=filtfilt(typeOfFilt,subsetTrueXCorr);
end

% Find maxima of all x's
[~, xCorrMaxima]=max(reducedSmoothedVelocityMap,[],2); % Name is misleading, should be xCorrMaximaTimes I think?

% Fit to line, get slope/intercept for wave speed/frequency, variance about linear fit
linearCoefs=polyfit(1:size(xCorrMaxima,1),xCorrMaxima',1);
waveFrequency=fps*60/(linearCoefs(2)+dTimeMin); % Units of per minutes
wavePeriod=(linearCoefs(2)+dTimeMin)/fps; % Units of seconds
waveSpeedSlope=fps*translateMarkerNumToMicron/linearCoefs(1); % Units of um/sec (fps*(micron/marker)/(frames/marker))

% Find R^2
yfit=polyval(linearCoefs,1:size(xCorrMaxima,1));
yresid=xCorrMaxima'-yfit;
SSresid = sum(yresid.^2); % Aweful units!
SStotal = (size(xCorrMaxima,1)-1) * var(xCorrMaxima);
waveFitRSquared = 1 - SSresid/SStotal;

%% Find median wave amplitude
velVectMaxes=max(surfL,[],1);
wavePeriodFrames=wavePeriod*fps;
[sortedMaxima,sortedMaximaIndices]=sort(velVectMaxes,'descend'); % Sort velocities based on magnitude, also save the corresponding indices
roughHowManyWaves=floor(size(sortedMaxima,2)/wavePeriodFrames)-1; % Roughly how many maxima should I expect?
localMaxesIndices=zeros(1,roughHowManyWaves);
localMaxIndex=1;
for i=1:size(sortedMaxima,2)
    inQ=sortedMaximaIndices(i); % Descend down list of maximum velocities indices
    thoseOutOfRangeMaybe=(abs(inQ-localMaxesIndices)>=wavePeriodFrames/2); % Compare with previously obtained list of maxima indices. Is the new index too close or is it out of range and thus acceptable?
    thoseNotEqualToThemselves=thoseOutOfRangeMaybe(abs(inQ-localMaxesIndices)~=inQ); % Be careful though: Any equal to themselves must be discarded (since it came from the zeros in our array)
    if isempty(thoseNotEqualToThemselves) % If empty, our list started off as empty! Populate it!
        localMaxesIndices(localMaxIndex)=sortedMaximaIndices(i);
        localMaxIndex=localMaxIndex+1;
    elseif min(thoseNotEqualToThemselves)==1 % If the list is cleared for all values (thus none can be 0, otherwise logical 0), this new value is a local maxima!
        localMaxesIndices(localMaxIndex)=sortedMaximaIndices(i);
        localMaxIndex=localMaxIndex+1;
    end
    if localMaxIndex>roughHowManyWaves % We only obtain the first (roughHowManyWaves) local maxima
        break;
    end
end

plot(velVectMaxes,'k-');hold on;plot(localMaxesIndices,velVectMaxes(localMaxesIndices),'ro');hold off;
averageMaxVelocities=mean(velVectMaxes(localMaxesIndices));

%%
% Save various parameters
analyzedDeltaMarkers=[markerNumStartFreq, markerNumEndFreq];
save(strcat(imPath,filesep,dataDir,filesep,'GutParameters',date),'averageMaxVelocities','waveAverageWidth','waveFrequency','wavePeriod','waveSpeedSlope','waveFitRSquared','SSresid','analyzedDeltaMarkers','xCorrMaxima');
save(strcat(imPath,filesep,dataDir,filesep,'allParameters',date));

% Let user look at pictures if wanted, or close all
% close all;

end