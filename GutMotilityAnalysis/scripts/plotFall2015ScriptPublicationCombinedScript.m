% plotFall2015ScriptPublicationCombined

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
set(0,'defaultAxesFontName', 'Arial') % Default is Helvetica

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

fishOrderedByDay = micronsPerPixel/fps*[dayFourWT(i,:); dayFourRet(i,:);...
            dayFiveWT(i,:); dayFiveRet(i,:);...
            daySixWT(i,:); daySixRet(i,:)];

%% Plot
% Initialize boxplot variables
mainFigureDirectory = '/Users/altaen/Documents/Research/Papers/Gut Motility Analysis/Figures/';
feedingDir = 'Figure3Feeding/';
retDir = 'Figure4Ret/';
numPerGroup = 2;
numBoxes = 6;
numGroups = numBoxes/numPerGroup;
x = 1:( numBoxes + numGroups - 1 );
% Way of adding space: delete every numGroups spacing between x's
for i=1:numGroups - 1
    x( i*( numPerGroup + 1 ) ) = NaN;
end
x( isnan( x ) ) = [];
boxColorWheel = [ 0, 0, 0 ];

% Initialize bounds
ampYMin = 0;
ampYMax = 2*micronsPerPixel*900/1500;
freqYMin = 1.2;
freqYMax = 3.3;

% % Wt vs Ret
for i = 2:6
    
    % Make boxplot
    figure;
    colorWheelO = colorWheelBorder( [ 1, 3 ], : );
    colorWheelF = colorWheelFill( [ 1, 3 ], : );
    markerSize = 45;
    y = [dayFourWT(i,:); dayFourRet(i,:);...
            dayFiveWT(i,:); dayFiveRet(i,:);...
            daySixWT(i,:); daySixRet(i,:)];
    if(i==2)
        y = micronsPerPixel/fps*y;
%     elseif(i==3)
%         y=60*y;
    elseif(i==4)
        y=1./y;
    end
    y = y';
    boxplot( y, 'positions', x, 'labels', { '', '', '', '', '', '' }, 'colors', boxColorWheel, 'outliersize', 1 );
    
    
    % Make Scatterplot
    for l=1:2
        
        el = 3 - l;
        % Remake all of the variables...
        maxElements = 0;
        
        dayFourWT2 = wtVsRetSet(1 + 3*(el-1)).FishParameters(i,(wtVsRetSet(1 + 3*(el-1)).FishType(1,:) & wtVsRetSet(1 + 3*(el-1)).BoolsNonNaN));
        if(size(dayFourWT2,2) > maxElements)
            maxElements = size(dayFourWT2,2);
        end
        dayFiveWT2 = wtVsRetSet(2 + 3*(el-1)).FishParameters(i,(wtVsRetSet(2 + 3*(el-1)).FishType(1,:) & wtVsRetSet(2 + 3*(el-1)).BoolsNonNaN));
        if(size(dayFiveWT2,2) > maxElements)
            maxElements = size(dayFiveWT2,2);
        end
        daySixWT2 = wtVsRetSet(3 + 3*(el-1)).FishParameters(i,(wtVsRetSet(3 + 3*(el-1)).FishType(1,:) & wtVsRetSet(3 + 3*(el-1)).BoolsNonNaN));
        if(size(daySixWT2,2) > maxElements)
            maxElements = size(daySixWT2,2);
        end
        
        dayFourRet2 = wtVsRetSet(1 + 3*(el-1)).FishParameters(i,(wtVsRetSet(1 + 3*(el-1)).FishType(3,:) & wtVsRetSet(1 + 3*(el-1)).BoolsNonNaN));
        if(size(dayFourRet2,2) > maxElements)
            maxElements = size(dayFourRet2,2);
        end
        dayFiveRet2 = wtVsRetSet(2 + 3*(el-1)).FishParameters(i,(wtVsRetSet(2 + 3*(el-1)).FishType(3,:) & wtVsRetSet(2 + 3*(el-1)).BoolsNonNaN));
        if(size(dayFiveRet2,2) > maxElements)
            maxElements = size(dayFiveRet2,2);
        end
        daySixRet2 = wtVsRetSet(3 + 3*(el-1)).FishParameters(i,(wtVsRetSet(3 + 3*(el-1)).FishType(3,:) & wtVsRetSet(3 + 3*(el-1)).BoolsNonNaN));
        if(size(daySixRet2,2) > maxElements)
            maxElements = size(daySixRet2,2);
        end
        
        curSize = size(dayFourWT2,2);
        if(curSize < maxElements)
            dayFourWT2 = [dayFourWT2, nan(1,maxElements-curSize)];
        end
        curSize = size(dayFiveWT2,2);
        if(curSize < maxElements)
            dayFiveWT2 = [dayFiveWT2, nan(1,maxElements-curSize)];
        end
        curSize = size(daySixWT2,2);
        if(curSize < maxElements)
            daySixWT2 = [daySixWT2, nan(1,maxElements-curSize)];
        end
        
        curSize = size(dayFourRet2,2);
        if(curSize < maxElements)
            dayFourRet2 = [dayFourRet2, nan(1,maxElements-curSize)];
        end
        curSize = size(dayFiveRet2,2);
        if(curSize < maxElements)
            dayFiveRet2 = [dayFiveRet2, nan(1,maxElements-curSize)];
        end
        curSize = size(daySixRet2,2);
        if(curSize < maxElements)
            daySixRet2 = [daySixRet2, nan(1,maxElements-curSize)];
        end
        
        % Define y
        y = [dayFourWT2; dayFourRet2;...
                dayFiveWT2; dayFiveRet2;...
                daySixWT2; daySixRet2];
        if(i==2)
            y = micronsPerPixel/fps*y;
