function objs = im2obj_rp(im, objsize, thresh, fitstr)
%im2obj : finds objects in image stack
%
% im      : 3-d matrix of images
% objsize : size in pixels of objects to find
% thresh  : number in [0 1] to threshold objects with
% fitstr : (Optional) string that selects the fitting option (Gaussian or
%    centroid) for use in fo4_rp.  Default is non-linear 2DGaussian 
%    ('nonlineargauss').   For centroid, enter 'centroid'.  For linear-fit
%    of a 2D gaussian, enter 'gauss'
%
% Output:
% objs    : object matrix with following form:
%
%             objs = [x;
%                     y; 
%                     mass; (brightness)
%                     particleid; 
%                     frame; 
%                     trackid]
%           frame field is set by im2obj().  
%
% based on Andrew Demond's im2obj.m
% Modified by Raghuveer Parthasarathy, 16 April, 2007:
%   Calls fo4_rp -- RP's modified fo4.m -- no t-test, just std test
%   (deleted iput p : standard deviation value for maxima test in fo4_rp()
%           -- recommended: not > 1 )
% June 3, 2011: use distance.m for close pair calculation -- very small
% speedup
%
% Last modified: June 28, 2011

% Fitting option; default is Gaussian
if ~exist('fitstr', 'var') || isempty(fitstr)
    disp('Default fitting option: non-linear 2D Gaussian');
    fitstr = 'nonlineargauss';
end
if strcmpi(fitstr, 'centroid')
    disp('Center of mass (centroid) fit -- AVOID unless necessary (saturated images)');
end

% Get nonlinear fitting options, to avoid repeated calls
% These are only used for non-linear Gaussian fitting, but it doesn't hurt
% to define them and pass them on to fo4_rp.m 
lsqoptions = optimset('lsqnonlin');

objs = [];
nf = size(im,3);
progtitle = sprintf('im2obj_{rp}: Finding objects...  '); 
if (nf > 1)
    progbar = waitbar(0, progtitle);  % will display progress
end
for j = 1:nf
    tmpobj = fo4_rp(im(:,:,j), objsize, thresh, fitstr, lsqoptions);
    tmpobj(5,:) = j;
    objs = [objs tmpobj];
    % show progress
    if nf>1
        waitbar(j/nf, progbar, ...
            strcat(progtitle, sprintf('frame %d of %d', j, nf)));
    end
end
if nf>1
    close(progbar)
end


% --------------------------------------------------------------
% Check for likely multiple identifications of the same particle
%   --- find pairs within the same frame that are separated by <2*objsize
% If these are found, user should re-run the function with a larger
%   value of objsize
unqframes = unique(objs(5,:)); % get unique frame numbers
anyclose = false;
for j=unqframes,
    objframe = objs(:,objs(5,:)==j);  
        % columns of the object matrix for this frame
    if size(objframe,2)>1
        % more than one particle found in this frame
        % consider all particle pairs, find any for which
        % separation < 2*objsize

        allr = [objframe(1,:); objframe(2,:)];  % 2 x "N" matrix of x,y
        d = distance(allr,allr);  % Euclidiean distance matrix
        isclose = (d < 2*objsize);  % close pairs, and d for same pairs
        closepair = (sum(isclose(:)) - size(objframe,2))/2.0;  
        if (closepair > 0)
            fs = sprintf('Frame %d: %d close pairs.', j, closepair);
            disp(fs);
            anyclose = true;
        end
    end
end
if anyclose
    disp('Close pairs found (above) -- recommend re-running with larger objsize.');
end