function objs = dedrift(objs, dispopt)

% dedrift : drift correction for tracked objects
%
% Determines the mean x and y positions of objects in each frame
%   Median Deltax, Deltay characterize the drift, which is then subtracted
%   from the x and y positions for the output matrix.
% Does not use a linear fitting of mean positions, as this may be sensitive
%   to particles entering or leaving the field of view
% Notes which frames exist, to avoid problems from missing frames
% Input dispopt -- if true, display graphs and slope values

% objs = Object matrix from im2obj_rp or nnlink_rp, with the following form:
%   [x;
%    y;
%    mass;
%    particleid;
%    frame;
%    trackid]

% Raghuveer Parthasarathy
% July 12, 2007
% last modified: August 2, 2007

if (nargin < 2)  % Assume user wants to plot
    dispopt=true;
end

unqtracks = unique(objs(6,:)); % get track numbers

Bx = zeros(1,length(unqtracks));
sigBx = zeros(1,length(unqtracks));
By = zeros(1,length(unqtracks));
sigBy = zeros(1,length(unqtracks));
npts = zeros(1,length(unqtracks));
k = 1;
for j=unqtracks
    tr = objs(:, ismember(objs(6,:),j));  % object matrix only with track j
    goodx = ~isnan(tr(1,:));
    fr = tr(5,goodx);
    x  = tr(1,goodx);
    y  = tr(2,goodx);
    npts(k) = length(fr);
    if (npts(k) > 2)
        [A, sigA, Bx(k), sigBx(k)] = fitline(fr, x, false);
        [A, sigA, By(k), sigBy(k)] = fitline(fr, y, false);
        k = k+1;
    end
end
gx = ~isnan(Bx);
gy = ~isnan(By);
Bx = Bx(gx);  % shouldn't be necessary...
By = By(gy);  % shouldn't be necessary...

mBx = median(Bx);
mBy = median(By);

if dispopt
    figure; hist(Bx, 50); title('Histogram of slopes: x'); xlabel('x-Slope')
    figure; hist(By, 50); title('Histogram of slopes: y'); xlabel('y-Slope')
    fs = sprintf('Slope of drift = %.3e (x), %.3e (y)', mBx, mBy);
    disp(fs)
end

% correct x and y values in the object matrix
objs(1,:) = objs(1,:)-objs(5,:)*mBx;
objs(2,:) = objs(2,:)-objs(5,:)*mBy;

