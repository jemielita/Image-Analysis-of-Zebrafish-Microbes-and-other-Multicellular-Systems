function [waveFrequency, wavePeriod, waveSpeedSlope, SSresid, waveFitRSquared, xCorrMaxima] = gutFreqWaveSpeedFinder( gutMesh, trueXCorr, fps )

% Find peristaltic frequency, wave speed from cross-correlation
onlyShowFirstNSeconds=1:90*fps;
imH = imshow(trueXCorr(onlyShowFirstNSeconds,:),[], 'InitialMagnification','fit'); % Do not show this graph in seconds, must use frames!
set(imH,'YDir','normal')
axis square;
colormap('Jet');

% Obtain rough line around maxima
roughFitEstimate = impoly( 'Closed', false );
rFEPoly = getPosition( roughFitEstimate );
deltaTimeUser=(rFEPoly(2,2)-rFEPoly(1,2));
deltaMarkerUser=rFEPoly(2,1)-rFEPoly(1,1);
translateMarkerNumToMicron=scale*round(mean(diff(squeeze(gutMesh(1,:,1,1)))));
slopeUser=deltaTimeUser/deltaMarkerUser; % Note: x is in units of marker numbers, not pixels or microns
interceptUser=rFEPoly(1,2)-slopeUser*rFEPoly(1,1);

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
waveFrequency=fps*60/(linearCoefs(2)+dTimeMin-1); % Units of per minutes, -1 for indexing at 1
wavePeriod=(linearCoefs(2)+dTimeMin-1)/fps; % Units of seconds
waveSpeedSlope=fps*translateMarkerNumToMicron/linearCoefs(1); % Units of um/sec (fps*(micron/marker)/(frames/marker))

% Find R^2
yfit=polyval(linearCoefs,1:size(xCorrMaxima,1));
yresid=xCorrMaxima'-yfit;
SSresid = sum(yresid.^2); % Awful units!
SStotal = (size(xCorrMaxima,1)-1) * var(xCorrMaxima);
waveFitRSquared = 1 - SSresid/SStotal;

end