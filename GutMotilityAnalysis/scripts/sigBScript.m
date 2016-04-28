% Script which plots the graph from which sigB is obtained

scale = 0.325; % Units of Micron/pixel
fps = 5;
translateMarkerNumToMicron = scale*round( mean( diff( squeeze( gutMesh( 1, :, 1, 1 ) ) ) ) ); % Units of Micron/Marker
m = 1/waveSpeedSlope;
b = 60/waveFrequency;
x = translateMarkerNumToMicron*( ( analyzedDeltaMarkers( 1 ) - 1 ):( analyzedDeltaMarkers( 2 ) - 1 ) );
y = xCorrMaxima/fps + b - ( xCorrMaxima( 1 )/fps ); % xCorrMaxima was saved in a subset image so the offset needs to be added back
yy = m*x + b;

figure;
plot(x, y, 'b-'); hold on;
plot(x, yy, 'r-'); hold off;
axis([x(1), x(end), 0, y(end)]);