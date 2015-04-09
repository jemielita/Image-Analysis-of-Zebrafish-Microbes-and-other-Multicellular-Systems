function analyzeGutData(gutMesh, gutMeshVels, gutMeshVelsPCoords, fps, scale, imPath)

curDir=pwd;
cd(imPath);

%% Initialize variables
nV=size(gutMeshVels,1);
nU=size(gutMeshVels,2);
nT=size(gutMeshVels,4);
totalTimeFraction=1;
fractionOfTimeStart=size(gutMeshVelsPCoords,4); % Use size(gutMeshVelsPCoords,4) if beginning
markerNumStart=1;
markerNumEnd=size(gutMesh,2);
time=1/fps:1/fps:nT/(fps*totalTimeFraction);
markerNum=1:nU;

%% Longitudinal Motion as a surface
erx=int16(size(gutMeshVelsPCoords,4)/fractionOfTimeStart:(size(gutMeshVelsPCoords,4)/(fractionOfTimeStart)+size(gutMeshVelsPCoords,4)/totalTimeFraction-1));
surfL=squeeze(-mean(gutMeshVelsPCoords(:,markerNumStart:markerNumEnd,1,erx),1));

figure;
%surf(time,markerNum,surfL,'LineStyle','none');
%imshow(surfL,[],'InitialMagnification','fit');
%truesize;
%h=gca;
erx=[erx(1), erx(end)];
whyr=[markerNumStart,markerNumEnd];
imshow(surfL,[], 'InitialMagnification', 'fit','XData', 1/fps*erx, 'YData', whyr);
set(gca,'YDir','normal')
colormap('Jet');
axis square;
h=gcf;
set(h, 'Position', get(0,'Screensize')); % Maximize figure.
title('Longitudinal velocities down the gut','FontSize',20,'FontWeight','bold');
xlabel('Time (s)','FontSize',20);
ylabel('Marker number','FontSize',20);
%axes('FontSize',15);
set(findall(h,'type','axes'),'fontsize',15,'fontWeight','bold');
cd ..
print -dpng namethisplease;
cd(imPath);

% print('-dtiff','-r300','WT_7_22_Fish2_Marker_Tracks');

%% Transverse Motion as a surface

% surfL=squeeze((mean(gutMeshVelsPCoords(1:end/2,:,2,1:end/totalTimeFraction),1)-mean(gutMeshVelsPCoords((end/2+1):end,:,2,1:end/totalTimeFraction),1))/2); % Transverse components will be opposite sign across gut line
% 
% figure;
% surf(time,markerNum,surfL,'LineStyle','none');
% colormap('Jet');
% %caxis([-numSTD*stdFN,numSTD*stdFN]);
% 
% title('Transverse velocities down the gut','FontSize',12,'FontWeight','bold');
% xlabel('Time (s)','FontSize',20);
% ylabel('Marker number','FontSize',20);
% % axes('FontSize',15);
% % set(findall(h,'type','axes'),'fontsize',15,'fontWeight','bold')
% % print('-dtiff','-r300','WT_7_22_Fish2_Marker_Tracks');
%  cd(curDir);
end