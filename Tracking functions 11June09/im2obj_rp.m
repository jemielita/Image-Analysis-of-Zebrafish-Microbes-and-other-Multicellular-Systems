function objs = im2obj_rp(im, objsize, thresh, fitstr)
%im2obj : finds objects in image stack
%
% im      : 3-d matrix of images
% objsize : size in pixels of objects to find
% thresh  : number in [0 1] to threshold objects with
% fitstr : (Optional) string that selects the fitting option (Gaussian or
%    centroid) for use in fo4_rp.  Default is Gaussian ('gauss').  
%    For centroid, enter 'centroid'.
%
% Output:
% objs    : object matrix with following form:
%
%             objs = [x;
%                     y; 
%                     mass; 
%                     particleid; 
%                     frame; 
%                     trackid]
%           
%           frame field is set by im2obj().  
%
% based on Andrew Demond's im2obj.m
% Modified by Raghuveer Parthasarathy, 16 April, 2007:
%   Calls fo4_rp -- RP's modified fo4.m -- no t-test, just std test
%   (deleted iput p : standard deviation value for maxima test in fo4_rp()
%           -- recommended: not > 1 )
%
% Last modified: June 11, 2009

% Fitting option; default is Gaussian
if (nargin<4)
    fitstr = 'gauss';
end
if strcmpi(fitstr, 'centroid')
    disp('Center of mass (centroid) fit -- AVOID unless necessary (saturated images)');
end

objs = [];
nf = size(im,3);
progtitle = sprintf('im2obj_{rp}: Finding objects...  '); 
if (nf > 1)
    progbar = waitbar(0, progtitle);  % will display progress
end
for j = 1:nf
    tmpobj = fo4_rp(im(:,:,j), objsize, thresh, fitstr);
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
        % loop through all particle pairs, find any for which
        % separation < 2*objsize
        closepair = 0;
        for k=1:(size(objframe,2)-1),
            for m=(k+1):size(objframe,2),
                dx = objframe(1,k)-objframe(1,m);
                dy = objframe(2,k)-objframe(2,m);
                d = sqrt(dx*dx+dy*dy);
                if (d < 2*objsize)
                    closepair = closepair+1;
                end
            end
        end
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