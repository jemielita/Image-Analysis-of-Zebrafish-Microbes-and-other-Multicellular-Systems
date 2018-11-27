function [amplitudeVector, frequencyVector, durationVector] = motilityParametersOverTime(mainAnalysisDirectory, mainExperimentDirectoryContents, mainExperimentSubDirectoryContentsCell, analysisToPerform, analysisVariables)

%% Initialize variables
nDirectories = size(analysisToPerform, 2);
% currentAnalysisFile = load(strcat(mainAnalysisDirectory, filesep, currentAnalysesPerformedFileName)); % WARNING: Do not change this variable name without changing the save string below
% currentAnalysisPerformed = currentAnalysisFile.currentAnalysisPerformed; % WARNING: Don't change this variable name
% xMin = 0;
% xMax = 90;
% yMin = 0;
% yMax = 100;

% Progress bar
progtitle = sprintf('Preparing for analysis...');
progbar = waitbar(0, progtitle);  % will display progress

%% Loop through all checked directories to perform analysis on motility
for i=1:nDirectories
    
    % Progress bar update
    waitbar(i/nDirectories, progbar, ...
        sprintf('Performing longitudinal analysis for folder %d of %d', i, nDirectories));
    
    % Obtain the current directory size
    nSubDirectories = size(analysisToPerform(i).bools, 1);
    
    % Loop through all checked subdirectories
    for j=1:nSubDirectories
        
        % If we want to analyze it, do so, else skip
        if(analysisToPerform(i).bools(j,6))
            
            % ObtainCurrentDirectory
            curDir = strcat(mainAnalysisDirectory, filesep, mainExperimentDirectoryContents(i).name, filesep, mainExperimentSubDirectoryContentsCell{1, i}(j).name);
            [amplitudeVector, frequencyVector, durationVector, spectrograph, f] = obtainIndividualMotilityOverTime(curDir, analysisVariables, i);
            
        end
        
    end
    
end

    % Obtain the longitudinal data for a given folder
    function [amplitudeVector, frequencyVector, durationVector, spectrograph, f] = obtainIndividualMotilityOverTime(analysisDirectory, analysisVariables, curFolderIndex)
        
        % Load data
        loadedAnalysisFile = load(strcat(analysisDirectory, filesep, 'processedPIVOutput_Current.mat'));
        
        % Initialize variables
        minFreqToConsider = 0.25; % Units of per minute
        maxFreqToConsider = 4.0; % Units of per minute
        gutMeshVelsPCoords = loadedAnalysisFile.gutMeshVelsPCoords;
        gutMeshVals=squeeze(mean(gutMeshVelsPCoords(:,:,1,:),1));
        gutMeshVals = gutMeshVals(:,1:end);
        fps = str2double(analysisVariables{3}); % Units of frames per second
        micronsPerPixel = str2double(analysisVariables{4}); % Units of microns per pixel... look at the name
        deltaTBetweenWindowSlides = 60; % Units of seconds
        windowSize = 4; % Units of minutes
        nFrames = size(gutMeshVals, 2);
        totalNWindowSlides = floor((nFrames/fps - windowSize*60)/deltaTBetweenWindowSlides) + 1; % Subtraction is because we can't slide the window up until the last delta t... we can only slide it up to the size of the window, + 1 for initial frame
        amplitudeVector = zeros(1,totalNWindowSlides);
        frequencyVector = zeros(1,totalNWindowSlides);
        durationVector = zeros(1,totalNWindowSlides);
        NFFT = 2^nextpow2(windowSize*60*fps);
        spectrograph = zeros(floor(NFFT/2 + 1), totalNWindowSlides);
        f = fps/2*linspace(0,1,NFFT/2+1); % Units of per second
        [~, minFreqToConsiderIndex] = min(abs(f - minFreqToConsider/(60)));
        [~, maxFreqToConsiderIndex] = min(abs(f - maxFreqToConsider/(60)));
        figureLineWidths = 1.2;
        
        % Progress bar
        progtitle2 = sprintf('Preparing for FFT...');
        progbar2 = waitbar(0, progtitle2);  % will display progress
        
        % Loop through each time step of the video and perform analysis
        for ii=1:totalNWindowSlides
            
            % Progress bar update
            waitbar(ii/totalNWindowSlides, progbar2, ...
                sprintf('Performing FFT on window %d of %d', ii, totalNWindowSlides));
            
            % Define current variables
            startIndex = (ii - 1)*deltaTBetweenWindowSlides*fps + 1;
            endIndex = (ii - 1)*deltaTBetweenWindowSlides*fps + windowSize*60*fps;
            curGutMesh = gutMeshVals(:, startIndex:endIndex);
            fftGMV=zeros(size(curGutMesh,1),NFFT);
            L = length(curGutMesh);
            
            % Loop to do FFT on each position down the gut
            for jj=1:size(curGutMesh,1)
                fftGMVCur=fft((curGutMesh(jj,:) - mean(curGutMesh(jj,:)))/L,NFFT);
                fftGMV(jj,:)=fftGMVCur; % Division by fps is the same as multiplication by deltaT between frames, giving the right units, despite what engineers tell you
            end
            
            % Obtain amplitude and frequency
            fftRootPowerGMV=abs(fftGMV)*2*micronsPerPixel;
            singleFFTRPGMV=mean(fftRootPowerGMV);
            singleFFTRPGMV = singleFFTRPGMV(1:NFFT/2+1);
            [amplitude, ampIndex] = max(singleFFTRPGMV(minFreqToConsiderIndex:maxFreqToConsiderIndex));
            
            % Obtain the duration
            tauSubdiv=1;
