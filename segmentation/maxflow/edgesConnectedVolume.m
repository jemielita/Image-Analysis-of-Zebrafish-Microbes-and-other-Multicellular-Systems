function E = edgesConnectedVolume(height, width, depth)
% edgesConnectedVolume Creates edges where each node is connected to its
% six adjacent neighbors on a height x width x depth grid.
% E - a vector in which each row i represents an edge
% E(i,1) --> E(i,2). The edges are listed is in the following
% neighbor order: down,up,right,left, where nodes
% indices are taken column-major.
%
% Based on edges4connected by Michael Rubinstein, an implementation for
% finding connected edges of a 2D grid.
%
% Author: Matthew Jemielita, July 17, 2012

% N = height*width*depth;
% 
% I = []; J = [];
% 
% %Find vertically connected components
% neighborI = [1:N]';
% neighborI([height:height:N]) = [];
% 
% neighborJ = neighborI+1;
% I = [I;neighborI;neighborJ];
% J = [J;neighborJ;neighborI];
% 
% %Find horizontally connected components
% neighborI = [1:N-height]';
% %Remove elements on the far right of any single z-plane
% ind = find( mod(neighborI+height-1,height*width) <height);
% neighborI(ind) = [];
% 
% 
% neighborJ = neighborI+height;
% I = [I;neighborI;neighborJ];
% J = [J;neighborJ;neighborI];
% 
% %Find connected components in z-direction (parallel to depth direction)
% neighborI = [1:N-height*width]';
% neighborJ = neighborI+height*width;
% 
% I = [I; neighborI; neighborJ];
% J = [J; neighborJ; neighborI];
% 
% E = [I,J];

N = height*width*depth;

numVConn = (height-1)*width*depth;
numHConn = (width-1)*height*depth;
numDConn = (depth-1)*height*width;

E = zeros(2*(numVConn+numHConn+numDConn), 2);

%Find vertically connected components
neighborI = [1:N]';
neighborI([height:height:N]) = [];

neighborJ = neighborI+1;
% I = [I;neighborI;neighborJ];
% J = [J;neighborJ;neighborI];

E(1:2*numVConn,1) = [neighborI; neighborJ];
E(1:2*numVConn,2) = [neighborJ;neighborI];

%Find horizontally connected components
neighborI = [1:N-height]';
%Remove elements on the far right of any single z-plane
ind =  mod(neighborI+height-1,height*width) <height;
neighborI(ind) = [];

neighborJ = neighborI+height;

E(2*numVConn+1:2*(numVConn+numHConn),1) = [neighborI;neighborJ];
E(2*numVConn+1:2*(numVConn+numHConn),2) = [neighborJ; neighborI];


%Find connected components in z-direction (parallel to depth direction)
neighborI = [1:N-height*width]';
neighborJ = neighborI+height*width;
% 
% I = [I; neighborI; neighborJ];
% J = [J; neighborJ; neighborI];

E(end-2*numDConn+1:end,1) = [neighborI;neighborJ];
E(end-2*numDConn+1:end,2) = [neighborJ;neighborI];

% E = [I,J];



end