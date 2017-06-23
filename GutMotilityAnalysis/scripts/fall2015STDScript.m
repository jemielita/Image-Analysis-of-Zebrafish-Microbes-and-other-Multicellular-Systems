%% Script for plotting the std inset of graphs

retStd = zeros(2, 3, 5); % first index is experiment, second index is day, third is parameter (1=amp, 2=freq)
wtStd = zeros(2, 3, 5);
unfedStd = zeros(2, 3, 5);
fedStd = zeros(2, 3, 5);
fps = 5;
micronsPerPixel = 0.325;

% Ret
for i=1:3
    curData = fall2015Data(i).FishParameters(2:6, :);
    useFish = fall2015Data(i).BoolsNaN & fall2015Data(i).FishType(3, :);
    curData = curData(:, useFish);
    retStd(1, i, :) = std(curData, 0, 2);
end
for i=1:3
    curData = fall2015Data(3+i).FishParameters(2:6, :);
    useFish = fall2015Data(3+i).BoolsNaN & fall2015Data(3+i).FishType(3, :);
    curData = curData(:, useFish);
    retStd(2, i, :) = std(curData, 0, 2);
end

% WT
for i=1:3
    curData = fall2015Data(i).FishParameters(2:6, :);
    useFish = fall2015Data(i).BoolsNaN & fall2015Data(i).FishType(1, :);
    curData = curData(:, useFish);
    wtStd(1, i, :) = std(curData, 0, 2);
end
for i=1:3
    curData = fall2015Data(3+i).FishParameters(2:6, :);
    useFish = fall2015Data(3+i).BoolsNaN & fall2015Data(3+i).FishType(1, :);
    curData = curData(:, useFish);
    wtStd(2, i, :) = std(curData, 0, 2);
end

% Unfed
for i=4:6
    curData = fall2015Data(i).FishParameters(2:6, :);
    useFish = fall2015Data(i).BoolsNaN & fall2015Data(i).FishType(1, :);
    curData = curData(:, useFish);
    unfedStd(1, i-3, :) = std(curData, 0, 2);
end
for i=4:6
    curData = fall2015Data(3+i).FishParameters(2:6, :);
    useFish = fall2015Data(3+i).BoolsNaN & fall2015Data(3+i).FishType(1, :);
    curData = curData(:, useFish);
    unfedStd(2, i-3, :) = std(curData, 0, 2);
end

% Fed
for i=4:6
    curData = fall2015Data(i).FishParameters(2:6, :);
    useFish = fall2015Data(i).BoolsNaN & fall2015Data(i).FishType(2, :);
    curData = curData(:, useFish);
    fedStd(1, i-3, :) = std(curData, 0, 2);
end
for i=4:6
    curData = fall2015Data(3+i).FishParameters(2:6, :);
    useFish = fall2015Data(3+i).BoolsNaN & fall2015Data(3+i).FishType(2, :);
    curData = curData(:, useFish);
    fedStd(2, i-3, :) = std(curData, 0, 2);
end

%% Plotting the data

% Variables
colorWheelBorder = [ [0, 0, 0.4]; [0, 0.3, 0]; [0.4, 0, 0] ];
colorWheelFill = [[0.2 0.3 0.8]; [0.2 0.9 0.2]; [0.9 0.3 0.1]];
mainFigureDirectory = '/Users/Ampere/Documents/Research/Papers/Gut Motility Analysis/Figures';
markerSize = 45;
yLimAmpRet = [0,12];
yLimFreqRet = [0, 0.42];
yLimAmpFeed = [0,42];
yLimFreqFeed = yLimFreqRet;

