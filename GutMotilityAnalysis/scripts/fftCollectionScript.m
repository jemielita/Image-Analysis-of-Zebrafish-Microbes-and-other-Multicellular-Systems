% fft script for analyzing amplitudes of analyzed fish videos (must have
% gutMeshVelsPCoords)

disp('Warning: I hard coded an FPS of 5 into the function call to gutFFTPeakFinder');
mainFolder=uigetdir('Where is the main directory located?');
fishFolders=dir(mainFolder);
fishFolders(strncmp({fishFolders.name}, '.', 1)) = []; % Removes . and .. and hidden files
fishFolders(~[fishFolders.isdir])=[]; % Removes any non-directories

gutFFTData=zeros(size(fishFolders,1),4);
sameBool1=false;
sameBool2=false;

% Loop through fish directories
for i=1:size(fishFolders,1)
    
    % Get to data file
    curFold=strcat(mainFolder,filesep,fishFolders(i).name);
    nextFold=dir(curFold);
    nextFold(strncmp({nextFold.name}, '.', 1)) = []; % Removes . and .. and hidden files
    nextFold(~[nextFold.isdir])=[]; % Removes any non-directories
    nextFold=nextFold(1).name;
    curFold=strcat(curFold,filesep,nextFold);
    
    % Load .mat file for gutMesh related data, if multiple .mat files, let user select one
    theFileName=dir(strcat(curFold,filesep,'analyzedGutData*.mat'));
    fileIndex=1;
    if( length(theFileName) > 1)
        if(~sameBool1)
            disp('Multiple analyzedGutData files; Pick one by entering the number');
            for j=1:length(theFileName)
                fileNumStr=sprintf('%i) %s',j,theFileName(j).name);
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
            for j=1:length(theFileName)
                fileNumStr=sprintf('%i) %s',j,theFileName(j).name);
                disp(fileNumStr);
            end
            fileIndex=input('Which number?: ');
            % Do this for all?
            userContChoice2=menu('Choose the same for all fish?','Yes','No');
            % If not, exit loop
            if userContChoice1==1
                sameBool2=true;
            end
        end
    end
    load(strcat(curFold,filesep,theFileName(fileIndex).name));
    
    % Obtain parameters
    freqMean=waveFrequency/60; % Convert into per seconds from per minutes
    [fPeak, fSTD, fMin, fMax]=gutFFTPeakFinder( gutMeshVelsPCoords, 5, freqMean );
    
    % Save values with fish number
    curFishChars=fishFolders(i).name;
    curFishChars(1:4)=[];
    curFishNum=str2double(curFishChars);
    
    gutFFTData(curFishNum,:)=[fPeak, fSTD, fMin, fMax];
    
end

% Determine which fish are which
retBool=logical([0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0]);
wTUBool=logical([1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,0]);
wTFBool=logical([0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0]);
fishPosInTime=1:length(retBool);

% Assign variables per fish type
paramsRet=gutFFTData(retBool,:);
paramsWTU=gutFFTData(wTUBool,:);
paramsWTF=gutFFTData(wTFBool,:);

% Obtain mean and std per fish type
meanAmpRet=mean(paramsRet(:,1));
stdAmpRet=std(paramsRet(:,1));
meanAmpWTU=mean(paramsWTU(:,1));
stdAmpWTU=std(paramsWTU(:,1));
meanAmpWTF=mean(paramsWTF(:,1));
stdAmpWTF=std(paramsWTF(:,1));

% Plot time series data
figure;
h=plot(fishPosInTime(retBool),paramsRet(:,1),'r-');hold on;plot(fishPosInTime(wTUBool),paramsWTU(:,1),'b-');plot(fishPosInTime(wTFBool),paramsWTF(:,1),'g-');hold off;
title('Wave Amplitudes (Red: Ret, Blue: WTU, Green: WTF)','FontSize',17,'FontWeight','bold');
xlabel('Fish # (in order of time imaged)','FontSize',20);
ylabel('Amplitude (arb.)','FontSize',20);
set(findall(h,'type','axes'),'fontsize',15,'fontWeight','bold');