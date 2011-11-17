% TIFFseries.m
%
% Function to read a series images from multiple TIFF files or a single 
%   multipage TIFF and manipulate them -- cropping,
%   exporting an AVI, exporting cropped TIFFs, etc.
% For multiple files, file names must all be the same *length,* with 
%     the sequence number indicated as trailing digits, e.g.
%     seq001.tif, seq002.tif, ... seq012.tif, ...seq123.tif
% Can read 8- or 16-bit TIFF images.  
% Can read grayscale or COLOR (3-layer RGB) images.
% TIFF output can be 8 or 16-bit, and can be rescaled so max intensity =
%     full range.  (Doesn't consider each color layer separately)
% AVI output must be 8-bit, and can be rescaled so max intensity = 255.
% Works with "save-series" and other camera control programs
% Optional input argument: cropping rectangle [xmin ymin width height];
%
% Two image reading possibilities:
% (1) Read and store all images in one object -- fast, but needs lots of memory
% (2) Read each image as needed, without saving it.  (Output outA = [])
%
% Output: series of (cropped) TIFF images.
% Two output possibilities:
% (1) one structured array -- structured to allow easy transfer to AVI
%    outA(k).cdata = frame #k (if grayscale)
%    outA(k).colormap = colormap
% (2) a matrix whose "depth" is the sequence of frames (typically a 3D
%    array of frames).
%
% Option:  Do particle tracking, using im2obj_rp.m and dependent functions.
%   Must first have determined objsize, threshold, e.g. with testthresh
%   Output:  object matrix (objs), as usual -- see particle tracking
%   functions.  If no tracking, objs = [].
%
% Raghuveer Parthasarathy
% last modified July 12, 2011
%    Sept. 20, 2010: Use getnumfilelist.m to get information on files to
%    load.
%    July 26, 2010 (convert 12-bit images to 8-bit)
%    June 6, 2011 (minor changes to tracking options)
%    July 10, 2011: Allow multipage TIFF input
%
% Mike Taormina
% last modified November 16, 2011
%   November 16, 2011: Free speed up - Use 'Info' for reading multipage TIFF files (as
%   http://blogs.mathworks.com/steve/2009/04/02/matlab-r2009a-imread-and-multipage-tiffs/).
%   This is probably noticable when dealing with thousands of images, e.g.,
%   for high speed video.  The prevented bottleneck is not tied to the resolution of
%   the images, just the number of frames.


function [outA objs] = TIFFseries(rect)


disp(' ');
disp('TIFFseries.m');
disp('   Suggestion: first change to images sequence directory.');
disp(' ');

firstdir = pwd;  % present directory


% -----------------------------------------------------------------------
% Load images: Get File Names, etc., from getnumfilelist
% Can be multipage TIFF
[fbase, frmin, frmax, formatstr, FileName1, FileName2, PathName1 ext ismultipage] = ...
    getnumfilelist;
% frmin and frmax are returned as 1 and Nframes, resp., for multi-page TIFFs
% If it's a multi-page TIFF, allow a subset of the frames to be considered
if ismultipage
    prompt = {'First frame to consider', ...
        'Last frame to consider'};
    dlg_title = 'Series option'; num_lines= 1;
    def     = {num2str(frmin), num2str(frmax)};  % default values
    answer  = inputdlg(prompt,dlg_title,num_lines,def);
    frmin = round(str2double(answer(1)));
    frmax = round(str2double(answer(2)));
end

% -----------------------------------------------------------------------
% Load images: Get Options
%
prompt = {'Images are 12-bit; convert to 8-bit? (1==yes)', ...
    '(0) Load all images into matrix, or (1) consider each separately:', ...
    'Analyze every "k-th" image; k = ', ...
    'Crop images?  (0==no, 1==yes):', ...
    'Output TIFFs to file (0==no, 1==yes):', ...
    'Output AVI to file (0==no, 1==yes) -- only if loading all to matrix:', ...
    'Output data as 3D matrix of frames, not structure? (0==no, 1==yes):'};
dlg_title = 'Series option'; num_lines= 1;
def     = {'0', '0', '1','0','0','0', '1'};  % default values
answer  = inputdlg(prompt,dlg_title,num_lines,def);
convert12to8opt = logical(str2double(answer(1)));
loadallopt = ~logical(str2double(answer(2)));  
Nskip = str2double(answer(3));
cropopt = logical(str2double(answer(4)));
TIFFopt = logical(str2double(answer(5)));
AVIopt = logical(str2double(answer(6)));
matrix3Dopt = logical(str2double(answer(7)));

if ~loadallopt
    outA = [];
end

if AVIopt && ~loadallopt
    disp('WARNING: Cannot export AVI unless full array loaded!')
    disp('Not exporting AVI!')
    AVIopt = false;
end

% total number of frames to consider
Noutframes = length(frmin:Nskip:frmax);


% -----------------------------------------------------------------------
% Load images:  Load first image
if ismultipage
    Fr1 = imread(strcat(fbase, ext), frmin);
    allinfo = imfinfo(strcat(fbase, ext));  % information for all images in the stack
    info1 = allinfo(1);
else
    Fr1 = imread(FileName1);
    info1 = imfinfo(FileName1, 'tif');
end
if convert12to8opt
    % user says it's a 12-bit image; convert to 8-bit (rescale)
    % First make sure original is 16 bit file
    imclass = class(Fr1); 
    if ~strcmp(imclass, 'uint16')
        disp('Error!  Original image file should be 16 bit!')
        disp('Press Control-C');
        pause
    else
        Fr1 = uint8(double(Fr1)*255/4095); % rescale 12-bit to 8-bit
    end
end
imclass = class(Fr1);  % Determine the class -- uint8 or uint16
fs = sprintf('Image class: %s', imclass); disp(fs);
if ~or(strcmp(imclass, 'uint8'), strcmp(imclass, 'uint16'))
    disp('Image must be 8 or 16 bit!  Press Control-C');
    pause
end

s = size(Fr1);
iscolor = (length(s)==3);  % TRUE if the image is color (3 layers)
if isfield(info1, 'DateTime')
    % Date Stamp saved as description of TIFF
    ds1 = {info1.DateTime};
elseif isfield(info1, 'ImageDescription')
    % Date Stamp saved as description of TIFF
    ds1 = {info1.ImageDescription};
else
    % Date Stamp NOT saved as description; use file mod date
    ds1 = {['FMD: ' info1.FileModDate]};
end

% -----------------------------------------------------------------------
% Region to Crop
if cropopt
    % Determine cropping region, based on first image
    disp('   Select the region to keep...');
    % For ease of cropping display, scale the image
    dFr1 = double(Fr1);
    scaleFr1 = uint8((dFr1 - min(dFr1(:)))*255.0 / (max(dFr1(:)) - min(dFr1(:))));
    if (nargin > 0)
        % cropping rectangle is specified
        cropFr1 = imcrop(scaleFr1, rect);
    else
        % interactive cropping rectangle
        [cropFr1,rect] = imcrop(scaleFr1);
    end
    scrop = size(cropFr1);  % size of the cropped image
else
    rect = [1 1 (s(2)-1) (s(1)-1)];
    scrop = s;  % size of the cropped image
end
fs = sprintf('Cropping rectangle: %d % d %d %d', rect); disp(fs);

% -----------------------------------------------------------------------
% Options for exporting TIFFs
if TIFFopt
    fbaseout = strcat(fbase, '_out_');
    prompt = {'Enter the BASE output filename (will add frame no., .tif):',...
        'if 16-bit, convert to 8-bit? (1==yes)', ...
        'Re-scale max. intensity to full range? (only if full matrix loaded) (1==yes)'};
    dlg_title = 'Output TIFF parameters'; num_lines= 1;
    def     = {fbaseout, '0', '0'};  % default values
    answer  = inputdlg(prompt,dlg_title,num_lines,def);
    fbaseout = char(answer(1));
    TIFF8bit = logical(str2double(answer(2))) && strcmp(imclass, 'uint16');
    % already checked that if not 8-bit, image is 16-bit
    % Note that TIFF8bit is set to false if we already have 8bit TIFFs
    TIFFscaleint = logical(str2double(answer(3)));

    if TIFFscaleint && ~loadallopt
        disp('WARNING: Cannot rescale intensity unless full array loaded!')
        disp('Not rescaling!')
        TIFFscaleint = false;
    end
end


% -----------------------------------------------------------------------
% Options for particle tracking
prompt = {'Track objects (w/ im2obj_rp etc) (1==yes):',...
    'if yes: object size (px)', ...
    'if yes: threshold', ...
    'if yes: Track *single particle center of mass* (1==yes)'};
dlg_title = 'Particle tracking'; num_lines= 1;
def     = {'0', '8', '0.997', '0'};  % default values
answer  = inputdlg(prompt,dlg_title,num_lines,def);
trackopt = logical(str2double(answer(1)));
objsize = str2double(answer(2));
threshold = str2double(answer(3));
comtrackopt = logical(str2double(answer(4)));

objs = [];

% Don't preallocate memory for tracking, since number of particles is
% unknown

% -----------------------------------------------------------------------
% if loading all, preallocate memory for the cropped images
if loadallopt
    if iscolor
        outA = struct('cdata',zeros(scrop(1),scrop(2),3,Noutframes,imclass),...
            'colormap', zeros(256,3,Noutframes));
    else
        outA = struct('cdata',zeros(scrop(1),scrop(2),Noutframes,imclass),...
            'colormap', zeros(256,3,Noutframes));
    end
end

% -----------------------------------------------------------------------
% Load frames.
% For each, if desired,
%    crop
%    save TIFF

% preallocate memory for the description strings -- max 400 char.
ds = repmat({cell(1,400)},Noutframes,1); 
maxAk = zeros(1,Noutframes);
outk = 1;  % index for the number of frames
progtitle = 'Progress loading images...'; 
progbar = waitbar(0, progtitle);  % will display progress
for k=frmin:Nskip:frmax,
    if (k==frmin)  % first frame
        tempoutA = Fr1;
        ds(1) = ds1;
    else
        if ismultipage
            tempoutA = imread(strcat(fbase, ext), k, 'Info',allinfo); % image
            infoA = allinfo(k);
        else
            framestr = sprintf(formatstr, k);
            FileName = strcat(fbase, framestr, '.tif');
            tempoutA  = imread(FileName, 'tif');  % image
            infoA = imfinfo(FileName, 'tif');
        end
        if convert12to8opt
            % user says it's a 12-bit image; convert to 8-bit (rescale)
            tempoutA = uint8(double(tempoutA)*255/4095);
        end
        if isfield(info1, 'DateTime')
            % Date Stamp saved as description of TIFF
            ds(outk) = {infoA.DateTime};
        elseif isfield(info1, 'ImageDescription')
            % Date Stamp saved as description of TIFF
            ds(outk) = {infoA.ImageDescription};
        else
            % Date Stamp NOT saved as description; use file mod date
            ds(outk) = {['FMD: ' infoA.FileModDate]};
        end
    end
    if cropopt
        % crop image
        tempoutA = imcrop(tempoutA,rect);  % cropped image
    end
    maxAk(outk) = max(tempoutA(:));  % maximal intensity
    if loadallopt
        % put into large matrix
        outA(outk).cdata = tempoutA;
    else
        % Don't need to do anything, but write TIFFs if desired
        if TIFFopt
            % save image as TIFF
            cd(PathName1)
            if TIFF8bit
                TIFFoutA = uint8(double(tempoutA)*255/65535);
            else
                TIFFoutA = tempoutA;
            end
            framestr = sprintf(formatstr, (k-1)*Nskip + frmin);
            OutFileName = strcat(fbaseout, framestr, '.tif');
            imwrite(TIFFoutA, OutFileName, 'tif', 'Description', char(ds(k)));
            cd(firstdir)  % Return to the original directory
        end
    end
    if trackopt
        % Track data, using function im2obj_rp, fo4_rp, bpfilter
        if comtrackopt
            %  find image center of mass (for single 'ring' particles)
            tempobjs = fcm_rp(tempoutA, objsize, threshold);
        else
            % usual tracking
            tempobjs = im2obj_rp(tempoutA, objsize, threshold);
        end
        tempobjs(5,:) = outk;  % frame number -- note that this is outk, not k
             % Note that tempobjs will have as many 
             % columns as there are objects in the frame
        objs = [objs tempobjs];
    end
    outk = outk+1;
    waitbar((k-frmin)/(frmax-frmin), progbar, progtitle);
end
close(progbar);
maxA = double(max(maxAk(:)));  % maximal intensity over all frames, all color channels

% Information, including Date Stamps
disp(' ');
fs = sprintf('%s (base file name)', fbase); disp(fs);
fs = sprintf('%d output frames, from input frames %d to %d, increment %d', ...
    Noutframes, frmin, frmax, Nskip); disp(fs);
fs = sprintf('Initial Datestamp: %s', char(ds(1))); disp(fs);
fs = sprintf('Final Datestamp:   %s', char(ds(Noutframes))); disp(fs);


% -----------------------------------------------------------------------
% Export TIFFs -- if desired and if not done "frame by frame" above.  Doing
% now allows rescaling intensity
if TIFFopt && loadallopt
    cd(PathName1)
    for k=1:Noutframes,
        % export each frame
        if TIFFscaleint
            % Scale the max intensity to full range
            doA = double(outA(k).cdata);
            if (TIFF8bit || strcmp(imclass, 'uint8'))
                TIFFoutA = uint8(doA*255/maxA);
            else
                TIFFoutA = uint16(doA*65535/maxA);
            end
        else
            if TIFF8bit
                TIFFoutA = uint8(double(outA(k).cdata)*255/65535);
            else
                TIFFoutA = outA(k).cdata;
            end
        end
        framestr = sprintf(formatstr, (k-1)*Nskip + frmin);
        OutFileName = strcat(fbaseout, framestr, '.tif');
        imwrite(TIFFoutA, OutFileName, 'tif', ...
            'Description', char(ds(k)));
    end
    cd(firstdir)  % Return to the original directory
end


% -----------------------------------------------------------------------
% Export AVI
% Note that AVI output image must be 8-bit -- convert if necessary
if AVIopt
    cd(PathName1)
    % Ensure 8-bit color map
    gray8 =zeros(256,3);
    for j=1:256
        gray8(j,1:3) = (j-1)/256.0;
    end
    % A non-linear gray colormap
    gray8nonlin =zeros(256,3);
    for j=1:256
        gray8nonlin(j,1:3) = sqrt(j-1)/sqrt(256);
    end
    % An 8-bit 'hot' colormap
      hot8 = ones(256,3);
      hot8(1:96,1) = (1:96)/96;
%      hot8(1:12,1) = zeros(12,1);
%      hot8(13:96,1) = (1:84)/84;
      hot8(1:96,2) = zeros(96,1);
      hot8(97:192,2) = (1:96)/96;
      hot8(1:192,3) = zeros(192,1);
      hot8(193:256,3) = (1:64)/64;
    % Output parameters
    prompt = {'Enter the output filename (will add .avi):', ...
        'Enter the output frames per second:', ...
        'Enter the output compression type:', ...
        'Enter the output compression quality (0-100)', ...
        'Re-scale max. intensity to full range? (1==yes)'};
    dlg_title = 'Output AVI parameters'; num_lines= 1;
    def     = {fbase, '10', 'none', '100', '0'};  % default values
    answer  = inputdlg(prompt,dlg_title,num_lines,def);
    Aoutfiletemp = char(answer(1));
    Aoutfile = strcat(Aoutfiletemp, '.avi');  % output filename
    fps = str2double(answer(2));
    newcompr = char(answer(3));
    newqual = str2double(answer(4));
    AVIscaleint = logical(str2double(answer(5)));
    if (newqual > 100.0)
        newqual = 100; end
    if (newqual < 1.0)
        newqual = 1; end
    if AVIscaleint
        % scale so max intensity is 255
        for k=1:Noutframes
            outA(k).cdata = double(outA(k).cdata) * 255 / maxA;
            % logarithmic intensity
            %   outA(k).cdata = log(double(outA(k).cdata)+1) * 255 / log(maxA+1);
        end
    else
        % if necessary, convert to 8-bit
        for k=1:Noutframes
            if strcmp(imclass, 'uint16')
                outA(k).cdata = uint8(double(outA(k).cdata) * 255 / 65535);
            end
        end
    end
    for k=1:Noutframes
        outA(k).colormap = gray8; % hot8 %jet;
    end
    disp(' ')
    disp('   Writing file (wait for "done" indication...)');
    movie2avi(outA, Aoutfile, 'compression', newcompr, 'quality', newqual, 'fps', fps);
    disp('      ... done.');
    cd(firstdir)  % Return to the original directory
end

% ----------------------------------------------------------------------
% Convert structure into output double precision 3D array
% ignore colormap

doutA = [];
if matrix3Dopt && loadallopt
    if iscolor
        doutA = zeros(scrop(1),scrop(2),3, Noutframes,imclass);
        for k=1:Noutframes
            doutA(:,:,:,k)=outA(k).cdata;
        end
    else
        doutA = zeros(scrop(1),scrop(2), Noutframes,imclass);
        for k=1:Noutframes
            doutA(:,:,k)=outA(k).cdata;
        end
    end
end
outA = doutA;  % destroys structured array

% ----------------------------------------------------------------------

cd(firstdir);  %Return to original directory

close all

    