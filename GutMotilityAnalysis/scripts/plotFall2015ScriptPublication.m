% Script which plots the fall2015Data in a combined fashion. Assumes the
% fall2015Data is loaded into the workspace

%% Initialize variables
colorWheelBorder = [ [0, 0, 0.4]; [0, 0.3, 0]; [0.4, 0, 0] ];
colorWheelFill = [[0.2 0.3 0.8]; [0.2 0.9 0.2]; [0.9 0.3 0.1]];
ampYMin = 0;
ampYMax = 52;
freqYMin = 1.2;
freqYMax = 3.3;
dataSizeArrays = zeros(2,6); % First index is (1 = control, 2 = experiment, e.g., 1 = wt, 2 = ret), second index is day mixed with experiment (1-3 is wt vs ret, 4-6 is fed vs unfed)
fps = 5;
micronsPerPixel = 0.325;

% Obtain wt vs ret data from both experiments
modifiedFall2015Data = fall2015Data;
wtVsRetSet = modifiedFall2015Data(1:6);
unfedVsFedSet = modifiedFall2015Data(4:9);

% Remove fed fish from ret set and vice versa
for i=1:6 % Important; 1-3 removes ret from fed, 4-6 removes fed from ret
    wtVsRetSet(i).FishParameters(2:6, wtVsRetSet(i).FishType(2, :)) = NaN; % Remove all fed fish
    unfedVsFedSet(i).FishParameters(2:6, unfedVsFedSet(i).FishType(3, :)) = NaN; % Remove all ret fish
end

% Collect all useful data per day per fish type
dayFourWTVsRet = [[wtVsRetSet(1).FishParameters, wtVsRetSet(4).FishParameters];[wtVsRetSet(1).BoolsNonNaN, wtVsRetSet(4).BoolsNonNaN];[wtVsRetSet(1).FishType(1, :), wtVsRetSet(4).FishType(1, :)]];
dayFourWTVsRet(:, [wtVsRetSet(1).FishType(2, :), wtVsRetSet(4).FishType(2, :)]) = [];
dayFourWTVsRet(:, ~dayFourWTVsRet(7,:)) = [];
dayFourWTVsRet(7,:) = [];
dayFourWT = dayFourWTVsRet(:, logical(dayFourWTVsRet(7,:)));
dayFourRet = dayFourWTVsRet(:, ~logical(dayFourWTVsRet(7,:)));
dataSizeArrays(1,1) = length(dayFourWT);
dataSizeArrays(2,1) = length(dayFourWT);

dayFiveWTVsRet = [[wtVsRetSet(2).FishParameters, wtVsRetSet(5).FishParameters];[wtVsRetSet(2).BoolsNonNaN, wtVsRetSet(5).BoolsNonNaN];[wtVsRetSet(2).FishType(1, :), wtVsRetSet(5).FishType(1, :)]];
dayFiveWTVsRet(:, [wtVsRetSet(2).FishType(2, :), wtVsRetSet(5).FishType(2, :)]) = [];
dayFiveWTVsRet(:, ~dayFiveWTVsRet(7,:)) = [];
dayFiveWTVsRet(7,:) = [];
dayFiveWT = dayFiveWTVsRet(:, logical(dayFiveWTVsRet(7,:)));
dayFiveRet = dayFiveWTVsRet(:, ~logical(dayFiveWTVsRet(7,:)));
dataSizeArrays(1,2) = length(dayFiveWT);
dataSizeArrays(2,2) = length(dayFiveRet);

daySixWTVsRet = [[wtVsRetSet(3).FishParameters, wtVsRetSet(6).FishParameters];[wtVsRetSet(3).BoolsNonNaN, wtVsRetSet(6).BoolsNonNaN];[wtVsRetSet(3).FishType(1, :), wtVsRetSet(6).FishType(1, :)]];
daySixWTVsRet(:, [wtVsRetSet(3).FishType(2, :), wtVsRetSet(6).FishType(2, :)]) = [];
daySixWTVsRet(:, ~daySixWTVsRet(7,:)) = [];
daySixWTVsRet(7,:) = [];
daySixWT = daySixWTVsRet(:, logical(daySixWTVsRet(7,:)));
daySixRet = daySixWTVsRet(:, ~logical(daySixWTVsRet(7,:)));
dataSizeArrays(1,3) = length(daySixWT);
dataSizeArrays(2,3) = length(daySixRet);

