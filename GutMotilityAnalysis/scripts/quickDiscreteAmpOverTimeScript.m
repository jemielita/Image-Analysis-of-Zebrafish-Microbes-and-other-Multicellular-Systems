% Script which plots amplitude over time

% fftPeakFreq

gutMeshVals=squeeze(mean(gutMeshVelsPCoords(:,:,1,:),1)); % Average longitudinal component of transverse vectors down the gut, resulting dimension [xPosition, time]

fps = 5;
timeWindowSize = 3; % Units of min
NWindows = ceil(size(gutMeshVals,2)/(timeWindowSize*60*fps));
ampVector = zeros(1,NWindows);
figure; hold on;

for i=1:NWindows
    
    startIndex = (i-1)*size(gutMeshVals,2)/NWindows + 1;
    endIndex = i*size(gutMeshVals,2)/NWindows;
    curGutMesh = gutMeshVals(:, startIndex:endIndex);
    NFFT = 2^nextpow2(size(curGutMesh,2));
    fftGMV=zeros(size(curGutMesh,1),NFFT);
    for j=1:size(curGutMesh,1)
        fftGMVCur=fft(curGutMesh(j,:) - mean(curGutMesh(j,:)),NFFT);
        fftGMV(j,:)=fftGMVCur;
    end
    fftRootPowerGMV=abs(fftGMV);
    singleFFTRPGMV=mean(fftRootPowerGMV);
    singleFFTRPGMV = singleFFTRPGMV(1:NFFT/2+1);
    f = fps/2*linspace(0,1,NFFT/2+1); % Units of per second
    [~, theRightIndex] = min(abs(f - fftPeakFreq));
    ampVector(i) = singleFFTRPGMV(theRightIndex);
    plot(f*60, singleFFTRPGMV, 'Color', [(i-1)/NWindows, 0, (NWindows-i+1)/NWindows]); plot(f(theRightIndex)*60, singleFFTRPGMV(theRightIndex), 'x', 'Color', [0, (i-1)/NWindows, (NWindows-i+1)/NWindows]);

end
hold off;
figure;plot(ampVector);