%         elseif(i==3)
%             y=60*y;
        elseif(i==4)
            y=1./y;
        end
        y=y';
        
        % l loops through the replicate studies
        if(el==1)
            curMarker = 'o';
        else
            curMarker = 'd';
        end
        
        numPoints = size( y, 1 ); % If different sizes, just pad with NaNs
        maxDX = 0.2; % Don't go higher than 0.5
        xSpacing = linspace(-maxDX,maxDX,numPoints);
        scatterX = zeros( numBoxes, numPoints );
        for j=1:numBoxes
            tempRandPerm = randperm( numPoints );
            scatterX( j, : ) = xSpacing( tempRandPerm );
        end
        hold on;
        for j=1:numGroups
            for k=1:numPerGroup
                faceColor = colorWheelF( k, : );
                edgeColor = colorWheelO( k, : );
                if(el==2)
                    faceColor = faceColor + 3*(1 - faceColor)/4;
                    edgeColor = edgeColor + (1 - edgeColor)/2;
                end
                scatter( x( numPerGroup*( j - 1 ) + k ) + scatterX( numPerGroup*( j - 1 ) + k , : ), y( :, numPerGroup*( j - 1 ) + k  ), markerSize, 'Marker', curMarker, 'MarkerEdgeColor', edgeColor, 'MarkerFaceColor', faceColor );
            end
        end
    end
    
    hold off;
    h = gcf;
    set(findall(h,'type','axes'),'fontsize',20, 'FontName',...
        'Arial', 'TickDir', 'out','box','off');
    set(h, 'Units', 'Inches');
    pos = get(h, 'Position');
    set(h, 'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)]);
    if(i==2)
        ylim([ampYMin, ampYMax]);
        curfileName = 'Amp.pdf';
    elseif(i==3)
        ylim([freqYMin, freqYMax]);
        curfileName = 'Freq.pdf';
    elseif(i==4)
        curfileName = 'InvWaveSpeed.pdf';
    elseif(i==5)
        curfileName = 'WaveVariance.pdf';
    elseif(i==6)
        curfileName = 'WaveDuration.pdf';
    end
    print(h, strcat(mainFigureDirectory, retDir, curfileName), '-dpdf', '-r0'); % Fileseps already included in name

end

% Unfed vs Fed
for i = 2:6
    
    % Make boxplot
    figure;
    colorWheelO = colorWheelBorder( [ 1, 2 ], : );
    colorWheelF = colorWheelFill( [ 1, 2 ], : );
    markerSize = 45;
    y = [dayFourUnfed(i,:); dayFourFed(i,:);...
            dayFiveUnfed(i,:); dayFiveFed(i,:);...
            daySixUnfed(i,:); daySixFed(i,:)];
    if(i==2)
        y = micronsPerPixel/fps*y;
%     elseif(i==3)
%         y=60*y;
    elseif(i==4)
        y=1./y;
    end
    y = y';
%    boxplot( y, 'positions', x, 'labels', { 'Unfed', 'Fed', 'Unfed', 'Fed', 'Unfed', 'Fed' }, 'colors', boxColorWheel, 'outliersize', 1 );
boxplot( y, 'positions', x, 'labels', { '', '', '', '', '', '' }, 'colors', boxColorWheel, 'outliersize', 1 );
    
    
    % Make Scatterplot
    for l=1:2
        
        el = 3 - l;
        % Remake all of the variables...
        maxElements = 0;
        
        dayFourUnfed2 = unfedVsFedSet(1 + 3*(el-1)).FishParameters(i,(unfedVsFedSet(1 + 3*(el-1)).FishType(1,:) & unfedVsFedSet(1 + 3*(el-1)).BoolsNonNaN));
        if(size(dayFourUnfed2,2) > maxElements)
            maxElements = size(dayFourUnfed2,2);
        end
        dayFiveUnfed2 = unfedVsFedSet(2 + 3*(el-1)).FishParameters(i,(unfedVsFedSet(2 + 3*(el-1)).FishType(1,:) & unfedVsFedSet(2 + 3*(el-1)).BoolsNonNaN));
        if(size(dayFiveUnfed2,2) > maxElements)
            maxElements = size(dayFiveUnfed2,2);
        end
        daySixUnfed2 = unfedVsFedSet(3 + 3*(el-1)).FishParameters(i,(unfedVsFedSet(3 + 3*(el-1)).FishType(1,:) & unfedVsFedSet(3 + 3*(el-1)).BoolsNonNaN));
        if(size(daySixUnfed2,2) > maxElements)
            maxElements = size(daySixUnfed2,2);
        end
        
        dayFourFed2 = unfedVsFedSet(1 + 3*(el-1)).FishParameters(i,(unfedVsFedSet(1 + 3*(el-1)).FishType(2,:) & unfedVsFedSet(1 + 3*(el-1)).BoolsNonNaN));
        if(size(dayFourFed2,2) > maxElements)
            maxElements = size(dayFourFed2,2);
        end
        dayFiveFed2 = unfedVsFedSet(2 + 3*(el-1)).FishParameters(i,(unfedVsFedSet(2 + 3*(el-1)).FishType(2,:) & unfedVsFedSet(2 + 3*(el-1)).BoolsNonNaN));
        if(size(dayFiveFed2,2) > maxElements)
            maxElements = size(dayFiveFed2,2);
        end
        daySixFed2 = unfedVsFedSet(3 + 3*(el-1)).FishParameters(i,(unfedVsFedSet(3 + 3*(el-1)).FishType(2,:) & unfedVsFedSet(3 + 3*(el-1)).BoolsNonNaN));
        if(size(daySixFed2,2) > maxElements)
            maxElements = size(daySixFed2,2);
        end
        
        curSize = size(dayFourUnfed2,2);
        if(curSize < maxElements)
            dayFourUnfed2 = [dayFourUnfed2, nan(1,maxElements-curSize)];
        end
        curSize = size(dayFiveUnfed2,2);
        if(curSize < maxElements)
            dayFiveUnfed2 = [dayFiveUnfed2, nan(1,maxElements-curSize)];
        end
        curSize = size(daySixUnfed2,2);
        if(curSize < maxElements)
            daySixUnfed2 = [daySixUnfed2, nan(1,maxElements-curSize)];
        end
        
        curSize = size(dayFourFed2,2);
        if(curSize < maxElements)
            dayFourFed2 = [dayFourFed2, nan(1,maxElements-curSize)];
        end
        curSize = size(dayFiveFed2,2);
        if(curSize < maxElements)
            dayFiveFed2 = [dayFiveFed2, nan(1,maxElements-curSize)];
        end
        curSize = size(daySixFed2,2);
        if(curSize < maxElements)
            daySixFed2 = [daySixFed2, nan(1,maxElements-curSize)];
        end
        
        % Define y
        y = [dayFourUnfed2; dayFourFed2;...
                dayFiveUnfed2; dayFiveFed2;...
                daySixUnfed2; daySixFed2];
        if(i==2)
            y = micronsPerPixel/fps*y;
%         elseif(i==3)
%             y=60*y;
        elseif(i==4)
            y=1./y;
        end
        y=y';
        
        % l loops through the replicate studies
        if(el==1)
            curMarker = 'o';
        else
            curMarker = 'd';
        end
        
        numPoints = size( y, 1 ); % If different sizes, just pad with NaNs
        maxDX = 0.2; % Don't go higher than 0.5
        xSpacing = linspace(-maxDX,maxDX,numPoints);
        scatterX = zeros( numBoxes, numPoints );
        for j=1:numBoxes
            tempRandPerm = randperm( numPoints );
            scatterX( j, : ) = xSpacing( tempRandPerm );
        end
        hold on;
        for j=1:numGroups
            for k=1:numPerGroup
                faceColor = colorWheelF( k, : );
                edgeColor = colorWheelO( k, : );
                if(el==2)
                    faceColor = faceColor + 3*(1 - faceColor)/4;
                    edgeColor = edgeColor + (1 - edgeColor)/2;
                end
                scatter( x( numPerGroup*( j - 1 ) + k ) + scatterX( numPerGroup*( j - 1 ) + k , : ), y( :, numPerGroup*( j - 1 ) + k  ), markerSize, 'Marker', curMarker, 'MarkerEdgeColor', edgeColor, 'MarkerFaceColor', faceColor );
            end
        end
    end
    
    hold off;
    h = gcf;
    set(findall(h,'type','axes'),'fontsize',20, 'FontName',...
        'Arial', 'TickDir', 'out','box','off');
    set(h, 'Units', 'Inches');
    pos = get(h, 'Position');
    set(h, 'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)]);
    if(i==2)
        ylim([ampYMin, ampYMax]);
        curfileName = 'Amp.pdf';
    elseif(i==3)
        ylim([freqYMin, freqYMax]);
        curfileName = 'Freq.pdf';
    elseif(i==4)
        curfileName = 'InvWaveSpeed.pdf';
    elseif(i==5)
        curfileName = 'WaveVariance.pdf';
    elseif(i==6)
        curfileName = 'WaveDuration.pdf';
    end
    print(h, strcat(mainFigureDirectory, feedingDir, curfileName), '-dpdf', '-r0'); % Fileseps already included in name

end