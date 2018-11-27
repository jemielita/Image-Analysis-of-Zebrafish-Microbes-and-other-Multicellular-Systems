% Assumes some 'gutMeshVelsPCoords' has been loaded into memory

% Initialize variables
indexToView = 29; % Usually a number between 1-40
fps = 5;

% Generate surfaces
APSurface = squeeze(mean(gutMeshVelsPCoords(:,:,1,:)));
DVSurface = squeeze(mean(gutMeshVelsPCoords(:,:,2,:)));

% Define slices
APSlice = squeeze(APSurface(indexToView,:));
DVSlice = squeeze(DVSurface(indexToView,:));

% Plot!
rawX = 1:size(APSurface, 2);
%rawX = rawX(1:end/3);
x = rawX/fps;
figure;
hold on;
plot(x, DVSlice(rawX), 'b-');
plot(x, APSlice(rawX), 'r-');
