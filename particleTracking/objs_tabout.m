% objs_tabout.m
%
% function to "print" the contents of an object matrix (position, in
% "objs") or a displacement matrix ("stepvec") as a tab-delimited text file
%
% In each of these, the first two rows are the "data" -- position (x,y) or
% displacement (distance, angle), the last row is the track id, and the
% second-to-last-row is the frame number.
%
%
% Input:
%   A :  objs matrix or stepvec matrix
%   fname = output file name.
%
% Output
% outA : returns a matrix in the same format as the printed matrix
%   Writes a tab-delimited text file.  Each row is a frame, each col. is
%   position or displacement data -- two columns per track.
%   For frames in which the track does not exist, leave empty.
% E.g. for object data (objs) of M tracks with (up to) N frames: 
%     outA = {x11, y11, x21, y21, x31, y31, ... xM1, yM1;
%               x12, y12, x22, y22, x32, y32, ... xM2, yM2;
%               x1N, y1N, x2N, y2N, x3N, y3N, ... xMN, yMN}
%     where the first index is the track id and the second is the frame
%     number}
% E.g. for step data (stepvec) of M tracks with (up to) N frames: 
%     outA = {d11, theta11, d21, theta21, d31, theta31, ... dM1, thetaM1;
%               d1(N-1), theta1(N-1), ... dM(N-1), thetaM(N-1)}
%     where the first index is the track id and the second is the frame
%     number}
%
% March 23, 2009
% Raghuveer Parthasarathy
% last modified March 23, 2009


function outA = objs_tabout(A, fname)

nrows = size(A,1);

utrk = unique(A(nrows,:));  % all the unique track ids

sh = [];  % too short tracks
% Delete tracks with <2 elements
for j = utrk
    % loop through each track
    trtmp = A(:, ismember(A(nrows,:),j));  % objects that are part of track j
    if(size(trtmp,2) < 2)
        sh = [sh j];
    end
end
utrk = setdiff(utrk, sh);

Ntr = length(utrk);  % number of tracks
minfr = min(A(nrows-1,:));  % lowest frame no. (probably 1 if A is an 
      % object matrix, 2 if a displacement matrix)
maxfr = max(A(nrows-1,:));  % highest frame no.

outA = NaN(maxfr-minfr+1,Ntr);  % Initialize output matrix as NaN

for j = 1:length(utrk)
    % loop through each track
    trtmp = A(:, ismember(A(nrows,:),utrk(j)));  % objects that are part of track j
    minfrj = min(trtmp(nrows-1,:));  % min frame number in track utrk(j)
    maxfrj = max(trtmp(nrows-1,:));  % max frame number in track utrk(j)
    % As in msdtr_rp and other things, pad with NaNs for missing frames
    row1 = nanpad(trtmp(1,:), trtmp(nrows-1,:));
    row2 = nanpad(trtmp(2,:), trtmp(nrows-1,:));
    outA(minfrj - minfr + 1 : maxfrj - minfr + 1, 2*j-1) = transpose(row1);
       % All the 'first row' values -- x or displacement magnitude
    outA(minfrj - minfr + 1 : maxfrj - minfr + 1, 2*j) = transpose(row2);
       % All the 'second row' values -- y or displacement angle
end

outf = fopen(fname, 'w');

for k = 1:(maxfr-minfr+1)
    % Loop through all frames, write file
    for j = 1:length(utrk)
        if ~isnan(outA(k,j))
            fs = sprintf('%.2f \t', outA(k,j));
        else
            fs = sprintf(' \t');
        end
        fprintf(outf, fs);
    end
    fprintf(outf, '\n');
end


fclose(outf);



function padvec = nanpad(spvec, fmvec)
% pads spvec with NaNs based on fmvec

allfms = fmvec(1):fmvec(end);
padvec = zeros(size(allfms));
notmissing = ismember(allfms, fmvec); % find missing frames
padvec(notmissing) = spvec;
padvec(padvec == 0) = NaN;