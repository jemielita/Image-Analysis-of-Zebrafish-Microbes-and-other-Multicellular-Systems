% Script which collects data from gutMotility analysis and puts it together

mainDirectory=uigetdir(pwd,'Directory containing fish sets to analyze'); %directory containing the images you want to analyze

cd(mainDirectory);

% Initialize variables
subDir='DeconstructedImages';

% Go into directory (for ease of writing code)
cd(mainDirectory);
fishDirect=dir;
% fishDirect(1:2)=[]; % Remove . and .., assumes ONLY directories here
fishDirect(strncmp({fishDirect.name}, '.', 1)) = []; % Removes . and .. and hidden files
nFD=size(fishDirect,1);
subFishDirect={};

paramsAmpWidFreqPeriodSpeedSsresidbynR2FN=[];

%% Loop through fish directories to obtain masks
for i=1:nFD
    
    % Find appropriate directory
    subDire=dir(fishDirect(i).name);
    % subDire(1:2)=[]; % Better below
    subDire(strncmp({subDire.name}, '.', 1)) = []; % Removes . and ..
    subFishDirect(i).name={subDire.name};
    nSFD=size(subFishDirect(i).name,2);
    cd(fishDirect(i).name);
    
    for j=1:nSFD
        
        cd(subDire(1).name);
        cd(subDir);
        cd 'Data';
        % load 'GutParameters25-Aug-2015.mat'; % 8.19.15
        % load 'GutParameters26-Aug-2015.mat'; % 8.20.15
        % load 'GutParameters27-Aug-2015.mat'; % 8.21.15
        load 'GutParameters04-Oct-2015.mat'; % 9.18.15
        
        curFish=fishDirect(i).name;
        curFish(1:4)=[];
        fishNum=str2double(curFish);
        
        paramsAmpWidFreqPeriodSpeedSsresidbynR2FN=[paramsAmpWidFreqPeriodSpeedSsresidbynR2FN;averageMaxVelocities,waveAverageWidth,waveFrequency,wavePeriod,waveSpeedSlope,SSresid/analyzedDeltaMarkers(2),waveFitRSquared,fishNum];
        
        cd ../../..
        
    end
    
    cd ..
    
end

% paramsOdd=paramsAmpWidFreqPeriodSpeedSsresidbynR2FN(mod(paramsAmpWidFreqPeriodSpeedSsresidbynR2FN(:,8),2)==1,:);
% paramsEven=paramsAmpWidFreqPeriodSpeedSsresidbynR2FN(mod(paramsAmpWidFreqPeriodSpeedSsresidbynR2FN(:,8),2)==0,:);
retBool=logical([0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0]);
wTUBool=logical([1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,0,0,0]);
wTFBool=logical([0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,0,0]);
fishPosInTime=1:length(retBool);
paramsRet=paramsAmpWidFreqPeriodSpeedSsresidbynR2FN(retBool,:);
paramsWTU=paramsAmpWidFreqPeriodSpeedSsresidbynR2FN(wTUBool,:);
paramsWTF=paramsAmpWidFreqPeriodSpeedSsresidbynR2FN(wTFBool,:);

% WT odd on 8.19.15; WT even on 8.20.15; WT odd on 8.21.15... see lab notebook
% meanAmpEven=mean(paramsEven(:,1));
% stdAmpEven=std(paramsEven(:,1));
% meanAmpOdd=mean(paramsOdd(:,1));
% stdAmpOdd=std(paramsOdd(:,1));
meanAmpRet=mean(paramsRet(:,1));
stdAmpRet=std(paramsRet(:,1));
meanAmpWTU=mean(paramsWTU(:,1));
stdAmpWTU=std(paramsWTU(:,1));
meanAmpWTF=mean(paramsWTF(:,1));
stdAmpWTF=std(paramsWTF(:,1));

%% For 9.18.15
h=plot(fishPosInTime(retBool),paramsRet(:,1),'r-');hold on;plot(fishPosInTime(wTUBool),paramsWTU(:,1),'b-');plot(fishPosInTime(wTFBool),paramsWTF(:,1),'g-');hold off;
title('Wave Amplitudes (Red: Ret, Blue: WTU, Green: WTF)','FontSize',17,'FontWeight','bold');
xlabel('Fish # (in order of time imaged)','FontSize',20);
ylabel('Amplitude (arb.)','FontSize',20);
set(findall(h,'type','axes'),'fontsize',15,'fontWeight','bold');

% For 8.19.15
% plot([paramsEven(6,1);paramsEven(13:15,1);paramsEven(1:5,1);paramsEven(7:12,1)],'r-');hold on;plot([paramsOdd(11:14,1);paramsOdd(1:10,1)],'b-');hold off;

% For 8.20.15
% plot([paramsEven(6,1);paramsEven(13:15,1);paramsEven(1:5,1);paramsEven(7:12,1)],'b-');hold on;plot([paramsOdd(1,1);paramsOdd(11:14,1);paramsOdd(2:10,1)],'r-');hold off;

% For 8.21.15
% plot([paramsEven(12:14,1);paramsEven(1:11,1)],'r-');hold on;plot([paramsOdd(1,1);paramsOdd(11:14,1);paramsOdd(2:10,1)],'b-');hold off;