% Script for plotting the Acetylecholine data

%% Initialize variables
colorWheelO = [ [0, 0, 0.4]; [0.4, 0.1, 0]];
colorWheelF = [[0.2 0.3 0.8]; [0.95 0.7 0.3]];
dataSizeArrays = zeros(2,2); % First index is (1 = control, 2 = experiment), second index is which experiment
fps = 5;
ampYMin = 0;
ampYMax = 60;
freqYMin = 1.2;
freqYMax = 3.3;
micronsPerPixel = 0.325;
set(0,'defaultAxesFontName', 'Arial') % Default is Helvetica

contFish = acetylcholineData(acetylcholineData(:,2)==1,:);
aceFish = acetylcholineData(acetylcholineData(:,2)==2,:);

%% Plot
% Initialize boxplot variables
mainFigureDirectory = '/Users/Ampere/Documents/Research/Papers/Gut Motility Analysis/Figures/';
aceDir = 'Figure2Acetylcholine/';
numPerGroup = 2;
numBoxes = 2;
numGroups = numBoxes/numPerGroup;
x = 1:( numBoxes + numGroups - 1 );
% Way of adding space: delete every numGroups spacing between x's
for i=1:numGroups - 1
    x( i*( numPerGroup + 1 ) ) = NaN;
end
x( isnan( x ) ) = [];
boxColorWheel = [ 0, 0, 0 ];

% Make boxplot
for i = 5:8
    
    figure;
    markerSize = 45;
    y = [contFish(:,i), aceFish(:,i)];
    if(i==6)
        y = micronsPerPixel/fps*y;
    elseif(i==8)
        y=1./y;
    end
    
    boxplot( y, 'positions', x, 'labels', { '', ''}, 'colors', boxColorWheel, 'outliersize', 1 );
    
    % Make Scatterplot
    for l=1:2
        
        curCont = acetylcholineData(acetylcholineData(:,1)==l & acetylcholineData(:,2)==1,:);
        curAce = acetylcholineData(acetylcholineData(:,1)==l & acetylcholineData(:,2)==2,:);
        y = [curCont(:,i), curAce(:,i)];
        if(i==6)
            y = micronsPerPixel/fps*y;
        elseif(i==8)
            y=1./y;
        end
        
        % l loops through the replicate studies
        if(l==1)
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
                if(l==2)
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
    set(h, 'Position', [pos(1), pos(2), pos(3)/3, pos(4)]);
    
    if(i==6)
        ylim([ampYMin, ampYMax]);
        curfileName = 'Amp.pdf';
    elseif(i==5)
        ylim([freqYMin, freqYMax]);
        curfileName = 'Freq.pdf';
    elseif(i==8)
        curfileName = 'InvWaveSpeed.pdf';
    elseif(i==7)
        curfileName = 'WaveDuration.pdf';
    end
    print(h, strcat(mainFigureDirectory, aceDir, curfileName), '-dpdf', '-r0'); % Fileseps already included in name
    
end