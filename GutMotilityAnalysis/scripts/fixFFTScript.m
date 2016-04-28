% This script fixes fft problems I had when I forgot a factor of fps. It will probably be useless in the future

moreDaysBool=true;
mainFolders={};
daysIndex=1;
numParams=11;
fps = 5;

% Obtain all data directories to analyze
while moreDaysBool
    
    % Obtain Directory
    mainFolder=uigetdir('Where is the next fish directory located?');
    mainFolders{daysIndex}=mainFolder;
    daysIndex=daysIndex+1;
    
    userContChoice1=menu('Are there more fish data sets?','Yes','No');
    % If not, exit loop
    if userContChoice1==2
        moreDaysBool=false;
    end
    
end

% Initialize new variables from prompt
numDays=size(mainFolders,2);

% Obtain all data for all days
for i=1:numDays
    
    % Obtain all fish folders to loop through
    fishFolders=dir(mainFolders{i});
    fishFolders(strncmp({fishFolders.name}, '.', 1)) = []; % Removes . and .. and hidden files
    fishFolders(~[fishFolders.isdir])=[]; % Removes any non-directories
    
    % Initialize loop variables
    gutData=zeros(size(fishFolders,1),numParams);
    sameBool1=false;
    sameBool2=false;
    
    % Loop through fish directories
    for j=1:size(fishFolders,1)
        
        % Get to data file
        curFold=strcat(mainFolders{i},filesep,fishFolders(j).name);
        nextFold=dir(curFold);
        nextFold(strncmp({nextFold.name}, '.', 1)) = []; % Removes . and .. and hidden files
        nextFold(~[nextFold.isdir])=[]; % Removes any non-directories
        nextFold=nextFold(1).name; % Purposeful hardcoding of 1; should only be one section
        curFold=strcat(curFold,filesep,nextFold);
        
        % Load .mat file for gutMesh related data, if multiple .mat files, let user select one
        theFileName=dir(strcat(curFold,filesep,'analyzedGutData*.mat'));
        fileIndex=1;
        if( length(theFileName) > 1)
            if(~sameBool1)
                disp('Multiple analyzedGutData files; Pick one by entering the number');
                for k=1:length(theFileName)
                    fileNumStr=sprintf('%i) %s',k,theFileName(k).name);
                    disp(fileNumStr);
                end
                fileIndex=input('Which number?: ');
                % Do this for all?
                userContChoice1=menu('Choose the same for all fish?','Yes','No');
                % If not, exit loop
                if userContChoice1==1
                    sameBool1=true;
                end
            end
        end
        load(strcat(curFold,filesep,theFileName(fileIndex).name));
        
        % Load .mat file for waveFreq data, if multiple .mat files, let user select one
        curFold=strcat(curFold,filesep,'DeconstructedImages',filesep,'Data');
        waveFreqFileLoc=strcat(curFold,filesep,'GutParameters*.mat');
        theFileName=dir(waveFreqFileLoc);
        fileIndex=1;
        if( length(theFileName) > 1)
            if(~sameBool2)
                disp('Multiple GutParameters files; Pick one by entering the number');
                for k=1:length(theFileName)
                    fileNumStr=sprintf('%i) %s',k,theFileName(k).name);
                    disp(fileNumStr);
                end
                fileIndex=input('Which number?: ');
                % Do this for all?
                userContChoice2=menu('Choose the same for all fish?','Yes','No');
                % If not, exit loop
                if userContChoice2==1
                    sameBool2=true;
                end
            end
        end
        load(strcat(curFold,filesep,theFileName(fileIndex).name));
        
        [fftPowerPeak, fftPowerPeakSTD, fftPowerPeakMin, fftPowerPeakMax, fftPeakFreq] = gutFFTPeakFinder( gutMeshVelsPCoords, fps, waveFrequency/60); % Outputs will be saved % waveFrequency/60 to change from min^-1 to s^-1
        
        % Save various parameters
        save(strcat(curFold,filesep,'GutParameters',date),'fftPowerPeak','fftPowerPeakSTD', 'fftPowerPeakMin', 'fftPowerPeakMax', 'fftPeakFreq', 'waveAverageWidth', 'waveFrequency', 'waveSpeedSlope', 'waveFitRSquared', 'sigB', 'analyzedDeltaMarkers', 'xCorrMaxima');
        save(strcat(curFold,filesep,'allParameters',date));
        
    end
    
end