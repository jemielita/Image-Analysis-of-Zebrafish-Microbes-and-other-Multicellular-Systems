% plot_gut_1Dintensity.m
% 
% Plots the output of 1D "projections" of bacterial fluorescence intensity
% along the zebrafish gut, previously analyzed from SPIM images.
% Creates 3D line plots (intensity vs. "x" and time) and surface plots;
% Prints surface plots as PNG images (optional)
%
% Asks user for .mat file names -- a series of MAT 
%   files, "Analysis_ScanXX.dat," where XX is the scan number; 
%   in each MAT file is a cell array regFeatures that contains 
%   green fluorescence (cell 1) and red fluorescence (cell 2)
%   data.  In each cell, elements 2:end are the intensity values
%   in a range of intensity bins (so summing gives the total 
%   intensity).
%
% Inputs
% timeinfo : a two element array, with the starting times of the green and
%           red bacteria inoculations, respectively, e.g. [0 3] for GFP
%           starting at t=0 and TdTomato starting at 3 hrs.
%           Leave empty to be prompted
% threshCutoff : cutoff bin number for summing fluorescence intensity at
%           each position (e.g. 10).  Can be a 2-element array for [green
%           red]
% intensitybins : intensity values of bins used to make the regFeatures array
% timestep : time interval between scans, hours (typically 0.33)
% boxwidth : box width for gut positions, microns (typically 5)
% maxplotpos : plot only points with x-position <= this (microns); default
%              Inf
% greenredintensity : either 
%           (i) the total intensity of green and red bacteria,
%               summed over all px, as a two-element array; intensities are then
%               converted to an approximate number of bacteria, 
%           or
%           (i) the ratio of the intensities of a green / red bacterium; all
%               red intensities are multiplied by this factor to make
%               inferences of bacterial density equivalent 
%           Default: 1
%           Oct. 15, 2012: measured this to be approx. [80 11], i.e. ratio = 7
%           (see notes)
% bacteriavolume : typical single bacterium volume, px, for conversion of
%           above-threshold pixels to number of bacteria.  
%           e.g. 5*2*2/0.165/0.165/1 = 734 for 5x2x2 um bacteria with
%           0.165*0.165*1 um^3 voxels
%           Default 1 (no conversion)
% surfplotfilenamebase : file name for saving surface plots (via print).  
%           Will add '_green', '_red', and '.png');  
%           Leave empty to skip printing image (default) 
%
% Outputs
% data_all : all position, time, intensity data in a structured array.  
%            data_all(j).x = x array, microns, for time point j
%            data_all(j).green = green intensity
%            data_all(j).red = red intensity
%            data_all(j).time = time value, hrs., repeated to be same
%                        length as other fields
%
% uses
% getnumfilelist.m to get .mat file names
% fitline.m for fitting to exponential growth
%
% based on Matt's "plotData.m"
%
% Raghuveer Parthasarathy
% Sept. 16, 2012
% last modified Oct. 15, 2012

function data_all = plot_gut_1Dintensity(timeinfo, threshCutoff, intensitybins, timestep, ...
    boxwidth, maxplotpos, greenredintensity, bacteriavolume, surfplotfilenamebase)


% get file name from list
% [matfilebase, min_scan, max_scan, formatstr, FileName1, FileName2, datadir ext] = ...
%     getnumfilelist;
% disp(datadir)

datadir = 'H:\Aeromonas_Oct18_take2\fish2\gutOutline';
matfilebase = 'Analysis_Scan';
min_scan = 1;
max_scan = 49;
ext = '.mat';
formatstr = '%d';

NtimePoints = max_scan-min_scan+1;
presentdir = pwd;
cd(datadir)

if ~exist('maxplotpos', 'var')  || isempty(maxplotpos)
    maxplotpos = Inf;
end
if ~exist('greenredintensity', 'var')  || isempty(greenredintensity)
    greenredintensity = 1;
end
if ~exist('bacteriavolume', 'var')  
    bacteriavolume = 1;
end
if ~exist('surfplotfilenamebase', 'var')  
    surfplotfilenamebase = [];
