function [] = plotData(data, dataTitle)
%Plots the intensity data over time for the bacterial experiments
timePoints = size(data, 1);
distPoints = size(data,3);

green = data(:,1,:);
green = squeeze(green);


red = data(:,2,:);
red = squeeze(red);

%Putting together the data
combRed = zeros(timePoints, distPoints,3);
combRed(:,:,1) = red;
combRed(:,:,2) = repmat(cumsum(20*ones(1,distPoints)),timePoints,1);
tp = [1:timePoints]';
combRed(:,:,3) = repmat(tp, 1, distPoints);

red = combRed;


combGreen = zeros(timePoints, distPoints, 3);
combGreen(:,:,1) = green;
combGreen(:,:,2) = repmat(cumsum(20*ones(1,distPoints)), timePoints,1);
combGreen(:,:,3) = repmat(tp, 1, distPoints);

green = combGreen;



hFig = figure; 
hAxis = axes('Parent', hFig);

hold on
cData = cool(timePoints);
for i=1:timePoints
    
 p =    plot3(green(i,:,3), green(i,:,2), green(i,:,1));
    set(p, 'Color', cData(i,:));
    
end
plotTitle = strcat(dataTitle, ': green channel');
title(plotTitle);
hold off


hFig = figure; 
hAxis = axes('Parent', hFig);

hold on
cData = cool(timePoints);
for i=1:timePoints
    
 p =    plot3(red(i,:,3), red(i,:,2), red(i,:,1));
    set(p, 'Color', cData(i,:));
    
    
end
plotTitle = strcat(dataTitle, ': red channel');
title (plotTitle)
hold off