dayFourFedVsUnfed = [[unfedVsFedSet(1).FishParameters, unfedVsFedSet(4).FishParameters];[unfedVsFedSet(1).BoolsNonNaN, unfedVsFedSet(4).BoolsNonNaN];[unfedVsFedSet(1).FishType(1, :), unfedVsFedSet(4).FishType(1, :)]];
dayFourFedVsUnfed(:, [unfedVsFedSet(1).FishType(3, :), unfedVsFedSet(4).FishType(3, :)]) = [];
dayFourFedVsUnfed(:, ~dayFourFedVsUnfed(7,:)) = [];
dayFourFedVsUnfed(7,:) = [];
dayFourUnfed = dayFourFedVsUnfed(:, logical(dayFourFedVsUnfed(7,:)));
dayFourFed = dayFourFedVsUnfed(:, ~logical(dayFourFedVsUnfed(7,:)));
dataSizeArrays(1,4) = length(dayFourFed);
dataSizeArrays(2,4) = length(dayFourUnfed);

dayFiveFedVsUnfed = [[unfedVsFedSet(2).FishParameters, unfedVsFedSet(5).FishParameters];[unfedVsFedSet(2).BoolsNonNaN, unfedVsFedSet(5).BoolsNonNaN];[unfedVsFedSet(2).FishType(1, :), unfedVsFedSet(5).FishType(1, :)]];
dayFiveFedVsUnfed(:, [unfedVsFedSet(2).FishType(3, :), unfedVsFedSet(5).FishType(3, :)]) = [];
dayFiveFedVsUnfed(:, ~dayFiveFedVsUnfed(7,:)) = [];
dayFiveFedVsUnfed(7,:) = [];
dayFiveUnfed = dayFiveFedVsUnfed(:, logical(dayFiveFedVsUnfed(7,:)));
dayFiveFed = dayFiveFedVsUnfed(:, ~logical(dayFiveFedVsUnfed(7,:)));
dataSizeArrays(1,5) = length(dayFiveFed);
dataSizeArrays(2,5) = length(dayFiveUnfed);

daySixFedVsUnfed = [[unfedVsFedSet(3).FishParameters, unfedVsFedSet(6).FishParameters];[unfedVsFedSet(3).BoolsNonNaN, unfedVsFedSet(6).BoolsNonNaN];[unfedVsFedSet(3).FishType(1, :), unfedVsFedSet(6).FishType(1, :)]];
daySixFedVsUnfed(:, [unfedVsFedSet(3).FishType(3, :), unfedVsFedSet(6).FishType(3, :)]) = [];
daySixFedVsUnfed(:, ~daySixFedVsUnfed(7,:)) = [];
daySixFedVsUnfed(7,:) = [];
daySixUnfed = daySixFedVsUnfed(:, logical(daySixFedVsUnfed(7,:)));
daySixFed = daySixFedVsUnfed(:, ~logical(daySixFedVsUnfed(7,:)));
dataSizeArrays(1,6) = length(daySixFed);
dataSizeArrays(2,6) = length(daySixUnfed);

% Reshape the arrays to match one another
% WT vs Ret
maxNumFishOfAnyType = max(dataSizeArrays(:));
prevArrayLength = length(dayFourWT);
if(prevArrayLength < maxNumFishOfAnyType)
    dayFourWT = padarray(dayFourWT, [0, maxNumFishOfAnyType - prevArrayLength], 'post');
    dayFourWT(:, (prevArrayLength + 1):end) = NaN;
end
prevArrayLength = length(dayFiveWT);
if(prevArrayLength < maxNumFishOfAnyType)
    dayFiveWT = padarray(dayFiveWT, [0, maxNumFishOfAnyType - prevArrayLength], 'post');
    dayFiveWT(:, (prevArrayLength + 1):end) = NaN;
end
prevArrayLength = length(daySixWT);
if(prevArrayLength < maxNumFishOfAnyType)
    daySixWT = padarray(daySixWT, [0, maxNumFishOfAnyType - prevArrayLength], 'post');
    daySixWT(:, (prevArrayLength + 1):end) = NaN;
end
prevArrayLength = length(dayFourRet);
if(prevArrayLength < maxNumFishOfAnyType)
    dayFourRet = padarray(dayFourRet, [0, maxNumFishOfAnyType - prevArrayLength], 'post');
    dayFourRet(:, (prevArrayLength + 1):end) = NaN;
end
prevArrayLength = length(dayFiveRet);
if(prevArrayLength < maxNumFishOfAnyType)
    dayFiveRet = padarray(dayFiveRet, [0, maxNumFishOfAnyType - prevArrayLength], 'post');
    dayFiveRet(:, (prevArrayLength + 1):end) = NaN;