end
if length(threshCutoff)==1
    threshCutoff = [threshCutoff threshCutoff];  % use the same bin for both color channels
end

% Note the time delay, and create a string for figure labels
if isempty(timeinfo)
    timeinfo = zeros(1,2);
    dlg_title = 'Starting points'; num_lines= 1;
    prompt = {'GFP start time (hrs.)', 'RFP start time (hrs.)'};
    def     = {num2str(0), num2str(0)};  % default values
    answer  = inputdlg(prompt,dlg_title,num_lines,def);
    timeinfo(1) = str2double(answer(1));
    timeinfo(2) = str2double(answer(2));
    
    %timeinfo(1) = input('GFP start time (hrs.): ');
    %    timeinfo(2) = input('RFP start time (hrs.): ');
end
dataTitle = sprintf('GFP%d;RFP%d', timeinfo(1), timeinfo(2));
tdelay = abs(diff(timeinfo)); % difference between inoculation start times, hr.

scrsz = get(0,'ScreenSize');
hFig_green = figure('Position',[1+500 scrsz(4)/2 - 300 scrsz(3)/2 scrsz(4)/2]);
hold on
hFig_red = figure('Position',[1+300 scrsz(4)/2 - 300 scrsz(3)/2 scrsz(4)/2]);
hold on

%hAxis_green = axes('Parent', hFig_green);
%set(hAxis_green, 'ZLim', [0 0.02*10e6]);
%hAxis_red = axes('Parent', hFig_red);
%set(hAxis_red, 'ZLim', [0 0.02*10e6]);

%%
% Put position and intensity values in a structured array -- will put into
% a matrix later, but for now, lengths may not be the same for all time
% points.  See header comments for structure fields

