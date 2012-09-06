function [] = plotData(data, dataTitle)

%Extracting color channels
green = data{1};
red = data{2};

%Plots the intensity data over time for the bacterial experiments
timePoints = size(green, 2);

%Putting together the data
% combRed = zeros(timePoints, distPoints,3);
% combRed(:,:,1) = red;
% combRed(:,:,2) = repmat(cumsum(20*ones(1,distPoints)),timePoints,1);
% tp = [1:timePoints]';
% combRed(:,:,3) = repmat(tp, 1, distPoints);
% 
% red = combRed;
% 
% combGreen = zeros(timePoints, distPoints, 3);
% combGreen(:,:,1) = green;
% combGreen(:,:,2) = repmat(cumsum(20*ones(1,distPoints)), timePoints,1);
% combGreen(:,:,3) = repmat(tp, 1, distPoints);
% 
% green = combGreen;


scrsz = get(0,'ScreenSize');
hFig = figure('Position',[1+500 scrsz(4)/2 - 300 scrsz(3)/2 scrsz(4)/2])

hAxis = axes('Parent', hFig);
set(hAxis, 'ZLim', [0 1500]);
hold on
% cData = cool(timePoints);


cData = summer(ceil(2*timePoints));

for i=1:timePoints
    len = length(green{i}(:,1));
    
    p = plot3(1:len, i*10*ones(len,1), green{i}(:,1));
    set(p, 'Color', cData(i,:));
    
end
plotTitle = strcat(dataTitle, ': GFP');
hTitle = title(plotTitle);
set(hTitle, 'FontSize', [16]);

% hYLabel = ylabel('Distance down gut (microns)');
% hXLabel = xlabel('Time (hours)');
% hZLabel = zlabel('Normalized Total pixel intensity');


hold off
view([-64 36]);
% 
% set(hXLabel, 'FontSize', [16]);
% set(hYLabel, 'FontSize', [16]);
% set(hZLabel, 'FontSize', [16]);
% 
% set(hZLabel, 'Position', 1.0e+003*[-0.3084, -2.6754, 0.3870]);
% set(hXLabel, 'Position', 1.0e+003*[-0.2938, -4.4404, 0.3592]);
% set(hYLabel, 'Position', 1.0e+003*[-0.3120, -3.7374, 0.3488]);

%set(hAxis, 'XTick', [10.28 20.56 30.84 41.12]);
%set(hAxis, 'XTickLabel', [4 8 12 16]);
%set(hFig, 'Position', [680 344 815 634]);


scrsz = get(0,'ScreenSize');
hFigRed = figure('Position',[1+500 scrsz(4)/2 - 300 scrsz(3)/2 scrsz(4)/2])

hAxisRed = axes('Parent', hFigRed);
% set(hAxis, 'ZLim', [0 300000]);
%set(hAxis, 'ZLim', [0 40000]);
hold on
cData = hot(2*timePoints);
set(hAxisRed, 'ZLim', [0 1000]);
for i=1:timePoints
    

     len = length(red{i}(:,1));
    
    p = plot3(1:len, i*10*ones(len,1), red{i}(:,1));
    set(p, 'Color', cData(i,:));
    
end
plotTitle = strcat(dataTitle, ': tdTomato');
hTitle = title(plotTitle);
set(hTitle, 'FontSize', [16]);
% 
% hYLabel = ylabel('Distance down gut (microns)');
% hXLabel = xlabel('Time (hours)');
% hZLabel = zlabel('Normalized Total pixel intensity');


hold off
view([-64 36]);
% 
% set(hXLabel, 'FontSize', [16]);
% set(hYLabel, 'FontSize', [16]);
% % set(hZLabel, 'FontSize', [16]);
% 
% set(hZLabel, 'Position', 1.0e+003*[-0.3084, -2.6754, 0.3870]);
% set(hXLabel, 'Position', 1.0e+003*[-0.2938, -4.4404, 0.3592]);
% set(hYLabel, 'Position', 1.0e+003*[-0.3120, -3.7374, 0.3488]);

%Redefine in terms of time
%set(hAxisRed, 'XTick', [10.28 20.56 30.84 41.12]);
%set(hAxisRed, 'XTickLabel', [4 8 12 16]);
%set(hFigRed, 'Position', [680 344 815 634]);

