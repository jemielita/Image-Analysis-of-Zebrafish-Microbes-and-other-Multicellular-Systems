% Script for debugging impoly graphics problems. Assumes an image assigned
% to variable name f is already in memory

NSeconds=40;
fps = 5;
onlyShowFirstNSeconds=1:NSeconds*fps;
% imshow(f(onlyShowFirstNSeconds,:),[], 'InitialMagnification','fit', 'YData', [0, NSeconds]);
imshow(f(onlyShowFirstNSeconds,:),[], 'YData', [0, NSeconds]);
set(gcf, 'Position', get(0, 'Screensize') );
set(gca,'YDir','normal')
axis square;
colormap('Jet');

% Obtain rough line around maxima
roughFitEstimate = impoly( 'Closed', false );
rFEPoly = getPosition( roughFitEstimate );