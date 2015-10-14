function [fftPowerPeak, fftPowerPeakSTD, fftPowerPeakMin, fftPowerPeakMax] = gutFFTPeakFinder( gutMeshVelsPCoords, fps, freqMean )

% Initialize variables
plusMinusSearchAroundMean=5;

% Do FFT on data
gutMeshVals=squeeze(mean(gutMeshVelsPCoords(:,:,1,:),1)); % Average longitudinal component of transverse vectors down the gut, resulting dimension [xPosition, time]
NFFT = 2^nextpow2(size(gutMeshVals,2));
fftGMV=zeros(size(gutMeshVals,1),NFFT);
for i=1:size(gutMeshVals,1)
    fftGMVCur=fft(gutMeshVals(i,:),NFFT);
    fftGMV(i,:)=fftGMVCur;
end
fftPowerGMV=abs(fftGMV).^2;

% % Plot results
% x=1:size(gutMeshVals,1);
% t=freqDomain(2:end)*fps; % Units of per second
% z=abs(fftGMV(:,2:end/2));
% surf(x,t,z','LineStyle','none');
% colormap('Jet');

% Collapse data onto one mean curve
singleFFTPGMV=mean(fftPowerGMV);
f = fps/2*linspace(0,1,NFFT/2+1); % Units of per second
[~, indMean]=min(abs(f-freqMean));

% Find strength of pulses around mean
subsetFFT=singleFFTPGMV(indMean-plusMinusSearchAroundMean:indMean+plusMinusSearchAroundMean);
[fftPowerPeak, whereQ]=max(subsetFFT);
fftPowerPeakSTD=std(fftPowerGMV(:,indMean-plusMinusSearchAroundMean+whereQ-1));
fftPowerPeakMin=min(fftPowerGMV(:,indMean-plusMinusSearchAroundMean+whereQ-1));
fftPowerPeakMax=max(fftPowerGMV(:,indMean-plusMinusSearchAroundMean+whereQ-1));

end