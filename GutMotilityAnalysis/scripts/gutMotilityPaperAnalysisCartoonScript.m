% Plots a cartoon of how the analysis works

% User defined variables
fundamentalFreq = 2.1/3; % Units of per minute
amplitudeVector = 1.8*[0.1, 0.25, 2.2, 0.7, 0.6, 0.1, 0, 0.2, 0.4, 0.05, 0]; % Make last index 0 for ease of later operations
numSamplesPerSine = 1000;
deltaOffsetBetweenSines = 0.25;
secondPlotYReduction = 2/3;
mainFigureDirectory = '/Users/Ampere/Documents/Research/Papers/Gut Motility Analysis/Figures/';
overDir = 'Figure1Overview/';

% Derived variables
nSines = size(amplitudeVector, 2) - 1; % Minus 1 for the additional zero in amplitudeVector
allModes = zeros(nSines, numSamplesPerSine);
runningSum = amplitudeVector(1);
[maxVal, maxLoc] = max(amplitudeVector);
tAxis = linspace(0, 1/fundamentalFreq, numSamplesPerSine);

% Generate waves
for i = 1:nSines
    allModes(i, :) = amplitudeVector(i)*sin(2*3.141592*i*(1:numSamplesPerSine)/numSamplesPerSine);
end
fullWave = sum(allModes);

% Build composite plot
h = figure;
hold on;
for i = 1:nSines
    %runningSum = 0;
    inverseIndex = nSines - i + 1;
    runningSum = runningSum + amplitudeVector(inverseIndex + 1) + amplitudeVector(inverseIndex) + deltaOffsetBetweenSines;
    if(inverseIndex==maxLoc)
        plot(tAxis, runningSum + allModes(inverseIndex,:), 'r');
        plot(tAxis, zeros(1,numSamplesPerSine) + runningSum, 'k--');
        plot(tAxis, zeros(1,numSamplesPerSine) + runningSum + amplitudeVector(inverseIndex), 'k--');
        midLine = runningSum;
    else
        plot(tAxis, runningSum + allModes(inverseIndex,:), 'Color', [0.1, 0.1, 0.1] + (inverseIndex-1)*[0.6, 0.6, 0.6]/nSines);
    end
end
hold off;
yVals = ylim;
set(findall(h,'type','axes'),'fontsize',20, 'FontName',...
        'Arial', 'TickDir', 'out','box','off');
set(h, 'Units', 'Inches');
pos = get(h, 'Position');
set(h, 'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)]);
curfileName = 'Sines.pdf';
print(h, strcat(mainFigureDirectory, overDir, curfileName), '-dpdf', '-r0'); % Fileseps already included in name

g = figure;
hold on;
plot(tAxis, fullWave + midLine, 'r');
plot(tAxis, zeros(1,numSamplesPerSine) + midLine, 'k--');
plot(tAxis, zeros(1,numSamplesPerSine) + amplitudeVector(maxLoc) + midLine, 'k--');
ylim([(1-secondPlotYReduction)*yVals(2) + yVals(1), yVals(2)]);
hold off;
set(findall(g,'type','axes'),'fontsize',20, 'FontName',...
        'Arial', 'TickDir', 'out','box','off');
set(g, 'Units', 'Inches');
pos = get(g, 'Position');
set(g, 'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)]);
set(g, 'Position', [pos(1), pos(2), pos(3), secondPlotYReduction*pos(4)]);
curfileName = 'FullWaveform.pdf';
print(g, strcat(mainFigureDirectory, overDir, curfileName), '-dpdf', '-r0'); % Fileseps already included in name

h = figure;
hold on;
fAxis = fundamentalFreq:fundamentalFreq:nSines*fundamentalFreq;
plot(fAxis, amplitudeVector(1:end-1), 'r');
ylim([0, maxVal]);
xlim([fundamentalFreq, nSines*fundamentalFreq]);
set(findall(h,'type','axes'),'fontsize',20, 'FontName',...
        'Arial', 'TickDir', 'out','box','off');
set(h, 'Units', 'Inches');
pos = get(h, 'Position');
set(h, 'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)]);
set(h, 'Position', [pos(1), pos(2), pos(3), (1-secondPlotYReduction)*pos(4)]);
curfileName = 'FourierPlot.pdf';
print(h, strcat(mainFigureDirectory, overDir, curfileName), '-dpdf', '-r0'); % Fileseps already included in name