function [waveFrequency, waveSpeedSlope, BByFPS, sigB, waveFitRSquared, xCorrMaxima, analyzedDeltaMarkers, g] = gutFreqWaveSpeedFinder( gutMesh, trueXCorr, fps, scale )

% Find peristaltic frequency, wave speed from cross-correlation
g = figure;
NSeconds=90;
onlyShowFirstNSeconds=1:NSeconds*fps;
imshow(trueXCorr(onlyShowFirstNSeconds,:),[], 'InitialMagnification','fit', 'YData', [0, NSeconds]);
set(gca,'YDir','normal')
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
    'What range of x should we use? Last x is at marker number '}, 'Title',1,{'5','1','39'});
timeAroundToSearchForMax=str2double(xTDlgAns(1));
markerNumStartFreq=str2double(xTDlgAns(2));
markerNumEndFreq=str2double(xTDlgAns(3));

% Perform zero-phase digital filter to data
dMarker=(markerNumEndFreq-markerNumStartFreq);
%dTime=2*floor(fps*timeAroundToSearchForMax); % Always even
dTimeMin=round(min(slopeUser*(markerNumStartFreq:markerNumEndFreq)+interceptUser-timeAroundToSearchForMax));
dTimeMax=round(max(slopeUser*(markerNumStartFreq:markerNumEndFreq)+interceptUser+timeAroundToSearchForMax));
dTime=fps*(dTimeMax-dTimeMin);
% This next if statement is needed for my filter, minimum size of 27 (using literals here is not wise, I know)
if(dTime*fps<27)
    addToDTimes = ceil((dTime*fps-27)/2);
    dTimeMin = dTimeMin - addToDTimes;
    dTimeMax = dTimeMax + addToDTimes;
    disp('Warning: Time range extended to allow filter to work. See gutFreqWaveSpeedFinder line 40 for more info');
end
reducedSmoothedVelocityMap=zeros(dMarker,dTime+1);
typeOfFilt=designfilt('lowpassfir', 'PassbandFrequency', .15, ...
        'StopbandFrequency', .65, 'PassbandRipple', 1, ...
        'StopbandAttenuation', 60);
    
for i=markerNumStartFreq:markerNumEndFreq
    %tAroundToSearch=round(fps*(slopeUser*i+interceptUser));
    subsetTrueXCorr=squeeze(trueXCorr(fps*dTimeMin:fps*dTimeMax,i));
    reducedSmoothedVelocityMap(i,:)=filtfilt(typeOfFilt,subsetTrueXCorr);
end

% Find maxima
[~, xCorrMaxima]=max(reducedSmoothedVelocityMap,[],2); % Name is misleading, should be xCorrMaximaTimes I think?
xes = markerNumStartFreq:markerNumEndFreq;
[A, ~, B, sigB, waveFitRSquared, ~, ~] = fitline( xes, xCorrMaxima' );
waveFrequency=60/((A-1)/fps+dTimeMin); % Units of per minutes, -1 for indexing A at 1
waveSpeedSlope=fps*translateMarkerNumToMicron/B; % Units of um/sec ((frames/sec)*(micron/marker)/(frames/marker))
BByFPS = B/fps;

% % Fit to line, get slope/intercept for wave speed/frequency, variance about linear fit
% linearCoefs=polyfit(1:size(xCorrMaxima,1),xCorrMaxima',1);
% %fprintf('Intercept: %d \n',(linearCoefs(2)+dTimeMin-1));
% 
% % Find R^2
% yfit=polyval(linearCoefs,1:size(xCorrMaxima,1));
% yresid=xCorrMaxima'-yfit;
% SSresid = sum(yresid.^2); % Awful units!
% SStotal = (size(xCorrMaxima,1)-1) * var(xCorrMaxima);
% waveFitRSquared = 1 - SSresid/SStotal;

analyzedDeltaMarkers=[markerNumStartFreq, markerNumEndFreq];

end