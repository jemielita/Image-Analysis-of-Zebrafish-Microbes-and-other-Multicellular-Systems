% Gut velocity histogram script

mainDirectory=uigetdir(pwd,'Directory containing fish sets to analyze'); %directory containing the images you want to analyze

cd(mainDirectory);

% Go into directory (for ease of writing code)
cd(mainDirectory);
fishDirect=dir;
% fishDirect(1:2)=[]; % Remove . and .., assumes ONLY directories here
fishDirect(strncmp({fishDirect.name}, '.', 1)) = []; % Removes . and .. and hidden files
nFD=size(fishDirect,1);
subFishDirect={};
fps=5;
histSize=40;
histSizzz=linspace(0,6.7,histSize);

% Xes=zeros(size(fishDirect,1),histSize);
Nes=zeros(size(fishDirect,1),histSize);
FishN=zeros(1,size(fishDirect,1));

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
        load 'analyzedGutData25-Aug-2015.mat'; % 8.19.15
        % load '?'; % 8.20.15
        % load '?'; % 8.21.15
        
        curFish=fishDirect(i).name;
        curFish(1:4)=[];
        fishNum=str2double(curFish);
        
        %% Initialize variables
        nV=size(gutMeshVels,1);
        nU=size(gutMeshVels,2);
        nT=size(gutMeshVels,4);
        totalTimeFraction=1; % Use 1 if all
        fractionOfTimeStart=size(gutMeshVelsPCoords,4); % Use size(gutMeshVelsPCoords,4) if all
        markerNumStart=1;
        markerNumEnd=size(gutMesh,2); % Use size(gutMesh,2) if all
        time=1/fps:1/fps:nT/(fps*totalTimeFraction);
        markerNum=1:nU;
        % timeToStartSearchFreq=4; % Units of seconds. I highly suggest NOT using 1, since autocorrelations at 1 are the highest. Suggested: > 4seconds
        % timeToSearchFreq=50; % Units of seconds
        pulseWidthLargestDecayTime=50; % Units of frames... I feel that's easier
        
        % Longitudinal Motion as a surface
        erx=int16(size(gutMeshVelsPCoords,4)/fractionOfTimeStart:(size(gutMeshVelsPCoords,4)/(fractionOfTimeStart)+size(gutMeshVelsPCoords,4)/totalTimeFraction-1));
        surfL=squeeze(-mean(gutMeshVelsPCoords(:,markerNumStart:markerNumEnd,1,erx),1));
        
%         figure;
%         erx=[erx(1), erx(end)];
%         whyr=[markerNumStart,markerNumEnd];
%         imshow(abs(surfL'),[], 'InitialMagnification', 'fit','XData', whyr, 'YData', 1/fps*erx);
%         set(gca,'YDir','normal')
%         colormap('Jet');
%         axis square;
%         h=gcf;
%         set(h, 'Position', get(0,'Screensize')); % Maximize figure.
%         title('Anterior-Posterior velocities down the gut','FontSize',20,'FontWeight','bold');
%         ylabel('Time (s)','FontSize',20);
%         xlabel('Marker number','FontSize',20);
%         set(findall(h,'type','axes'),'fontsize',15,'fontWeight','bold');
        
%         % Low pass filter to remove noise
%         kernH=fspecial('Gaussian',9,3);
%         surfLSmooth=imfilter(abs(surfL),kernH);
%         asdf=abs(surfL(:));
%         asdfS=surfLSmooth(:);
%         plot(asdf(1:1000),'r-');hold on;plot(asdfS(1:1000),'b-');hold off;
        kernSize=9;
        gaussFilter = gausswin(kernSize);
        gaussFilter = gaussFilter / sum(gaussFilter); % Normalize.
        linSurfL=abs(surfL'); % Want the markers to concat on eachother, not times
        linSurfL=linSurfL(:);
        filtSurfL=conv(linSurfL,gaussFilter,'same');
        % [N, X] = hist(filtSurfL,histSize);
        N = histc(filtSurfL,histSizzz);
        
        N=N/(sum(N));
        
        % Xes(i,:)=X;
        Nes(i,:)=N;
        FishN(1,i)=fishNum;
        
%         plot(linSurfL(1:1000),'r-');hold on;plot(filtSurfL(1:1000),'b-');hold off;
                
        cd ..
        
    end
    
    cd ..
    
end

% XesE=Xes(mod(FishN,2)==0,:);
NesE=Nes(mod(FishN,2)==0,:);
% XesO=Xes(mod(FishN,2)==1,:);
NesO=Nes(mod(FishN,2)==1,:);

figure;
hold on;
for i=1:size(NesE,1)
    plot(histSizzz,NesE(i,:),'r-');
end
for i=1:size(NesO,1)
    plot(histSizzz,NesO(i,:),'b-');
end
hold off;

figure;
hold on;
plot(histSizzz,mean(NesE,1),'r-');
plot(histSizzz,mean(NesO,1),'b-');
hold off;