function [bb, theta,height, width] = minBoundingBox(X)
% compute the minimum bounding box of a set of 2D points
%   Use:   [boundingBox, theta] = minBoundingBox(point_matrix)
%
% Input:  2xn matrix containing the [x,y] coordinates of n points
%         *** there must be at least 3 points which are not collinear
% output: bb: 2x4 matrix containing the coordinates of the bounding box corners
%         theta: theta in degrees that the 2D set of points needs to be rotated by in
%         order to get the minimal bounding box
% Example : generate a random set of point in a randomly rotated recttheta
%     n = 50000;
%     t = pi*rand(1);
%     X = [cos(t) -sin(t) ; sin(t) cos(t)]*[7 0; 0 2]*rand(2,n);
%     X = [X  20*(rand(2,1)-0.5)];  % add an outlier
% 
%     tic
%     c = minBoundingBox(X);
%     toc
% 
%     figure(42);
%     hold off,  plot(X(1,:),X(2,:),'.')
%     hold on,   plot(c(1,[1:end 1]),c(2,[1:end 1]),'r')
%     axis equal

% compute the convex hull (CH is a 2*k matrix subset of X)
k = convhull(X(1,:),X(2,:));
CH = X(:,k);

% compute the theta to test, which are the theta of the CH edges as:
%   "one side of the bounding box contains an edge of the convex hull"
E = diff(CH,1,2);           % CH edges
T = atan2(E(2,:),E(1,:));   % theta of CH edges (used for rotation)
T = unique(mod(T,pi/2))-(pi/4); % reduced to the unique set of theta between +-45 degrees.

% create rotation matrix which contains
% the 2x2 rotation matrices for *all* thetas in T
% R is a 2n*2 matrix
R = cos( reshape(repmat(T,2,2),2*length(T),2) ... % duplicate thetas in T
       + repmat([0 -pi ; pi 0]/2,length(T),1));   % shift theta to convert sine in cosine

% rotate CH by all thetas
RCH = R*CH;

% compute border size  [w1;h1;w2;h2;....;wn;hn]
% and area of bounding box for all possible edges
bsize = max(RCH,[],2) - min(RCH,[],2);
area  = prod(reshape(bsize,2,length(bsize)/2));

% find minimal area, thus the index of the theta in T 
[~,i] = min(area);

% compute the bound (min and max) on the rotated frame
Rf    = R(2*i+[-1 0],:);   % rotated frame
bound = Rf * CH;           % project CH on the rotated frame
bmin  = min(bound,[],2);
bmax  = max(bound,[],2);

% compute the corner of the bounding box
Rf = Rf';
bb(:,4) = bmax(1)*Rf(:,1) + bmin(2)*Rf(:,2);
bb(:,1) = bmin(1)*Rf(:,1) + bmin(2)*Rf(:,2);
bb(:,2) = bmin(1)*Rf(:,1) + bmax(2)*Rf(:,2);
bb(:,3) = bmax(1)*Rf(:,1) + bmax(2)*Rf(:,2);


%Get angle to rotate mask by
theta = T(i);
theta = rad2deg(theta);

theta = -theta;
%Get height and width of the bounding box
width = bsize(2*i); width = round(width);
height = bsize(2*i-1);height = round(height);

end