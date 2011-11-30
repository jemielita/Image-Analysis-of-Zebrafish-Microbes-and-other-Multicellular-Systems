function objs = nnlink_rp(objs, step, memory, dispopt)
% links objects into paths, simply using nearest-neighbor identification
% rudimentary checking for unique neighbors
% format matches Andy Demond's link4.m
% uses "distance.m" by Roland Bunschoten (MATLAB file exchange)
% 
% Raghuveer Parthasarathy
% 16 April, 2007
% May 10, 2007: Fixed foward-backward mapping
% last modified: Dec. 19, 2007 (display option)

if (nargin<4)
    dispopt=true;
end

unqframes = unique(objs(5,:)); % get frame numbers
% Ensure the starting frame number is 1 -- a quick fix -- to avoid a flaw
% in the tracking algorithm
objs(5,:) = objs(5,:) - min(unqframes) + 1;

leftovers = [];

% first assign initial track ids to all objects in the first frame
fm1numobjs = size(objs(4, objs(5,:) == 1), 2);
objs(6, objs(5,:) == 1) = 1:fm1numobjs;
nextid = fm1numobjs + 1; % the next available track id

if dispopt
    progtitle = sprintf('nnlink_{rp}: Linking objects...  '); 
    progbar = waitbar(0, progtitle);  % will display progress
end

for i = 1:length(unqframes)-1
    % disp(['link : [' num2str(i) ',' num2str(length(unqframes) - 1) ']']);
    cur = [find(objs(5,:) == i) leftovers]; 
    nex = (find(objs(5,:) == i+1));     
    % cur and nex are indicies into the object matrix (objs)
    % cur contains all indices corresponding to the present frame, and all
    % the "leftovers" from earlier frames within the "memory" time
    ncur = length(cur);
    nnex = length(nex);
    if or((ncur == 0),(nnex == 0)) % no elements to track, go to next frame
        disp('No objects to link');
        continue;
    end
    
    % nearest-neighboor matching algorithm
    pcur = objs(1:2, cur);
    pnex = objs(1:2, nex);
    d = distance(pnex,pcur);  % should be ncur by nnex array of distances
                              % d(j,k) is the distance between pnex(j) and
                              % pcur(k)
    [nnf, fmap] = min(d,[],1);  % fmap(j) is the index number in pnex of the particle
                         % that is closest to particle #j in pcur 
                         % nnf has length ncur
                         % Don't use min(d), returns the minimum from each
                         % column of d only if d is not a row vector
    [nnb, bmap] = min(d,[],2);  % bmap(j) is the index number in pcur of the particle
                         % that is closest to particle #j in pnex 
                         % nnf has length nnex
    invertible = bmap(fmap); % fmap indexes into bmap

    fmapind = 1:length(fmap);
    notlost = fmapind(ismember(fmapind, invertible));  
       % "ismember" is true for a particle of pcur that is mapped back onto
       % itself.  Keep only these in "notlost"
    % Andy's version:
    %invertible(invertible ~= fmapind) = []; % just keep particles for which bmap == inverse(fmap)
    
    % Cull all links that are greater than sqrt(step*memory) away
    invo1x = objs(1, cur(notlost));
    invo1y = objs(2, cur(notlost));
    invo2x = objs(1, nex(fmap(notlost)));
    invo2y = objs(2, nex(fmap(notlost)));
    sqdisp = (invo1x - invo2x).^2 + (invo1y - invo2y).^2;
    notlost = notlost(sqdisp < step*memory);
    
    % assign track ids to particles in next frame
    objs(6, nex(fmap(notlost))) = objs(6, cur(notlost));

    % cull old objects
    cur(notlost) = [];
    curframes = objs(5, cur);
    cullind = find(curframes < (i - memory));
    objs(6, cur(cullind)) = 0; % particles with trackid 0 are culled at end
    cur(cullind) = [];
    
    % add the rest to leftovers
    leftovers = cur;
    
    % assign new trackids to members of nex for which bmap ~= inv(fmap)
    % complicated -- from Andy
    bmapind = (1:length(bmap))';
    onesnew = ones(size(bmapind));
    onesinv = ones(size(notlost));
    resinv = kron(fmap(notlost), onesnew);
    resnew = kron(onesinv, bmapind);
    mask = all(resinv ~= resnew, 2);
    newguys = bmapind(mask);

    if (~isempty(newguys))
        objs(6, nex((newguys))) = nextid:(nextid+length(newguys)-1);
        nextid = nextid + length(newguys);
    end
    
    % show progress
    if dispopt
        waitbar(i/(length(unqframes)-1), progbar, progtitle);
    end
end
if dispopt
    close(progbar)
end

% now get rid of unmatched particles
singletons = find(objs(6,:) == 0);
objs(:, singletons) = [];

if dispopt
    % Display information about tracks found
    fs = sprintf('Found %d unique tracks.', length(unique(objs(6,:))));
    disp(fs)
    for j=unique(objs(6,:))
        frj = objs(5,find(objs(6,:)==j));
        fs = sprintf('   Track %d: frames %d:%d (%d frames)',...
            j, min(frj), max(frj), length(frj));
        % Note that some frames between min and max may not be good
        disp(fs)
    end
end
