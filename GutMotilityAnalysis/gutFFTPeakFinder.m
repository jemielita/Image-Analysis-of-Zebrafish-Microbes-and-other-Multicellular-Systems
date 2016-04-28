function [fftRPowerPeak, fftRPowerPeakSTD, fftRPowerPeakMin, fftRPowerPeakMax, fftPeakFreq] = gutFFTPeakFinder( gutMeshVelsPCoords, fps, freqMean )

% Initialize variables
plusMinusSearchAroundMean=8;

% Do FFT on data
gutMeshVals=squeeze(mean(gutMeshVelsPCoords(:,:,1,:),1)); % Average longitudinal component of transverse vectors down the gut, resulting dimension [xPosition, time]
NFFT = 2^nextpow2(size(gutMeshVals,2));
fftGMV=zeros(size(gutMeshVals,1),NFFT);
for i=1:size(gutMeshVals,1)
    fftGMVCur=fft(gutMeshVals(i,:),NFFT);
    fftGMV(i,:)=fftGMVCur;
end
fftRootPowerGMV=abs(fftGMV);

% Collapse data onto one mean curve
singleFFTRPGMV=mean(fftRootPowerGMV);
f = fps/2*linspace(0,1,NFFT/2+1); % Units of per second
[~, indMean]=min(abs(f-freqMean));

% Find strength of pulses around mean
beginningIndex=(indMean-plusMinusSearchAroundMean)*(indMean-plusMinusSearchAroundMean>0)+(indMean-plusMinusSearchAroundMean<1);
subsetFFT=singleFFTRPGMV(beginningIndex:indMean+plusMinusSearchAroundMean);
[fftRPowerPeak, whereQ]=max(subsetFFT);
actualMaxPosition=(indMean-plusMinusSearchAroundMean+whereQ-1)*(indMean-plusMinusSearchAroundMean+whereQ-1>0)+(indMean-plusMinusSearchAroundMean+whereQ-1<=0);
fftPeakFreq=f(actualMaxPosition);
fftRPowerPeakSTD=std(fftRootPowerGMV(:,actualMaxPosition));
fftRPowerPeakMin=min(fftRootPowerGMV(:,actualMaxPosition));
fftRPowerPeakMax=max(fftRootPowerGMV(:,actualMaxPosition));

% % Plot results
% x=1:size(gutMeshVals,1);
% % t=f(2:end)*fps; % Units of per second
% z=abs(fftRootPowerGMV(:,2:end/2));
% figure; surf(x,f(1:indMean+plusMinusSearchAroundMean),z(:,1:indMean+plusMinusSearchAroundMean)','LineStyle','none');
% colormap('Jet');

% x=1:size(gutMeshVals,1);
% z=abs(fftRootPowerGMV(:,2:end/2));
% figure; surf(x,60*f(1:80),z(:,1:80)','LineStyle','none');
% colormap('Jet');
% axis square;
% h=gcf;
% set(h, 'Position', get(0,'Screensize')); % Maximize figure.
% ylabel('Freq (min^{-1})','FontSize',20);
% xlabel('Marker Number','FontSize',20);
% set(findall(h,'type','axes'),'fontsize',15,'fontWeight','bold');

% figure; imshow(z(:,1:80)',[], 'InitialMagnification', 'fit','XData', [x(1), x(end)], 'YData', [f(80), f(1)]);
% colormap('Jet');
% axis square;
% h=gcf;
% set(h, 'Position', get(0,'Screensize')); % Maximize figure.

end