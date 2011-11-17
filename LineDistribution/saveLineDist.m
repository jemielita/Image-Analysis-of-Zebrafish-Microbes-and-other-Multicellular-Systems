%Plots the results from the line distribution calculation.


function [data, param] = saveLineDist(data,param, type)


%% General variables
%Distance from the centroid of the first region, in microns

distVect = param.centroidDist*(0:param.numBoxes -1);
distVect = distVect*param.micronPerPixel;

lineData = zeros(1,length(distVect));


%% Creating plots for each scan, color and region

%Save all the individual plots in a subfolder indivPlot;
indivSaveDir = [param.dataSaveDirectory, filesep, 'indivPlot'];
mkdir(indivSaveDir);



%For each line scan taken plot the distribution along the length of the
%regions.
for nScan=1:length(data.scan)
    %Going through each scan
    for nRegion=1:length(data.scan(nScan).region)
        %Going through each region in this scan
        for nColor=1:length(data.scan(nScan).region(nRegion).color)
            %and each color
            lineData = [data.scan(nScan).region(nRegion).color(nColor).lineProp.MeanIntensity];
            

            hPlot = plot(distVect,lineData,'b-',distVect,lineData,'bo');
            
            %Labeling the figure
            titleString1 = 'Normalized Pixel Intensity for Different Averging Boxes';
            titleString2 = strcat('Scan ', num2str(nScan), ...
                ', Region ',num2str(nRegion), ' Color ', num2str(nColor));
            title({titleString1 ; titleString2});
            xlabel('Distance from first averaging box (microns)');
            ylabel('Mean Pixel Intensity');
            
            %Saving the figure as a .fig file
            saveFile = [indivSaveDir, filesep, 'Scan_', num2str(nScan),...
                'Region_', num2str(nRegion), 'Color_',num2str(nColor)];
           saveas(hPlot(1), saveFile);
  

        end
    end
end

%Close these figures
close all

%% Creating a plot showing the time evolution of the intensity
%% distributions for one color


%Save all the individual plots in a subfolder indivPlot;
allScanSaveDir = [param.dataSaveDirectory, filesep, 'allScanPlot'];
mkdir(allScanSaveDir);

scanData = zeros(length(lineData),3, length(data.scan));

for i=1:length(data.scan)
    scanData(:,1,i) = distVect;
end

%Going through each scan
for nRegion=1:length(data.scan(nScan).region)
    %Going through each region in this scan
    for nColor=1:length(data.scan(nScan).region(nRegion).color)
        for nScan=1:length(data.scan)
            lineData = [data.scan(nScan).region(nRegion).color(nColor).lineProp.MeanIntensity];
            scanData(:,3,nScan) = lineData;
            scanData(:,2,nScan) = nScan;
        end
        
        %Now plotting all these figures
        hold on
        
        %Plot each scan a different color
        cmap = hsv(length(data.scan));
        
        for i=1:length(data.scan)
           hPlot =  plot3(scanData(:,1,i), scanData(:,2,i), scanData(:,3,i), '-bo', 'Color', cmap(i,:));
            
        end
        
        
        %Labeling the figure
        titleString1 = 'Normalized Pixel Intensity for Different Averging Boxes';
        titleString2 = strcat('All scans ', ...
            ', Region ',num2str(nRegion), ' Color ', num2str(nColor));
        title({titleString1 ; titleString2});
        xlabel('Distance from first averaging box (microns)');
        ylabel('Scan Number');
        zlabel('Mean Pixel Intensity');
        
        hold off
        %Save the result
        
        saveFile = [allScanSaveDir, filesep, 'Region_', num2str(nRegion), 'Color_',num2str(nColor)];
        saveas(hPlot(1), saveFile);
        
        
    end
    
end

close all


%
end