%             ordinateValues=1:size(gutMeshVelsPCoords,4);
%             surfaceValues=squeeze(-mean(gutMeshVelsPCoords(:,1:end,1,ordinateValues),1));
            arr=xcorr(curGutMesh(1, :),'unbiased');
            endRByTwo=floor(length(arr)/2);
            arr=arr(endRByTwo+1:end);
            arr=zeros(size(arr,2),size(curGutMesh,1));
            for iii=1:tauSubdiv:size(curGutMesh,1)
                r=xcorr(curGutMesh(iii,:),'unbiased');
                endRByTwo=floor(length(r)/2);
                arr(:,iii)=r(endRByTwo+1:end);
            end
            typeOfFilt=designfilt('lowpassfir', 'PassbandFrequency', .15, ...
                'StopbandFrequency', .65, 'PassbandRipple', 1, ...
                'StopbandAttenuation', 60);
            autoCorrDecays=arr(1:50,:); % Units of frames, 50 chosen arbitrarily
            autoCorrDecaysTwo=autoCorrDecays;
            decayTimes=zeros(1,size(autoCorrDecaysTwo,2));
            for iii=1:size(autoCorrDecays,2)
                autoCorrDecaysTwo(:,iii)=filtfilt(typeOfFilt,autoCorrDecays(:,iii));
                eFoldingTimes=find(autoCorrDecaysTwo(:,iii)<=autoCorrDecaysTwo(1,iii)/exp(1));
                if(~isempty(eFoldingTimes))
                    decayTimes(iii)=eFoldingTimes(1);
                else
                    decayTimes(iii)=NaN;
                end
            end
            duration=2*mean(decayTimes)/fps; % The factor of 2 for the whole wave. In units of seconds!
            
            % Assign variables
            amplitudeVector(1, ii) = amplitude;
            frequencyVector(1, ii) = f(ampIndex);
            durationVector(1, ii) = duration;
            spectrograph(:, ii) = singleFFTRPGMV;
            
        end
        
        close(progbar2);
        
        % Plot Amplitude
        x = (0:size(amplitudeVector, 2) - 1)*deltaTBetweenWindowSlides/60; % Units of minutes
        figure;plot(x, amplitudeVector, 'Linewidth', figureLineWidths, 'Color', [0.1, 0.1, 0.1]);
        h=gcf;
        title('Amplitude','FontSize',20,'FontWeight','bold');
        xlabel('Time (min)','FontSize',20);
        ylabel('Amplitude ({\mu}m)','FontSize',20);
        set(findall(h,'type','axes'),'fontsize',15,'fontWeight','bold', 'FontName', 'Times New Roman', 'TickDir', 'out','box','off','Linewidth',figureLineWidths);
        %assignin('base', strcat('Amplitude',num2str(curFolderIndex)), amplitudeVector);
        %assignin('base', strcat('x',num2str(curFolderIndex)), x);
        
        % Plot Frequency
        figure;plot(x, frequencyVector*60, 'Linewidth', figureLineWidths, 'Color', [0.5, 0.5, 0.5]);
        h=gcf;
        title('Frequency','FontSize',20,'FontWeight','bold');
        xlabel('Time (min)','FontSize',20);
        ylabel('Frequency (minutes^{-1})','FontSize',20);
        set(findall(h,'type','axes'),'fontsize',15,'fontWeight','bold', 'FontName', 'Times New Roman', 'TickDir', 'out','box','off','Linewidth',figureLineWidths);
        %assignin('base', strcat('Frequency',num2str(curFolderIndex)), frequencyVector);
        
        % Plot Duration
        figure;plot(x, durationVector, 'Linewidth', figureLineWidths, 'Color', [0.5, 0.5, 0.5]);
        h=gcf;
        title('Duration','FontSize',20,'FontWeight','bold');
        xlabel('Time (min)','FontSize',20);
        ylabel('Duration (s)','FontSize',20);
        set(findall(h,'type','axes'),'fontsize',15,'fontWeight','bold', 'FontName', 'Times New Roman', 'TickDir', 'out','box','off','Linewidth',figureLineWidths);
        
        % Show the spectrograph
        % figure;surf(spectrograph);
        yData = (0:1/fps:(nFrames - 1)/fps)/60;
        % figure;imshow(spectrograph,[], 'InitialMagnification', 'fit','XData', [f(1), f(lazyIndex)], 'YData', [yData(1), yData(end)]);
        figure;imshow(spectrograph(minFreqToConsiderIndex:maxFreqToConsiderIndex, :),[0, 2*micronsPerPixel*60/1500], 'InitialMagnification', 'fit', 'YData', [f(minFreqToConsiderIndex)*60, f(maxFreqToConsiderIndex)*60], 'XData', [yData(1), yData(end)]);
        set(gca,'YDir','normal');
        colormap('hot');
        colorbar;
        axis square;
        h=gcf;
%         title('Spectrogram','FontSize',20);
%         xlabel('Time (minutes)','FontSize',20);
%         ylabel('Frequency (minutes^{-1})','FontSize',20);
        set(findall(h,'type','axes'),'fontsize',20, 'FontName', 'Arial', 'TickDir', 'out','box','off');
        
    end

close(progbar);

end