end
prevArrayLength = length(daySixRet);
if(prevArrayLength < maxNumFishOfAnyType)
    daySixRet = padarray(daySixRet, [0, maxNumFishOfAnyType - prevArrayLength], 'post');
    daySixRet(:, (prevArrayLength + 1):end) = NaN;
end

% Fed vs Unfed
prevArrayLength = length(dayFourUnfed);
if(prevArrayLength < maxNumFishOfAnyType)
    dayFourUnfed = padarray(dayFourUnfed, [0, maxNumFishOfAnyType - prevArrayLength], 'post');
    dayFourUnfed(:, (prevArrayLength + 1):end) = NaN;
end
prevArrayLength = length(dayFiveUnfed);
if(prevArrayLength < maxNumFishOfAnyType)
    dayFiveUnfed = padarray(dayFiveUnfed, [0, maxNumFishOfAnyType - prevArrayLength], 'post');
    dayFiveUnfed(:, (prevArrayLength + 1):end) = NaN;
end
prevArrayLength = length(daySixUnfed);
if(prevArrayLength < maxNumFishOfAnyType)
    daySixUnfed = padarray(daySixUnfed, [0, maxNumFishOfAnyType - prevArrayLength], 'post');
    daySixUnfed(:, (prevArrayLength + 1):end) = NaN;
end
prevArrayLength = length(dayFourFed);
if(prevArrayLength < maxNumFishOfAnyType)
    dayFourFed = padarray(dayFourFed, [0, maxNumFishOfAnyType - prevArrayLength], 'post');
    dayFourFed(:, (prevArrayLength + 1):end) = NaN;
end
prevArrayLength = length(dayFiveFed);
if(prevArrayLength < maxNumFishOfAnyType)
    dayFiveFed = padarray(dayFiveFed, [0, maxNumFishOfAnyType - prevArrayLength], 'post');
    dayFiveFed(:, (prevArrayLength + 1):end) = NaN;
end
prevArrayLength = length(daySixFed);
if(prevArrayLength < maxNumFishOfAnyType)
    daySixFed = padarray(daySixFed, [0, maxNumFishOfAnyType - prevArrayLength], 'post');
    daySixFed(:, (prevArrayLength + 1):end) = NaN;
end

%% Statistical tests
%
% For this part to work, you must temporarily remove
% /Users/Ampere/Documents/MATLAB/code/Lab/External_Lab_Programs/PIVlab/nanmean.m
% and
% /Users/Ampere/Documents/MATLAB/code/Lab/External_Lab_Programs/PIVlab/nanstd.m
% from your library

dayFourWT(4,:) = 1./dayFourWT(4,:);
dayFourRet(4,:) = 1./dayFourRet(4,:);
dayFiveWT(4,:) = 1./dayFiveWT(4,:);
dayFiveRet(4,:) = 1./dayFiveRet(4,:);
daySixWT(4,:) = 1./daySixWT(4,:);
daySixRet(4,:) = 1./daySixRet(4,:);
dayFourUnfed(4,:) = 1./dayFourUnfed(4,:);
dayFourFed(4,:) = 1./dayFourFed(4,:);
dayFiveUnfed(4,:) = 1./dayFiveUnfed(4,:);
dayFiveFed(4,:) = 1./dayFiveFed(4,:);
daySixUnfed(4,:) = 1./daySixUnfed(4,:);
daySixFed(4,:) = 1./daySixFed(4,:);

for i=2:6
    [ttTestPass, p] = ttest2(dayFourWT(i,:), dayFourRet(i,:));
    if(ttTestPass)
        sprintf('Day 4 of Wt vs Ret (for parameter %u) is significant with a p value of %0.3f', i, p)
    end
    [ttTestPass, p] = ttest2(dayFiveWT(i,:), dayFiveRet(i,:));
    if(ttTestPass)
        sprintf('Day 5 of Wt vs Ret (for parameter %u) is significant with a p value of %0.3f', i, p)
    end
    [ttTestPass, p] = ttest2(daySixWT(i,:), daySixRet(i,:));
    if(ttTestPass)
        sprintf('Day 6 of Wt vs Ret (for parameter %u) is significant with a p value of %0.3f', i, p)
    end
    [ttTestPass, p] = ttest2(dayFourUnfed(i,:), dayFourFed(i,:));
    if(ttTestPass)
        sprintf('Day 4 of Unfed vs Fed (for parameter %u) is significant with a p value of %0.3f', i, p)
    end
    [ttTestPass, p] = ttest2(dayFiveUnfed(i,:), dayFiveFed(i,:));
    if(ttTestPass)
        sprintf('Day 5 of Unfed vs Fed (for parameter %u) is significant with a p value of %0.3f', i, p)
    end
    [ttTestPass, p] = ttest2(daySixUnfed(i,:), daySixFed(i,:));
    if(ttTestPass)
        sprintf('Day 6 of Unfed vs Fed (for parameter %u) is significant with a p value of %0.3f', i, p)
    end
