%% Fix later blue overwriting red

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

%% Tau Autocorrelations of wave propagations
tauSubdiv=1;
colorSize=size(surfL,1);
erx=int16(size(gutMeshVelsPCoords,4)/fractionOfTimeStart:(size(gutMeshVelsPCoords,4)/(fractionOfTimeStart)+size(gutMeshVelsPCoords,4)/totalTimeFraction-1));
surfL=squeeze(-mean(gutMeshVelsPCoords(:,markerNumStart:markerNumEnd,1,erx),1));
figure
hold all;
for i=1:tauSubdiv:size(surfL,1)
    r=xcorr(surfL(i,:),'coeff');
    x=0:size(r,2)/2;
    dt=x/fps;
    plot(dt,r(end/2:end),'Color',[sin(3.1415/(2*colorSize)*(i-1)),0,cos(3.1415/(2*colorSize)*(i-1))]);
end
plot(dt,zeros(1,size(dt,2)),'k-');
hold off;
title('Autocorrelations of Anterior-Posterior velocities over time (Blue=Anterior, Red=Posterior)','FontSize',12,'FontWeight','bold');
xlabel('\tau (s)','FontSize',20);
ylabel('Correlation','FontSize',20);

%% Tau Correlations of wave propagations
erx=int16(size(gutMeshVelsPCoords,4)/fractionOfTimeStart:(size(gutMeshVelsPCoords,4)/(fractionOfTimeStart)+size(gutMeshVelsPCoords,4)/totalTimeFraction-1));
surfL=squeeze(-mean(gutMeshVelsPCoords(:,markerNumStart:markerNumEnd,1,erx),1));
figure
hold all;
for i=1:size(surfL,1)
    for j=(i+1):size(surfL,1)
        r=xcorr(surfL(i,:),surfL(j,:),'coeff');
        x=0:size(r,2)/2;
        dt=x/fps;
        dc=j-i-1;
        plot(dt,r(end/2:end),'Color',[sin(3.1415/(2*(size(surfL,1)-2))*dc),0,cos(3.1415/(2*(size(surfL,1)-2))*dc)]);
    end
end
hold off;
title('Correlations between Anterior-Posterior velocities over time (Blue=Anterior, Red=Posterior)','FontSize',12,'FontWeight','bold');
xlabel('\tau (s)','FontSize',20);
ylabel('Correlation','FontSize',20);
end