maxgreen = zeros(1,NtimePoints);  % max intensity at each time point
maxred = zeros(1,NtimePoints);
totalgreen = zeros(1,NtimePoints);  % total intensity at each time point
totalred = zeros(1,NtimePoints);
NtimePoints
for j=1:NtimePoints
    % Load data
    matfile = strcat(matfilebase, sprintf(formatstr,j+min_scan-1), ext);
    load(matfile)
    xpos = boxwidth*((1:length(regFeatures{1,1}))' - 0.5); % position along gut, microns (column vector)
    % Cutting off all pixel intensities below a certain threshold (bin)
    gr_bincounts = regFeatures{1,1}(:,threshCutoff(1)+1:end);  % +1 since first element is mean
    ibins_gr = repmat(intensitybins(threshCutoff(1):end), size(gr_bincounts,1),1);
    red_bincounts = regFeatures{2,1}(:,threshCutoff(2)+1:end);
    ibins_red = repmat(intensitybins(threshCutoff(2):end), size(red_bincounts,1),1);
    thisLine_green = sum(gr_bincounts.*ibins_gr,2);  % total intensity at each position -- counts * bin values
    thisLine_red   = sum(red_bincounts.*ibins_red,2);
    if length(greenredintensity)==1
        % Multiply by green / red intensity scaling factor:
        thisLine_red = thisLine_red * greenredintensity;
    else
        % convert to number of bacteria
        thisLine_green = thisLine_green / greenredintensity(1) / bacteriavolume;
        thisLine_red = thisLine_red / greenredintensity(2) / bacteriavolume;
    end
    % save in structured array
    data_all(j).x = xpos(xpos<=maxplotpos);
    data_all(j).green = thisLine_green(xpos<=maxplotpos);
    data_all(j).red = thisLine_red(xpos<=maxplotpos);
    data_all(j).time = j*timestep*ones(size(data_all(j).x));
    maxgreen(j) = max(data_all(j).green);
    maxred(j) = max(data_all(j).red);
    totalgreen(j) = sum(data_all(j).green);
    totalred(j) = sum(data_all(j).red);
    
    j
end


%% Growth rate from 'exponential growth phase'
% fit to intensity = I0*exp(k*time)
dlg_title = 'Fit range'; num_lines= 1;
prompt = {'Start time for exp. fit (hrs. after 1st loaded scan)', 'End time for exp. fit (hrs. after 1st loaded scan)'};
def     = {'0', num2str(7)};  % default values
answer  = inputdlg(prompt,dlg_title,num_lines,def);
logfitrange = [str2double(answer(1)) str2double(answer(2))];
% fs = sprintf('exponential fit to hard-wired range!  t = %d hours', logfitrange); disp(fs);
timehours = timestep*(0:NtimePoints-1);
t_to_fit = timehours(timehours>=logfitrange(1) & timehours<=logfitrange(2) & totalgreen > 0);
gr_to_fit = totalgreen(timehours>=logfitrange(1) & timehours<=logfitrange(2) & totalgreen > 0);
[A, sigA, k_green, sigk_green] = fitline(t_to_fit, log(gr_to_fit));
I0_green = exp(A);
t_to_fit = timehours(timehours>=logfitrange(1) & timehours<=logfitrange(2) & totalred > 0);
red_to_fit = totalred(timehours>=logfitrange(1) & timehours<=logfitrange(2) & totalred > 0);
[A, sigA, k_red, sigk_red] = fitline(t_to_fit, log(red_to_fit));
I0_red = exp(A);
fs = sprintf('  Growth rate green = %.2f +/- %.2f 1/hr', k_green, sigk_green); disp(fs);
fs = sprintf('  Growth rate red = %.2f +/- %.2f 1/hr',  k_red, sigk_red); disp(fs);
fs = sprintf('  Ratio of initial intensities (I_0) = %.2e', min([I0_green/I0_red I0_red/I0_green])); disp(fs);
fs = sprintf('  e^(-k_max t_delay) = %.2e', exp(-max([k_red k_green])*tdelay)); disp(fs)

%% Color maps
% For surface plots
cmaprows = 0:255;
% a green colormap that starts black, rapidly saturates green, goes to almost white
cmapgreen = zeros(length(cmaprows),3);
cmapgreen(:,2) = min(10*cmaprows/max(cmaprows), ones(size(cmaprows)));
cmapgreen(:,3) = max(cmaprows/max(cmaprows) - 0.1, zeros(size(cmaprows)));
cmapgreen(:,1) = max(1.75*cmaprows/max(cmaprows) - 1, zeros(size(cmaprows)));

% a red colormap that starts black, rapidly saturates red, goes to yellow
cmapred = zeros(length(cmaprows),3);
cmapred(:,1) = min(10*cmaprows/max(cmaprows), ones(size(cmaprows)));
cmapred(:,2) = min(2*cmaprows/max(cmaprows), ones(size(cmaprows)));
cmapred(:,3) = max(1.75*cmaprows/max(cmaprows) - 1, zeros(size(cmaprows)));

% for line-by-line plots
cData_green = summer(ceil(2*NtimePoints));
cData_red = hot(ceil(2*NtimePoints));


%% Make figures

%% Line-by-line plots
% Plot all green data, line-by-line
figure(hFig_green); 
for j=1:NtimePoints
    plot3(data_all(j).x, data_all(j).time, data_all(j).green, 'Color', cData_green(j,:));
end
% Plot all red data, line-by-line
figure(hFig_red);
for j=1:NtimePoints
    plot3(data_all(j).x, data_all(j).time, data_all(j).red, 'Color', cData_red(j,:));
end
viewangle = [-10 50];  % alt, az

figure(hFig_green);
plotTitleGreen = strcat(dataTitle, ': GFP');
figurethings(hFig_green, plotTitleGreen, viewangle);
agreen = axis;

figure(hFig_red);
plotTitleRed = strcat(dataTitle, ': TdTomato');
figurethings(hFig_red, plotTitleRed, viewangle);

% Axis ranges
% make axis ranges the same
maxgreenall = max(maxgreen);
maxredall = max(maxred);

sameax = [0 min([maxplotpos agreen(2)]) 1 NtimePoints*timestep 0 1.1*max([maxgreenall maxredall])];
figure(hFig_green);
axis(sameax)
figure(hFig_red);
axis(sameax)

% surface plots
% Deal with simplest case that all position values are the same at each
% time point; abandon if this isn't true
try
    hFig_green_surf = figure('name', 'GFP surface');
    surf([data_all.x], [data_all.time], [data_all.green])
    colormap(cmapgreen)
    shading interp
    figurethings(hFig_green_surf, plotTitleGreen, viewangle);
    axis(sameax)
    
    hFig_red_surf = figure('name', 'RFP surface');
    surf([data_all.x], [data_all.time], [data_all.red])
    colormap(cmapred)
    shading interp
    figurethings(hFig_red_surf, plotTitleRed, viewangle);
    axis(sameax)
    
    % Print figures
    if ~isempty(surfplotfilenamebase)
        set(hFig_green_surf, 'PaperPosition', [0.25 2.5 6 4])  % to get a decent aspect ratio
        print(hFig_green_surf, '-dpng', strcat(surfplotfilenamebase, '_green.png'), '-r300')
        set(hFig_red_surf, 'PaperPosition', [0.25 2.5 6 4])  % to get a decent aspect ratio
        print(hFig_red_surf, '-dpng', strcat(surfplotfilenamebase, '_red.png'), '-r300')
    end
catch
    disp('ERROR: surface plots probably failed because of differing x values.')
    disp('Try again with smaller maxplotpos.')
end

% Total intensity plot(s)
figure; plot(timestep*(1:NtimePoints), totalgreen, 'ko', 'markerfacecolor', [0.2 0.8 0.4]);
hold on
plot(timestep*(1:NtimePoints), totalred, 'kd', 'markerfacecolor', [0.8 0.4 0.2]);
xlabel('Time, hrs.')
if length(greenredintensity)==1
    ylabel('Total Intensity, a.u.')
else
    ylabel('Total Number of Bacteria')
end    
title(dataTitle, 'interpreter', 'none')

% Total intensity, log scale
figure('name', 'Total intensity, log scale');
semilogy(timestep*(1:NtimePoints), totalgreen, 'ko', 'markerfacecolor', [0.2 0.8 0.4]);
hold on
semilogy(timestep*(1:NtimePoints), totalred, 'kd', 'markerfacecolor', [0.8 0.4 0.2]);
xlabel('Time, hrs.')
if length(greenredintensity)==1
    ylabel('Total Intensity, a.u.')
else
    ylabel('Total Number of Bacteria')
end    
title(dataTitle, 'interpreter', 'none')
semilogy(timehours(timehours>=logfitrange(1) & timehours<=logfitrange(2)), I0_green*exp(k_green*timehours(timehours>=logfitrange(1) & timehours<=logfitrange(2))), '-', 'color', 0.7*[0.8 1 0.8])
semilogy(timehours(timehours>=logfitrange(1) & timehours<=logfitrange(2)), I0_red*exp(k_red*timehours(timehours>=logfitrange(1) & timehours<=logfitrange(2))), '-', 'color', 0.7*[1 0.8 0.8])
% scale the earlier data set by e^(-kt_delay)
if timeinfo(1)>timeinfo(2)
    % first red, then green; so scale red
    semilogy(timehours(timehours>=logfitrange(1) & timehours<=logfitrange(2)), exp(-k_red*tdelay)*I0_red*exp(k_red*timehours(timehours>=logfitrange(1) & timehours<=logfitrange(2))), 'r:')
else
    % first green, then red; so scale red
    semilogy(timehours(timehours>=logfitrange(1) & timehours<=logfitrange(2)), exp(-k_green*tdelay)*I0_green*exp(k_green*timehours(timehours>=logfitrange(1) & timehours<=logfitrange(2))), 'g:')
end    

% Ratio of total intensities
figure; plot(timestep*(1:NtimePoints), totalgreen./totalred, 'ko', 'markerfacecolor', [0.4 0.5 0.4]);
hold on
xlabel('Time, hrs.')
ylabel('Ratio of green/red bacteria')
title(dataTitle, 'interpreter', 'none')

cd(presentdir)


    function figurethings(hFig, plotTitle, viewangle)
        figure(hFig)
        title(plotTitle, 'interpreter', 'none', 'FontSize', 16);
        xlabel('Position, \mum')
        ylabel('Time, hrs.')
        zlabel('Intensity, a.u.')
        view(viewangle);
    end

end

