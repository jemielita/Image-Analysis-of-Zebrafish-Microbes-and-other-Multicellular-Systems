function analyzeGutData(gutMesh, gutMeshVels, gutMeshVelsPCoords, fps, scale)

%% Initialize variables
nV=size(gutMeshVels,1);
nU=size(gutMeshVels,2);
nT=size(gutMeshVels,4);
totalTimeFraction=1;
time=1/fps:1/fps:nT/(fps*totalTimeFraction);
markerNum=1:nU;

%% Longitudinal Motion as a surface

surfL=squeeze(mean(gutMeshVelsPCoords(:,:,1,1:end/totalTimeFraction),1));

figure;
surf(time,markerNum,surfL,'LineStyle','none');
colormap('Jet');
%caxis([-numSTD*stdFN,numSTD*stdFN]);

title('Longitudinal velocities down the gut','FontSize',12,'FontWeight','bold');
xlabel('Time (s)','FontSize',20);
ylabel('Marker number','FontSize',20);
% axes('FontSize',15);
% set(findall(h,'type','axes'),'fontsize',15,'fontWeight','bold')
% print('-dtiff','-r300','WT_7_22_Fish2_Marker_Tracks');

%% Transverse Motion as a surface

surfL=squeeze(mean(gutMeshVelsPCoords(:,:,2,1:end/totalTimeFraction),1));

figure;
surf(time,markerNum,surfL,'LineStyle','none');
colormap('Jet');
%caxis([-numSTD*stdFN,numSTD*stdFN]);

title('Transverse velocities down the gut','FontSize',12,'FontWeight','bold');
xlabel('Time (s)','FontSize',20);
ylabel('Marker number','FontSize',20);
% axes('FontSize',15);
% set(findall(h,'type','axes'),'fontsize',15,'fontWeight','bold')
% print('-dtiff','-r300','WT_7_22_Fish2_Marker_Tracks');

end