end

dayFourWT(4,:) = 1./dayFourWT(4,:);
dayFourRet(4,:) = 1./dayFourRet(4,:);
dayFiveWT(4,:) = 1./dayFiveWT(4,:);
dayFiveRet(4,:) = 1./dayFiveRet(4,:);
daySixWT(4,:) = 1./daySixWT(4,:);
daySixRet(4,:) = 1./daySixRet(4,:);
dayFourUnfed(4,:) = 1./dayFourUnfed(4,:);
dayFourFed(4,:) = 1./dayFourFed(4,:);
dayFiveUnfed(4,:) = 1./dayFiveUnfed(4,:);
dayFiveFed(4,:) = 1./dayFourFed(4,:);
daySixUnfed(4,:) = 1./daySixUnfed(4,:);
daySixFed(4,:) = 1./dayFourFed(4,:);

%% Plot
groupee = { 'WT', 'Ret', 'WT', 'Ret', 'WT', 'Ret' };
for i=2:6
    figure;
    if(i == 2)
        fishOrderedByDay = micronsPerPixel/fps*[dayFourWT(i,:); dayFourRet(i,:);...
            dayFiveWT(i,:); dayFiveRet(i,:);...
            daySixWT(i,:); daySixRet(i,:)];
    elseif(i == 4)
        fishOrderedByDay = 1./[dayFourWT(i,:); dayFourRet(i,:);...
            dayFiveWT(i,:); dayFiveRet(i,:);...
            daySixWT(i,:); daySixRet(i,:)];
    else
        fishOrderedByDay = [dayFourWT(i,:); dayFourRet(i,:);...
            dayFiveWT(i,:); dayFiveRet(i,:);...
            daySixWT(i,:); daySixRet(i,:)];
    end
    colorWheelO = colorWheelBorder( [ 1, 3 ], : );
    colorWheelF = colorWheelFill( [ 1, 3 ], : );
    scatterBox( fishOrderedByDay', {groupee, colorWheelO, colorWheelF});
    if(i == 2)
        ylim([ampYMin, ampYMax]);
    elseif(i == 3)
        ylim([freqYMin, freqYMax]);
    end
    h = gcf;
    set(findall(h,'type','axes'),'fontsize',20, 'FontName',...
    'Arial', 'TickDir', 'out','box','off');
end

groupee = { 'Unfed', 'Fed', 'Unfed', 'Fed', 'Unfed', 'Fed' };
for i=2:6
    figure;
    if(i == 2)
        fishOrderedByDay = micronsPerPixel/fps*[dayFourUnfed(i,:); dayFourFed(i,:);...
            dayFiveUnfed(i,:); dayFiveFed(i,:);...
            daySixUnfed(i,:); daySixFed(i,:)];
    elseif(i == 4)
        fishOrderedByDay = 1./[dayFourUnfed(i,:); dayFourFed(i,:);...
            dayFiveUnfed(i,:); dayFiveFed(i,:);...
            daySixUnfed(i,:); daySixFed(i,:)];
    else
        fishOrderedByDay = [dayFourUnfed(i,:); dayFourFed(i,:);...
            dayFiveUnfed(i,:); dayFiveFed(i,:);...
            daySixUnfed(i,:); daySixFed(i,:)];
    end
    colorWheelO = colorWheelBorder( [ 1, 2 ], : );
    colorWheelF = colorWheelFill( [ 1, 2 ], : );
    scatterBox( fishOrderedByDay', {groupee, colorWheelO, colorWheelF});
    if(i == 2)
        ylim([ampYMin, ampYMax]);
    elseif(i == 3)
        ylim([freqYMin, freqYMax]);
    end
    h = gcf;
    set(findall(h,'type','axes'),'fontsize',20, 'FontName', 'Arial',...
        'TickDir', 'out','box','off');
end



















%% Alternate plotting