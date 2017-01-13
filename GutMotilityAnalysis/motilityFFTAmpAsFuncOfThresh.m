% Function which takes a gutMesh and its corresponding velocity vector 
% field, thresholds it at various values, and then calculates the FFT 
% for all thresholds, eventually plotting the amplitude of the waves as a
% function of threshold
%
% To do: Normalize each FFT at each threshold

function [totalThreshValues, countedMotPerTime] = motilityFFTAmpAsFuncOfThresh(mainAnalysisDirectory)

% Initialize variables
interpolationOutputName = 'processedPIVOutput';
%motilityParametersOutputName = 'motilityParameters';
fps = 5; % units of frames per second
%scale = 0.1625;
threshRes = 100; % How many times to threshold the image, equally spaced from 0 to maximum
sigma = 0.1; % How smooth the thresholding becomes
largestPeriodToSeeInFFT = 1800; % Units of seconds, eventually 1/s
minPeriodToSeeInFFT = 10;
percentImageShown = 0.6;
smoothHowMuch = 19;
%plusMinusAroundMeanFFTFreqPM = 0.25; % Units of per minute

% Obtain directory structures
[mainAnalysisDirectoryContents, mainAnalysisSubDirectoryContentsCell, nMainAnalysisSubDirectories] = obtainDirectoryStructure(mainAnalysisDirectory);

% ObtainCurrentDirectory for array sizes
curAnDir = strcat(mainAnalysisDirectory, filesep, mainAnalysisDirectoryContents(1).name, filesep, mainAnalysisSubDirectoryContentsCell{1, 1}(1).name);

% Load files
gutFile = load(strcat(curAnDir, filesep, interpolationOutputName, '_Current.mat'));
gutMesh = gutFile.gutMesh;

% Determine N files for waitbar
nFiles = 0;
for i=1:nMainAnalysisSubDirectories
    nFiles = nFiles + size(mainAnalysisSubDirectoryContentsCell{i},1);
end

totalThreshValues = zeros(nFiles, threshRes*percentImageShown);
countedMotPerTime = zeros(nFiles, size(gutMesh, 2), threshRes);

% Progress bar
progtitle = sprintf('Preparing to load data...');
progbar = waitbar(0, progtitle);  % will display progress

curIndex = 0;
for i=1:nMainAnalysisSubDirectories
    
    % Obtain the current directory size
    nSubDirectories = size(mainAnalysisSubDirectoryContentsCell{i},1);
    
    % Loop through all checked subdirectories to perform PIV
    for j=1:nSubDirectories
        
        % Progress bar update
        curIndex = curIndex + 1;
        waitbar(curIndex/nFiles, progbar, ...
            sprintf('Loading and analyzing data from file %d of %d', curIndex, nFiles));
        
        % ObtainCurrentDirectory
        curAnDir = strcat(mainAnalysisDirectory, filesep, mainAnalysisDirectoryContents(i).name, filesep, mainAnalysisSubDirectoryContentsCell{1, i}(j).name);
        
        % Load files
        gutFile = load(strcat(curAnDir, filesep, interpolationOutputName, '_Current.mat'));
%        gutMesh = gutFile.gutMesh;
%        translateMarkerNumToMicron=scale*round(mean(diff(squeeze(gutMesh(1,:,1,1))))); %Units of Micron/Marker
        gutMeshVelsPCoords = gutFile.gutMeshVelsPCoords;
%        paramsFile = load(strcat(curAnDir, filesep, motilityParametersOutputName, '_Current.mat'));
%        waveFrequency = paramsFile.waveFrequency;
        
        % Perform a FFT on the QSTMap
        gutMeshVals=squeeze(mean(gutMeshVelsPCoords(:,:,1,:),1)); % Average longitudinal component of transverse vectors down the gut, resulting dimension [xPosition, time]
        NFFT = 2^nextpow2(size(gutMeshVals,2));
        fftGMV = zeros(size(gutMeshVals,1),NFFT);
        meanFFTAsFuncOfThresh = zeros(threshRes,NFFT);
        maxQSTMapValue = max(gutMeshVals(:));
        muValues = linspace(0,maxQSTMapValue,threshRes);
        %        waveFreqPerSec = waveFrequency/60;
        %        beginningIndex = 1;
        
        % Progress bar
        progtitle2 = sprintf('Preparing to perform FFTs...');
        progbar2 = waitbar(0, progtitle2);  % will display progress
        
        for k=1:threshRes
            
            % Progress bar update
            waitbar(k/threshRes, progbar2, ...
                sprintf('Performing FFT from threshold level %d of %d', k, threshRes));
            
            % Define the current thresholded gutMeshVals
            gutMeshValsThreshed = 1/2 * gutMeshVals .* (1 + tanh((gutMeshVals - muValues(k))/(2 * sigma))); % In short: multiply a value in the QSTMap by a number less than 1 which depends on that value, with large values being reduced less than lower ones, making a smooth threshold
