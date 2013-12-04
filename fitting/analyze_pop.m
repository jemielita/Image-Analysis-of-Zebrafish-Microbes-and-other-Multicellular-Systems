
% Analyze old (2012) co-inoculated red & green Aeromonas data, from Oct.
% 18, 2012 (fish 1-4) and May 23, 2012 (fish 1)
%
% Raghu Parthasarathy
% Oct. 11-13, 2013


late_time_option = true;
t_offset = 7;  % approximate time from the start of inoculation, hrs.
fs = sprintf('Using t_offset = %d hrs.', t_offset); disp(fs);
halfbox = 2;  % +/- 2 time points for boxcar standard deviation for logistic growth fit

%% Load Oct. 18, 2012 data
%cd '/Users/raghu/Documents/Experiments and Projects/Zebrafish Microbiota and Gut/Oct 18 2012 alldata'
%load('allParameters.mat', 'totPop');

% Data is in 'popTot'
% each cell is one fish

Nfish1 = length(totPop);
for f=1:Nfish1
    temp = totPop{f};
   % allfish(f).t = temp(:,3);   % time from start of imaging, hrs
    allfish(f).pgreen = temp(:,1);   % Aeromonas GFP population
    allfish(f).pred = temp(:,2);   % Aeromonas dTomato population
    allfish(f).t = 0.33*(1:length(allfish(f).pgreen));
end


%% Load May 23, 2012, fish 1
cd '/Users/raghu/Documents/Experiments and Projects/Zebrafish Microbiota and Gut/May23 2012 alldata'
load('populationData.mat', 'popTot');
% Data is in 'popTot'
% only fish 1 is co-inoculated
Nfish2 = 1;
temp = popTot{1};
allfish(Nfish1+Nfish2).t = temp(:,3);   % time from start of imaging, hrs
allfish(Nfish1+Nfish2).pgreen = temp(:,1);   % Aeromonas GFP population
allfish(Nfish1+Nfish2).pred = temp(:,2);   % Aeromonas dTomato population

Nfish = Nfish1+Nfish2;
r = zeros(Nfish,2);  % col 1 = red, col2 = green
K = zeros(Nfish,2);  % col 1 = red, col2 = green
N0 = zeros(Nfish,2);  % col 1 = red, col2 = green


% ranges of parameters for logistic fit -- see fit_logistic_growth.m
LB = [0 0 -1 1];
UB = [inf, inf, 0, inf];

for f=1:Nfish
    t = allfish(f).t;
    pred = allfish(f).pred;
    pgreen = allfish(f).pgreen;
    figure; semilogy(t+t_offset, pred, 'o', 'color', [0.6 0 0], 'markerfacecolor', [0.9 0.4 0.1], 'markersize', 10)
    hold on
    semilogy(t+t_offset, pgreen, 'o', 'color', [0.0 0.7 0.2], 'markerfacecolor', [0.0 1.0 0.2], 'markersize', 10)
    a = axis;
    axis([min(t)+t_offset max(t)+t_offset a(3) a(4)])
    
    % Corrections "by hand" for particular fish
    if f==1
        % red is noisy before t = 2.5 hours
        % could impose cutoff (for red only), or force some N0 value
        % if I manually make the t=2.5hr cutoff, N0 = 362 for red.
        disp('Fish 1: Forcing N0 to be <= 400!  Should look at low time data.')
        UB(4) = 400;
    else
        UB(4) = inf;  % default, as above
    end
    if f==3
        % large dropoff after 14 hours
        disp('Fish 3: consider time <= 14 hrs.')
        tcutoff = 14;
        pred = pred(t<tcutoff);
        pgreen = pgreen(t<tcutoff);
        t = t(t<tcutoff);
    end
    if f==4
        % huge dropoff at large time, and huge delay -- generally poor
        % data, but similar exponential growth in middle period is clear
        disp('Fish 4: consider time 3.75 to 10.25 hrs.')
        tcutoff1 = 3.75;
        tcutoff2 = 10.25;
        pred = pred(t>=tcutoff1 & t<=tcutoff2);
        pgreen = pgreen(t>=tcutoff1 & t<=tcutoff2);
        t = t(t>=tcutoff1 & t<=tcutoff2);
    end
    % fit logistic growth curve
    [r(f,1) K(f,1) , ~, N0(f,1)] = fit_logistic_growth(t, pred, late_time_option, halfbox, [], [], LB, UB);
    semilogy(t+t_offset, N0(f,1)./(N0(f,1)/K(f,1) + (1-N0(f,1)/K(f,1))*exp(-r(f,1).*t)), '-', 'color', [0.6 0.2 0]);
    [r(f,2) K(f,2) , ~, N0(f,2)] = fit_logistic_growth(t, pgreen, late_time_option, halfbox, [], [], LB, UB);
    semilogy(t+t_offset, N0(f,2)./(N0(f,2)/K(f,2) + (1-N0(f,2)/K(f,2))*exp(-r(f,2).*t)), '-', 'color', [0 0.6 0]);
    
    xlabel('Time, hrs.', 'fontsize', 16);
    ylabel('Number of bacteria', 'fontsize', 16)
    set(gca, 'fontsize', 16)    
end

% mean growth rate for each fish (avg. over red, green)
meanr = 0.5*sum(r,2);
meanr
% difference in red, green growth rate for each fish, rel. to mean
diffr = 0.5*abs(r(:,1)-r(:,2))./meanr;
diffr

cd '/Users/raghu/Documents/Experiments and Projects/Zebrafish Microbiota and Gut/Oct 18 2012 alldata'

% set(gcf, 'PaperPosition', [0.25 2.5 5 4])
% print(gcf, '-dpng', 'coinoc_18Oct12_fish3.png', '-r300')
% set(gcf, 'PaperPosition', [0.25 2.5 5 4])
% print(gcf, '-dpng', 'coinoc_23May12_fish1.png', '-r300')
