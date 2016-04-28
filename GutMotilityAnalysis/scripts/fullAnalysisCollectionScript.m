%% All parameters collection script, plot/day

% Initialize variables
moreDaysBool=true;
mainFolders={};
daysIndex=1;
meanGutData=zeros(1,12);
totalMeanRetGutData=[];
totalMeanWTUGutData=[];
totalMeanWTFGutData=[];
totalSTDRetGutData=[];
totalSTDWTUGutData=[];
totalSTDWTFGutData=[];
totalMedianRetGutData=[];
totalMedianWTUGutData=[];
totalMedianWTFGutData=[];
numParams=11;
userMonthChoice1=menu('Which month is being analyzed?','August','September');
august0September1=logical(userMonthChoice1-1);

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
        
        % Obtain parameters
        freqMean=waveFrequency/60; % Convert into per seconds from per minutes
        [fPeak, fSTD, fMin, fMax, fFreq]=gutFFTPeakFinder( gutMeshVelsPCoords, 5, freqMean );
        
        % Save values with fish number
        curFishChars=fishFolders(j).name;
        curFishChars(1:4)=[];
        curFishNum=str2double(curFishChars);
        
        % Collect data
        gutData(curFishNum,:)=[fPeak, fSTD, fMin, fMax, fFreq, freqMean, waveAverageWidth, waveSpeedSlope, analyzedDeltaMarkers(2), SSresid/analyzedDeltaMarkers(2), waveFitRSquared];
        
    end
    
    if ~august0September1
        % For August data, make fish type bools
        switch i
            case 1
                % Determine which fish are which (8/19/15)
                retBool=logical([0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1]);
                wTUBool=logical([1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0]);
                fishPosInTime=1:length(retBool);
                data5dpf=[gutData,retBool',wTUBool'];
                dayPF=5;
            case 2
                % Determine which fish are which (8/20/15)
                retBool=logical([1,0,1,0,1,0,1,0,1,0,0,0,1,0,0,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0]);
                wTUBool=logical([0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,0,0,1,0,0,0,1]);
                fishPosInTime=1:length(retBool);
                data6dpf=[gutData,retBool',wTUBool'];
                dayPF=6;
            case 3
                % Determine which fish are which (8/21/15)
                retBool=logical([0,0,0,1,0,1,0,0,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,0,0,1,0,1,0,1]);
                wTUBool=logical([1,0,1,0,1,0,1,0,1,0,1,0,0,0,0,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0]);
                fishPosInTime=1:length(retBool);
                data7dpf=[gutData,retBool',wTUBool'];
                dayPF=7;
        end
    else
        % For September data, make fish type bools
        switch i
            case 1
                % Determine which fish are whichh (9/16/15)
                retBool=logical([0,0,0,0,1,0,0,0,0,1,0,0,0,0,0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0]);
                wTUBool=logical([1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,0]);
                wTFBool=logical([0,0,0,1,0,0,1,0,0,0,0,1,0,1,0,0,0,0,1,0,0,1,0,1,0,0,1,0,1,0,0,0,0,0,0,0]);
                fishPosInTime=1:length(retBool);
                data5dpf=[gutData,retBool',wTUBool',wTFBool'];
                dayPF=5;
            case 2
                % Determine which fish are which (9/17/15)
                retBool=logical([0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,0]);
                wTUBool=logical([1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,0,0,1,0,0]);
                wTFBool=logical([0,0,0,0,0,0,0,0,1,0,0,1,0,0,0,0,0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0]);
                fishPosInTime=1:length(retBool);
                data6dpf=[gutData,retBool',wTUBool',wTFBool'];
                dayPF=6;
            case 3
                % Determine which fish are which (9/18/15)
                retBool=logical([0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0]);
                wTUBool=logical([0,0,1,0,0,1,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1,0,0,0,0,0,0,0,0,0,0]);
                wTFBool=logical([0,1,0,1,0,0,1,0,0,0,0,1,0,1,0,0,1,0,1,0,0,0,0,1,0,0,1,0,1,0,0,1,0,0,0,0,0,0]);
                fishPosInTime=1:length(retBool);
                data7dpf=[gutData,retBool',wTUBool',wTFBool'];
                dayPF=7;
        end
    end
    % For August and September data, mean, median, and std parameters per fish type
    meanRetGutData=mean(gutData(retBool,:));
    medianRetGutData=median(gutData(retBool,:));
    stdRetGutData=std(gutData(retBool,:))/sqrt(sum(retBool)); % Includes standard error of the mean
    meanWTUGutData=mean(gutData(wTUBool,:));
    medianWTUGutData=median(gutData(wTUBool,:));
    stdWTUGutData=std(gutData(wTUBool,:))/sqrt(sum(wTUBool)); % Includes standard error of the mean
    % For August and September data, collect all fish into a few arrays
    totalMeanRetGutData=[totalMeanRetGutData;meanRetGutData];
    totalSTDRetGutData=[totalSTDRetGutData;stdRetGutData];
    totalMedianRetGutData=[totalMedianRetGutData;medianRetGutData];
    totalMeanWTUGutData=[totalMeanWTUGutData;meanWTUGutData];
    totalSTDWTUGutData=[totalSTDWTUGutData;stdWTUGutData];
    totalMedianWTUGutData=[totalMedianWTUGutData;medianWTUGutData];
    if august0September1
        % For September data, mean, median, and std parameters per fish type
        meanWTFGutData=mean(gutData(wTFBool,:));
        medianWTFGutData=median(gutData(wTFBool,:));
        stdWTFGutData=std(gutData(wTFBool,:));
        % For September data, collect all fish into a few arrays
        totalMeanWTFGutData=[totalMeanWTFGutData;meanWTFGutData];
        totalMedianWTFGutData=[totalMedianWTFGutData;medianWTFGutData];
        totalSTDWTFGutData=[totalSTDWTFGutData;stdWTFGutData];
    end
    
end

% Convert frequency numbers from sec^-1 to min^-1
% totalMeanRetGutData(:,5:6)=60*totalMeanRetGutData(:,5:6);
totalSTDRetGutData(:,5:6)=60*totalSTDRetGutData(:,5:6);
totalMedianRetGutData(:,5:6)=60*totalMedianRetGutData(:,5:6);
% totalMeanWTUGutData(:,5:6)=60*totalMeanWTUGutData(:,5:6);
totalSTDWTUGutData(:,5:6)=60*totalSTDWTUGutData(:,5:6);
totalMedianWTUGutData(:,5:6)=60*totalMedianWTUGutData(:,5:6);
% Convert frequency numbers from sec^-1 to min^-1
% totalMeanWTFGutData(:,5:6)=60*totalMeanWTFGutData(:,5:6);
totalSTDWTFGutData(:,5:6)=60*totalSTDWTFGutData(:,5:6);
totalMedianWTFGutData(:,5:6)=60*totalMedianWTFGutData(:,5:6);

%% Plot data for all days
for i=1:numParams
    figure;
    for j=1:numDays
        
        % h = errorbar(4+j,totalMeanRetGutData(j,i),totalSTDRetGutData(j,i),'d','markersize',20, 'color', [0.4 0 0], 'markerfacecolor', [0.4 0 0]); hold on;
        h = errorbar(4+j,totalMedianRetGutData(j,i),totalSTDRetGutData(j,i),'d','markersize',20, 'color', [0.4 0 0], 'markerfacecolor', [0.7 0.2 0]); hold on;
        % errorbar(4+j,totalMeanWTUGutData(j,i),totalSTDWTUGutData(j,i),'s','markersize',20, 'color', [0 0 0.4], 'markerfacecolor', [0 0 0.4]);
        errorbar(4+j,totalMedianWTUGutData(j,i),totalSTDWTUGutData(j,i),'s','markersize',20, 'color', [0 0 0.4], 'markerfacecolor', [0.2 0 0.7]);
        if august0September1
            % errorbar(4+j,totalMeanWTFGutData(j,i),totalSTDWTFGutData(j,i),'o','markersize',20, 'color', [0 0.4 0], 'markerfacecolor', [0 0.4 0]);
            errorbar(4+j,totalMedianWTFGutData(j,i),totalSTDWTFGutData(j,i),'o','markersize',20, 'color', [0 0.3 0], 'markerfacecolor', [0 0.9 0.2]);
        end
        
    end
    hold off;
    % set(get(h,'Parent'), 'YScale', 'log');
    xlabel('Days Post Fertilization','FontSize',20);
    % legend('Mean Ret','MedianRet','MeanWTU','MedianWTU');
    if ~august0September1
        axis([4.5 7.5 0 max([ max(totalMeanRetGutData(:,i)), max(totalMedianRetGutData(:,i)), max(totalMeanWTUGutData(:,i)), max(totalMedianWTUGutData(:,i)) ])]);
    else
        axis([4.5 7.5 0 max([ max(totalMeanRetGutData(:,i)), max(totalMedianRetGutData(:,i)), max(totalMeanWTUGutData(:,i)), max(totalMedianWTUGutData(:,i)), max(totalMeanWTFGutData(:,i)), max(totalMedianWTFGutData(:,i)) ])]);
    end
    switch i
        case 1
            title('FFT Amplitude (Ret: Red, WTU: Blue, WTF: Green)','FontSize',17,'FontWeight','bold');
            ylabel('Amplitude (arb.)','FontSize',20);
            
        case 2
            title('FFT Amplitude STD Along Gut (Ret: Red, WTU: Blue, WTF: Green)','FontSize',17,'FontWeight','bold');
            ylabel('STD (arb.)','FontSize',20);
            
        case 3
            title('FFT Minimum Amplitude (Ret: Red, WTU: Blue, WTF: Green)','FontSize',17,'FontWeight','bold');
            ylabel('Amplitude (arb.)','FontSize',20);
            
        case 4
            title('FFT Maximum Amplitude (Ret: Red, WTU: Blue, WTF: Green)','FontSize',17,'FontWeight','bold');
            ylabel('Amplitude (arb.)','FontSize',20);
            
        case 5
            title('FFT Obtained Peristalsis Frequency (Ret: Red, WTU: Blue, WTF: Green)','FontSize',17,'FontWeight','bold');
            ylabel('Freq (1/min)','FontSize',20);
            
        case 6
            title('Peristalsis Frequency (Ret: Red, WTU: Blue, WTF: Green)','FontSize',17,'FontWeight','bold');
            ylabel('Freq (1/min)','FontSize',20);
            
        case 7
            title('Pulse Width (Ret: Red, WTU: Blue, WTF: Green)','FontSize',17,'FontWeight','bold');
            ylabel('Time (sec)','FontSize',20);
            
        case 8
            title('Wave Speed (Ret: Red, WTU: Blue, WTF: Green)','FontSize',17,'FontWeight','bold');
            ylabel('\mum/sec','FontSize',20);
            
        case 9
            title('Correlation Length (Ret: Red, WTU: Blue, WTF: Green)','FontSize',17,'FontWeight','bold');
            ylabel('Marker Number (arb.)','FontSize',20);
            
        case 10
            title('Wave Variance (Ret: Red, WTU: Blue, WTF: Green)','FontSize',17,'FontWeight','bold');
            ylabel('Arb.','FontSize',20);
            
        case 11
            title('Wave Fit RSquared (Ret: Red, WTU: Blue, WTF: Green)','FontSize',17,'FontWeight','bold');
            ylabel('RSquared Value','FontSize',20);
                    
    end
            
end
set(findall(h,'type','axes'),'fontsize',20,'fontWeight','bold');
    
%% Also plot wave amplitude with 0's included
figure;
if august0September1
    retBoolInc=logical([0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1]);
    wTUBoolInc=logical([1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0]);
    wTFBoolInc=logical([0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0]);
else
    retBoolInc=logical([0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1]);
    wTUBoolInc=logical([1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0]);
end
h = errorbar(5,mean(data5dpf(retBoolInc,1).*data5dpf(retBoolInc,12)),std(data5dpf(retBoolInc,1).*data5dpf(retBoolInc,12))/sqrt(sum(retBoolInc)),'d','markersize',20, 'color', [0.4 0 0], 'markerfacecolor', [0.7 0.2 0]); hold on;
errorbar(5,mean(data5dpf(wTUBoolInc,1).*data5dpf(wTUBoolInc,13)),std(data5dpf(wTUBoolInc,1).*data5dpf(wTUBoolInc,13))/sqrt(sum(wTUBoolInc)),'s','markersize',20, 'color', [0 0 0.4], 'markerfacecolor', [0.2 0 0.7]);
if august0September1
    errorbar(5,mean(data5dpf(wTFBoolInc,1).*data5dpf(wTFBoolInc,14)),std(data5dpf(wTFBoolInc,1).*data5dpf(wTFBoolInc,14))/sqrt(sum(wTFBoolInc)),'o','markersize',20, 'color', [0 0.3 0], 'markerfacecolor', [0 0.9 0.2]);
end

if august0September1
    errorbar(6,mean(data6dpf(retBoolInc,1).*data6dpf(retBoolInc,12)),std(data6dpf(retBoolInc,1).*data6dpf(retBoolInc,12))/sqrt(sum(retBoolInc)),'d','markersize',20, 'color', [0.4 0 0], 'markerfacecolor', [0.7 0.2 0]);
    errorbar(6,mean(data6dpf(wTUBoolInc,1).*data6dpf(wTUBoolInc,13)),std(data6dpf(wTUBoolInc,1).*data6dpf(wTUBoolInc,13))/sqrt(sum(wTUBoolInc)),'s','markersize',20, 'color', [0 0 0.4], 'markerfacecolor', [0.2 0 0.7]);
    errorbar(6,mean(data6dpf(wTFBoolInc,1).*data6dpf(wTFBoolInc,14)),std(data6dpf(wTFBoolInc,1).*data6dpf(wTFBoolInc,14))/sqrt(sum(wTFBoolInc)),'o','markersize',20, 'color', [0 0.3 0], 'markerfacecolor', [0 0.9 0.2]);
else
    errorbar(6,mean(data6dpf(~retBoolInc,1).*data6dpf(~retBoolInc,12)),std(data6dpf(~retBoolInc,1).*data6dpf(~retBoolInc,12))/sqrt(sum(retBoolInc)),'d','markersize',20, 'color', [0.4 0 0], 'markerfacecolor', [0.7 0.2 0]);
    errorbar(6,mean(data6dpf(~wTUBoolInc,1).*data6dpf(~wTUBoolInc,13)),std(data6dpf(~wTUBoolInc,1).*data6dpf(~wTUBoolInc,13))/sqrt(sum(wTUBoolInc)),'s','markersize',20, 'color', [0 0 0.4], 'markerfacecolor', [0.2 0 0.7]);
end

errorbar(7,mean(data7dpf(retBoolInc,1).*data7dpf(retBoolInc,12)),std(data7dpf(retBoolInc,1).*data7dpf(retBoolInc,12))/sqrt(sum(retBoolInc)),'d','markersize',20, 'color', [0.4 0 0], 'markerfacecolor', [0.7 0.2 0]);
errorbar(7,mean(data7dpf(wTUBoolInc,1).*data7dpf(wTUBoolInc,13)),std(data7dpf(wTUBoolInc,1).*data7dpf(wTUBoolInc,13))/sqrt(sum(wTUBoolInc)),'s','markersize',20, 'color', [0 0 0.4], 'markerfacecolor', [0.2 0 0.7]);
if august0September1
    errorbar(7,mean(data7dpf(wTFBoolInc,1).*data7dpf(wTFBoolInc,14)),std(data7dpf(wTFBoolInc,1).*data7dpf(wTFBoolInc,14))/sqrt(sum(wTFBoolInc)),'o','markersize',20, 'color', [0 0.3 0], 'markerfacecolor', [0 0.9 0.2]); hold off;
end

title('Gut Motility Amplitude (Ret: Red, WTU: Blue, WTF: Green)','FontSize',17,'FontWeight','bold');
ylabel('Amplitude (arb.)','FontSize',20);
xlabel('Days Post Fertilization','FontSize',20);
axis([4.5 7.5 0 300]); % Fix when needed

% Trim ret data wave speed with rSquared day7, put in var "realRetNums," do the following
% meanRealRetNums=mean(realRetNums);
% stdRealRetNums=std(realRetNums);
% medianRealRetNums=median(realRetNums);
% totalMedianRetGutData(3,8)=medianRealRetNums;