%             gutMeshValsThreshed = gutMeshVals;
%             gutMeshValsThreshed(gutMeshValsThreshed < muValues(k)) = 0;
            
            % Perform the FFT
            for l=1:size(gutMeshValsThreshed,1)
                fftGMVCur=fft(gutMeshValsThreshed(l,:) - mean(gutMeshValsThreshed(l,:)),NFFT);
                fftGMV(l,:)=fftGMVCur;
            end
            fftRootPowerGMV=abs(fftGMV);
            
            % Collapse data onto one mean curve
            singleFFTRPGMV=mean(fftRootPowerGMV);
            meanFFTAsFuncOfThresh(k, :) = (singleFFTRPGMV - min(singleFFTRPGMV(:)))/(max(singleFFTRPGMV(:)) - min(singleFFTRPGMV(:)));
            
%             %hold on;
%             if(mod(k, 5) == 1 && k < 52)
%                 figure;imshow(gutMeshValsThreshed',[], 'InitialMagnification', 'fit','XData', [0, size(gutMesh,2)*translateMarkerNumToMicron], 'YData', 1/fps*1:size(gutMeshVelsPCoords,4));
%                 set(gca,'YDir','normal')
%                 colormap('Jet');
%                 axis square;
%                 %N = hist(gutMeshValsThreshed(:),muValues);
%                 %plot(muValues(2:end),N(2:end),'o-');
%             end

            % Count the events higher than the mean
            for l=1:size(gutMeshValsThreshed,1)
                curLargerThanMeanBools = (smooth(gutMeshValsThreshed(l,:), smoothHowMuch) > mean(gutMeshValsThreshed(l,:)));
                diffOfBools = diff(curLargerThanMeanBools);
                diffOfBools(diffOfBools == -1) = 0; % Remove any 1's to 0's, meaning, count only new events
                totalEvents = sum(diffOfBools);
                if(curLargerThanMeanBools(1) == 1)
                    totalEvents = totalEvents + 1;
                end
                totalTime = (size(gutMeshValsThreshed, 2) + 1)/(fps*60); % Units of minutes
                countedMotPerTime(curIndex, l, k) = totalEvents/totalTime; % Units of events per minute
            end
            
        end
        %hold off;
        
        % Create a subset of the FFT
        f = fps/2*linspace(0,1,NFFT/2+1); % Units of per second
        subsetFFTBeginningF = floor(2*(NFFT/2+1)/(fps*largestPeriodToSeeInFFT)) + (floor(2*(NFFT/2+1)/(fps*largestPeriodToSeeInFFT))==0); % The second term is because I'm lazy. Just make it 1 if my floor makes it 0
        subsetFFTEndingF = floor(2*(NFFT/2+1)/(fps*minPeriodToSeeInFFT));
        subsetF = [f(subsetFFTBeginningF), f(subsetFFTEndingF)];
%        subsetF = [f(1), f(end)];
%        plusMinusAroundMeanFFTFreq = round(2*(NFFT/2 + 1)*plusMinusAroundMeanFFTFreqPM/(60*fps)); % Translates the search from plus or minus per minutes to plus or minus index numbers
%        translateMarkerNumToMicron=scale*round(mean(diff(squeeze(gutMesh(1,:,1,1))))); % Should be units of microns/marker
       subsetFullFFT = meanFFTAsFuncOfThresh(:,subsetFFTBeginningF:subsetFFTEndingF);
%         subsetFullFFT = meanFFTAsFuncOfThresh(:,1:length(f));
        
        fftToShow = subsetFullFFT(1:percentImageShown*end,:);
%         figure;imshow(fftToShow',[], 'InitialMagnification', 'fit','XData', [1, percentImageShown*size(subsetFullFFT,1)], 'YData', subsetF*60);
%         set(gca,'YDir','normal')
%         colormap('Jet');
%         axis square;
        [~, maxFreqOfMaxFFT] = max(fftToShow(:, 3:end), [], 2);
        totalThreshValues(curIndex,:) = f(maxFreqOfMaxFFT)';%/max(maxFFTToShow(:));
        
%         pause;
        close all;
        close(progbar2);
        
    end
    
end

close(progbar);
countedMotPerTime = countedMotPerTime(:,:,1:threshRes*percentImageShown);

end

%% Auxiliary functions

% obtainDirectoryStructure returns directory structures given a directory
function [directoryContents, subDirectoryContentsCell, nSubDirectories] = obtainDirectoryStructure(directory)
    
    % Obtain main directory structure
    directoryContents = dir(directory); % Obtain all main directory contents
    directoryContents(~[directoryContents.isdir]) = []; % Remove non-directories
    directoryContents(strncmp({directoryContents.name}, '.', 1)) = []; % Removes . and .. and hidden files
    nSubDirectories = size(directoryContents, 1);
    subDirectoryContentsCell = cell(1, nSubDirectories);
    
    % Loop through all sub-directory contents to obtain contents
    if(nSubDirectories > 0)
        for i = 1:nSubDirectories
            
            % Obtain main directory structure
            subDirectoryContents = dir(strcat(directory, filesep, directoryContents(i).name)); % Obtain all sub-directory contents
            subDirectoryContents(~[subDirectoryContents.isdir]) = []; % Remove non-directories
            subDirectoryContents(strncmp({subDirectoryContents.name}, '.', 1)) = []; % Removes . and .. and hidden files
            subDirectoryContentsCell{i} = subDirectoryContents;
            
        end
    end
end