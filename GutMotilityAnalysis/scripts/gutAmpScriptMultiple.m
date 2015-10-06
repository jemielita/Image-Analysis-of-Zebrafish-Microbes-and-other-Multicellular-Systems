% Script which analyzes the gut motility amplitudes of multiple fish using
% the gutAmpScript
%
% To do: display fish number, allow retry if drawing sucks

% Initialize variables
continueBool=true;
rmsAmpStdAmpRmsQAmpStdQAmpFishnum=[];
velVectMaxesCell={};
smoothedVelVectMaxesCell={};
ii=1;

while continueBool
    
    % Run script
    gutAmpScript;
    
    % Save variables
    rmsAmpStdAmpRmsQAmpStdQAmpFishnum=[rmsAmpStdAmpRmsQAmpStdQAmpFishnum;rmsWaveAmps,stdWaveAmps,rmsQuiescentAmps,stdQuiescentAmps,fishNum];
    velVectMaxesCell{ii}=velVectMaxes;
    smoothedVelVectMaxesCell{ii}=smoothedVelVectMaxes;
    
    % Increase index
    ii=ii+1;
    
    % More fish to analyze?
    userContChoice=menu('Are there more fish to analyze?','Yes','No');
    
    % If not, exit loop
    if userContChoice==2
        continueBool=false;
    end
    
end

% And what do you get?
ampMean=rmsAmpStdAmpRmsQAmpStdQAmpFishnum(:,1)-rmsAmpStdAmpRmsQAmpStdQAmpFishnum(:,3);
ampStd=sqrt(rmsAmpStdAmpRmsQAmpStdQAmpFishnum(:,2).^2+rmsAmpStdAmpRmsQAmpStdQAmpFishnum(:,4).^2);
ampMeanStdFish=[ampMean,ampStd,rmsAmpStdAmpRmsQAmpStdQAmpFishnum(:,5)];

%% Plot the data
ampMeanFEvenInOrderOfTime=ampMean(mod(ampMeanStdFish(:,3),2)==0);
ampMeanFOddInOrderOfTime=ampMean(mod(ampMeanStdFish(:,3),2)==1);
ampStdFEvenInOrderOfTime=ampStd(mod(ampMeanStdFish(:,3),2)==0);
ampStdFOddInOrderOfTime=ampStd(mod(ampMeanStdFish(:,3),2)==1);

xEven=ampMeanStdFish(mod(ampMeanStdFish(:,3),2)==0,3);
xOdd=ampMeanStdFish(mod(ampMeanStdFish(:,3),2)==1,3);
h=figure;
% errorbar(xEven,ampMeanFEvenInOrderOfTime,ampStdFEvenInOrderOfTime,'r-');hold on;
% errorbar(xOdd,ampMeanFOddInOrderOfTime,ampStdFOddInOrderOfTime,'b-');hold off;
% For 8.19.15 and 8.21.15
errorbar(xEven,ampMeanFEvenInOrderOfTime,ampStdFEvenInOrderOfTime,'d', 'markersize', 14, 'color', [0.4 0 0], 'markerfacecolor', [0.7 0.2 0]);hold on;
errorbar(xOdd,ampMeanFOddInOrderOfTime,ampStdFOddInOrderOfTime,'o', 'markersize', 14, 'color', [0.0 0.3 0], 'markerfacecolor', [0.0 0.9 0.3]);hold off;
% For 8.20.15
% errorbar(xOdd,ampMeanFOddInOrderOfTime,ampStdFOddInOrderOfTime,'d', 'markersize', 14, 'color', [0.4 0 0], 'markerfacecolor', [0.7 0.2 0]);hold on;
% errorbar(xEven,ampMeanFEvenInOrderOfTime,ampStdFEvenInOrderOfTime,'o', 'markersize', 14, 'color', [0.0 0.3 0], 'markerfacecolor', [0.0 0.9 0.3]);hold off;
legend('Ret','WT');
% For 8.19.15
% title('Quiescent Subtracted R.M.S. Wave Amplitudes 5dpf Fish 8-19-15','FontSize',17,'FontWeight','bold');
% For 8.20.15
% title('Quiescent Subtracted R.M.S. Wave Amplitudes 6dpf Fish 8-20-15','FontSize',17,'FontWeight','bold');
% For 8.21.15
title('Quiescent Subtracted R.M.S. Wave Amplitudes 7dpf Fish 8-21-15','FontSize',17,'FontWeight','bold');
xlabel('Fish # (in order of time imaged)','FontSize',20);
ylabel('R.M.S. Amplitude (arb.)','FontSize',20);
set(findall(h,'type','axes'),'fontsize',15,'fontWeight','bold');
axis([0, max(ampMeanStdFish(:,3))+1, 0, max(ampMeanStdFish(:,1))+1]);

%% Save the data
saveDir=uigetdir(pwd,'Where would you like to save the data?: ');
save(strcat(saveDir,filesep,'ampParameters',date),'rmsAmpStdAmpRmsQAmpStdQAmpFishnum','velVectMaxesCell','smoothedVelVectMaxesCell','ampMeanStdFish');
save(strcat(saveDir,filesep,'plotReadyAmpParameters',date),'xEven','xOdd','ampMeanFEvenInOrderOfTime','ampMeanFOddInOrderOfTime','ampStdFEvenInOrderOfTime','ampStdFOddInOrderOfTime');