% STD ret amp
h = figure;
curPos = get(h, 'Position');
set(h, 'Position', [curPos(1), curPos(2), curPos(3)/3, curPos(4)/3]);
scatter(1:3, micronsPerPixel/fps*retStd(1,:,1), markerSize, 'Marker', 'o', 'MarkerEdgeColor', colorWheelBorder(3,:), 'MarkerFaceColor', colorWheelFill(3,:)); hold on;
scatter(1:3, micronsPerPixel/fps*wtStd(1,:,1), markerSize, 'Marker', 'o', 'MarkerEdgeColor', colorWheelBorder(1,:), 'MarkerFaceColor', colorWheelFill(1,:));
scatter(1:3, micronsPerPixel/fps*retStd(2,:,1), markerSize, 'Marker', 'd', 'MarkerEdgeColor', colorWheelBorder(3,:) + (1-colorWheelBorder(3,:))/2, 'MarkerFaceColor', colorWheelFill(3,:) + 3*(1-colorWheelFill(3,:))/4);
scatter(1:3, micronsPerPixel/fps*wtStd(2,:,1), markerSize, 'Marker', 'd', 'MarkerEdgeColor', colorWheelBorder(1,:) + (1-colorWheelBorder(1,:))/2, 'MarkerFaceColor', colorWheelFill(1,:) + 3*(1-colorWheelFill(1,:))/4);
set(findall(h,'type','axes'),'fontsize',20, 'FontName',...
    'Arial', 'TickDir', 'in','box','on', 'XTick', [1,2,3], 'XTickLabels',{'4dpf', '5dpf', '6dpf'});
xlim([0.85, 3.15]);
ylim(yLimAmpRet);
set(h, 'Units', 'Inches');
pos = get(h, 'Position');
set(h, 'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)]);
print(h, strcat(mainFigureDirectory, filesep, 'Figure4Ret', filesep, 'AmpSTD.pdf'), '-dpdf', '-r0');

% h = figure;
% curPos = get(h, 'Position');
% set(h, 'Position', [curPos(1), curPos(2), curPos(3)/3, curPos(4)/3]);
% scatter(1:3, retStd(2,:,1), markerSize, 'MarkerEdgeColor', colorWheelBorder(3,:), 'MarkerFaceColor', colorWheelFill(3,:)); hold on;
% scatter(1:3, wtStd(2,:,1), markerSize, 'MarkerEdgeColor', colorWheelBorder(1,:), 'MarkerFaceColor', colorWheelFill(1,:));
% set(findall(h,'type','axes'),'fontsize',20, 'FontName',...
%     'Arial', 'TickDir', 'in','box','on', 'XTick', [1,2,3], 'XTickLabels',{'4dpf', '5dpf', '6dpf'});
% xlim([0.85, 3.15]);
% ylim(yLimAmpRet);
% set(h, 'Units', 'Inches');
% pos = get(h, 'Position');
% set(h, 'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)]);
% print(h, strcat(mainFigureDirectory, filesep, 'Figure4Ret', filesep, 'Amp2STD.pdf'), '-dpdf', '-r0');

% STD ret freq
h = figure;
curPos = get(h, 'Position');
set(h, 'Position', [curPos(1), curPos(2), curPos(3)/3, curPos(4)/3]);
scatter(1:3, retStd(1,:,2), markerSize, 'Marker', 'o', 'MarkerEdgeColor', colorWheelBorder(3,:), 'MarkerFaceColor', colorWheelFill(3,:)); hold on;
scatter(1:3, wtStd(1,:,2), markerSize, 'Marker', 'o', 'MarkerEdgeColor', colorWheelBorder(1,:), 'MarkerFaceColor', colorWheelFill(1,:));
scatter(1:3, retStd(2,:,2), markerSize, 'Marker', 'd', 'MarkerEdgeColor', colorWheelBorder(3,:) + (1-colorWheelBorder(3,:))/2, 'MarkerFaceColor', colorWheelFill(3,:) + 3*(1-colorWheelFill(3,:))/4);
scatter(1:3, wtStd(2,:,2), markerSize, 'Marker', 'd', 'MarkerEdgeColor', colorWheelBorder(1,:) + (1-colorWheelBorder(1,:))/2, 'MarkerFaceColor', colorWheelFill(1,:) + 3*(1-colorWheelFill(1,:))/4);
set(findall(h,'type','axes'),'fontsize',20, 'FontName',...
    'Arial', 'TickDir', 'in','box','on', 'XTick', [1,2,3], 'XTickLabels',{'4dpf', '5dpf', '6dpf'});
xlim([0.85, 3.15]);
ylim(yLimFreqRet);
set(h, 'Units', 'Inches');
pos = get(h, 'Position');
set(h, 'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)]);
print(h, strcat(mainFigureDirectory, filesep, 'Figure4Ret', filesep, 'FreqSTD.pdf'), '-dpdf', '-r0');

% h = figure;
% curPos = get(h, 'Position');
% set(h, 'Position', [curPos(1), curPos(2), curPos(3)/3, curPos(4)/3]);
% scatter(1:3, retStd(2,:,2), markerSize, 'MarkerEdgeColor', colorWheelBorder(3,:), 'MarkerFaceColor', colorWheelFill(3,:)); hold on;
% scatter(1:3, wtStd(2,:,2), markerSize, 'MarkerEdgeColor', colorWheelBorder(1,:), 'MarkerFaceColor', colorWheelFill(1,:));
% set(findall(h,'type','axes'),'fontsize',20, 'FontName',...
%     'Arial', 'TickDir', 'in','box','on', 'XTick', [1,2,3], 'XTickLabels',{'4dpf', '5dpf', '6dpf'});
% xlim([0.85, 3.15]);
% ylim(yLimFreqRet);
% set(h, 'Units', 'Inches');
% pos = get(h, 'Position');
% set(h, 'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)]);
% print(h, strcat(mainFigureDirectory, filesep, 'Figure4Ret', filesep, 'Freq2STD.pdf'), '-dpdf', '-r0');

% STD feed amp
h = figure;
curPos = get(h, 'Position');
set(h, 'Position', [curPos(1), curPos(2), curPos(3)/3, curPos(4)/3]);
scatter(1:3, micronsPerPixel/fps*fedStd(1,:,1), markerSize, 'Marker', 'o', 'MarkerEdgeColor', colorWheelBorder(2,:), 'MarkerFaceColor', colorWheelFill(2,:)); hold on;
scatter(1:3, micronsPerPixel/fps*unfedStd(1,:,1), markerSize, 'Marker', 'o', 'MarkerEdgeColor', colorWheelBorder(1,:), 'MarkerFaceColor', colorWheelFill(1,:));
scatter(1:3, micronsPerPixel/fps*fedStd(2,:,1), markerSize, 'Marker', 'd', 'MarkerEdgeColor', colorWheelBorder(2,:) + (1-colorWheelBorder(2,:))/2, 'MarkerFaceColor', colorWheelFill(2,:) + 3*(1-colorWheelFill(2,:))/4);
scatter(1:3, micronsPerPixel/fps*unfedStd(2,:,1), markerSize, 'Marker', 'd', 'MarkerEdgeColor', colorWheelBorder(1,:) + (1-colorWheelBorder(1,:))/2, 'MarkerFaceColor', colorWheelFill(1,:) + 3*(1-colorWheelFill(1,:))/4);
%xticks([1,2,3]);
set(findall(h,'type','axes'),'fontsize',20, 'FontName',...
    'Arial', 'TickDir', 'in','box','on', 'XTick', [1,2,3], 'XTickLabels',{'4dpf', '5dpf', '6dpf'});
xlim([0.85, 3.15]);
ylim(yLimAmpFeed);
set(h, 'Units', 'Inches');
pos = get(h, 'Position');
set(h, 'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)]);
print(h, strcat(mainFigureDirectory, filesep, 'Figure3Feeding', filesep, 'AmpSTD.pdf'), '-dpdf', '-r0');
% 
% h = figure;
% curPos = get(h, 'Position');
% set(h, 'Position', [curPos(1), curPos(2), curPos(3)/3, curPos(4)/3]);
% scatter(1:3, fedStd(2,:,1), markerSize, 'MarkerEdgeColor', colorWheelBorder(2,:), 'MarkerFaceColor', colorWheelFill(2,:)); hold on;
% scatter(1:3, unfedStd(2,:,1), markerSize, 'MarkerEdgeColor', colorWheelBorder(1,:), 'MarkerFaceColor', colorWheelFill(1,:));
% set(findall(h,'type','axes'),'fontsize',20, 'FontName',...
%     'Arial', 'TickDir', 'in','box','on', 'XTick', [1,2,3], 'XTickLabels',{'4dpf', '5dpf', '6dpf'});
% xlim([0.85, 3.15]);
% ylim(yLimAmpFeed);
% set(h, 'Units', 'Inches');
% pos = get(h, 'Position');
% set(h, 'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)]);
% print(h, strcat(mainFigureDirectory, filesep, 'Figure3Feeding', filesep, 'Amp2STD.pdf'), '-dpdf', '-r0');

% STD feed freq
h = figure;
curPos = get(h, 'Position');
set(h, 'Position', [curPos(1), curPos(2), curPos(3)/3, curPos(4)/3]);
scatter(1:3, fedStd(1,:,2), markerSize, 'Marker', 'o', 'MarkerEdgeColor', colorWheelBorder(2,:), 'MarkerFaceColor', colorWheelFill(2,:)); hold on;
scatter(1:3, unfedStd(1,:,2), markerSize, 'Marker', 'o', 'MarkerEdgeColor', colorWheelBorder(1,:), 'MarkerFaceColor', colorWheelFill(1,:));
scatter(1:3, fedStd(2,:,2), markerSize, 'Marker', 'd', 'MarkerEdgeColor', colorWheelBorder(2,:) + (1-colorWheelBorder(2,:))/2, 'MarkerFaceColor', colorWheelFill(2,:) + 3*(1-colorWheelFill(2,:))/4);
scatter(1:3, unfedStd(2,:,2), markerSize, 'Marker', 'd', 'MarkerEdgeColor', colorWheelBorder(1,:) + (1-colorWheelBorder(1,:))/2, 'MarkerFaceColor', colorWheelFill(1,:) + 3*(1-colorWheelFill(1,:))/4);
set(findall(h,'type','axes'),'fontsize',20, 'FontName',...
    'Arial', 'TickDir', 'in','box','on', 'XTick', [1,2,3], 'XTickLabels',{'4dpf', '5dpf', '6dpf'});
xlim([0.85, 3.15]);
ylim(yLimFreqFeed);
set(h, 'Units', 'Inches');
pos = get(h, 'Position');
set(h, 'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)]);
print(h, strcat(mainFigureDirectory, filesep, 'Figure3Feeding', filesep, 'FreqSTD.pdf'), '-dpdf', '-r0');
% 
% h = figure;
% curPos = get(h, 'Position');
% set(h, 'Position', [curPos(1), curPos(2), curPos(3)/3, curPos(4)/3]);
% scatter(1:3, fedStd(2,:,2), markerSize, 'MarkerEdgeColor', colorWheelBorder(2,:), 'MarkerFaceColor', colorWheelFill(2,:)); hold on;
% scatter(1:3, unfedStd(2,:,2), markerSize, 'MarkerEdgeColor', colorWheelBorder(1,:), 'MarkerFaceColor', colorWheelFill(1,:));
% set(findall(h,'type','axes'),'fontsize',20, 'FontName',...
%     'Arial', 'TickDir', 'in','box','on', 'XTick', [1,2,3], 'XTickLabels',{'4dpf', '5dpf', '6dpf'});
% xlim([0.85, 3.15]);
% ylim(yLimFreqFeed);
% set(h, 'Units', 'Inches');
% pos = get(h, 'Position');
% set(h, 'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)]);
% print(h, strcat(mainFigureDirectory, filesep, 'Figure3Feeding', filesep, 'Freq2STD.pdf'), '-dpdf', '-r0');