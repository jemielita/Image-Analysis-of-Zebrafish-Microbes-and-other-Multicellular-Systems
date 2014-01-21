% analyze_2pop.m
%
% USAGE analyze_2pop(totPop)
%       analyze_2pop(totPop,colorScheme)
% INPUT totPop: cell array containing the total population for a number of
%               different fish. Each of these cell arrays contains an array of size
%               number Scans X number Colors containing the total population for each
%               color and time point.
%        colorScheme: (optional, default: 'unique'). Use a different color
%        scheme for each time series ('unique') or use a red and green
%        color scheme for each fish data ('redgreen').
% NOTES
% Script for plotting, analyzing bacterial population data from
% two group "early time" Aeromonas colonization experiments of Summer 2013
% Population numbers from combination of single-particle analysis (early 
%    times only) and segmentation of larger groups (later times)
%
% fits logistic growth, using fit_logistic_growth.m
% Also calls
% logistic_growth_null_2ndpop.m (Null model)
% fit_Lotka_Volterra_same_r.m (Lotka-Volterra model, same r for both
%     groups)
%
% Raghuveer Parthasarathy
% Oct. 7,2013
% last modified Dec. 16, 2013
% Converted into function, Matthew Jemielita, Dec. 17, 2013.
% Load the two-population data
% Array name: totPop
% cd '/Users/raghu/Documents/Experiments and Projects/Zebrafish Microbiota and Gut/Aeromonas early times second pop Sept2013'
% load forRaghu_totalPopulation.mat
% Also in "allParamVariables.mat"

function analyze_2pop(totPop,varargin)
%% 
switch nargin
    case 1
    colorScheme = 'unique';
    case 2
    colorScheme = varargin{1};
    otherwise
        fprintf(2, 'Analyze_2pop take 1 or 2 inputs!\n');
end

Nfish = length(totPop);

numColor = size(totPop{1},2);
fprintf(1, 'Two colors will be analyzed for these scans.\n');


prompt = {'Time step', 'Fit to Lotka-Volterra Model', 'plot lag time vs. growth rate', 'plot universal'};
name = 'Parameters for fitting population data';
numlines = 1;


defaultanswer = {num2str(20/60), num2str(true), num2str(true), num2str(true)};

answer = inputdlg(prompt, name, numlines, defaultanswer);

dt = str2num(answer{1}); %hours between scans
fitLotkaVolterra = str2num(answer{2});
plot_lagtime_and_growthrate = str2num(answer{3});
plotuniversal = str2num(answer{4});

%Setting parameters about the fitting of the data
popFitParam(1).manual_fit = true;
popFitParam(1).alt_fit = [false false];


for nF=1:length(totPop)
   Nscans(nF) = size(totPop{nF},1);
   t{nF} = (1:Nscans(nF))*dt; % time from the start of imaging, hours
    t{nF} = t{nF}';
end

halfboxsize = 5;  % +/- 2 time points for boxcar standard deviation for logistic growth fit

tdelay = 3; % hours
fs = sprintf('Using time delay %.1f hrs. for second inoculation', tdelay); disp(fs)


% row 1,2 = group 1,2
t_lag = zeros(Nfish, numColor);
N0 = zeros(Nfish, numColor);
r = zeros(Nfish, numColor);
K = zeros(Nfish, numColor);
sigt_lag = zeros(Nfish, numColor);
sigN0 = zeros(Nfish, numColor);
sigr = zeros(Nfish, numColor);
sigK = zeros(Nfish, numColor);


% population: fish#, time, group
for nF=1:Nfish
    p{nF} = zeros(length(t{nF}), numColor);
end

logslope = NaN(Nfish, length(t),numColor);


switch colorScheme
    
    case 'unique'
        for nC=1:numColor
            colors{nC} = zeros(Nfish,3);
            
            for nF=1:Nfish
                switch nC
                    case 1
                        colors{1}(nF,:) =0.8*[1, mod(nF,4)/3, mod(nF,2)];
                    case 2
                        colors{2}(nF,:) =0.8*[mod(nF,3)/2, 1-mod(nF,4)/3, mod(nF,2)];
                end
                
            end
        end
        
    case 'redgreen'
        for nF=1:Nfish
            for nC=1:numColor
                switch nC
                    case 1
                        %green
                        colors{1}(nF,:) = [0.2 0.7 0.4];
                    case 2
                        colors{2}(nF,:) = [0.8 0.2 0.4];
                end
            end
        end
                        
end




%Find some other way to set all these variables.
%    manual_fit = true;
%         if manual_fit
%             if nF==3 && k==2
%                 disp('Manually fixing N0, t_lag')
%                 alt_fit = [80 2];  % t_lag, N0
%                 fs = sprintf('  Fish %d, k==%d; t_lag = %.1f hrs., N0 = %d',...
%                     nF, k, alt_fit(1), alt_fit(2)); disp(fs);
%             elseif nF==4 && k==2
%                 % Manually fix t_lag and N0 values; works better than trying to
%                 % alter fit range or weights
%                 disp('Manually fixing N0, t_lag')
%                 alt_fit = [150 5.5];  % t_lag, N0
%                 fs = sprintf('  Fish %d, k==%d; t_lag = %.1f hrs., N0 = %d',...
%                     nF, k, alt_fit(1), alt_fit(2)); disp(fs);
%             else
%                 alt_fit = false;
%             end
%         else
%             alt_fit = false;
%         end
        
        
%% 
% Plot all data and fit to a logistic model with a carrying capacity.

alt_fit = false;
for nF=1:Nfish
    figure('name', sprintf('Pop., Fish %d', nF), 'Position', [50 378 560 420]);
    
    % load experimental data
    p{nF}(:,:) = totPop{nF};

    %Where the logistic curve fit is stored.
    Nth = zeros(numColor,length(t{nF}));

    for nC=1:numColor
        semilogy(t{nF},p{nF}(:,nC), 'o', 'color', 0.8*colors{nC}(nF,:), 'markerfacecolor', colors{nC}(nF,:))
        hold on
        
        ax = axis;
        
        % fit, using fit_logistic_growth.m
        [r(nF,nC), K(nF,nC), N0(nF,nC), t_lag(nF,nC), sigr(nF,nC), sigK(nF,nC), sigN0(nF,nC), sigt_lag(nF,nC)] = ...
            fit_logistic_growth(t{nF},p{nF}(:,nC), alt_fit, halfboxsize);
        
        % Logistic fit curves, for each population
        Nth(nC,:) = logistic_N_t(t{nF}, r(nF,nC), K(nF,nC), N0(nF,nC), t_lag(nF,nC));
        
        % Plot
        semilogy(t{nF}, Nth(nC,:), '-', 'color', 0.5*colors{nC}(nF,:));
    end
    
    semilogy(t{nF}, N0(nF,1)*ones(size(t{nF})), ':', 'color', 0.7*[1 1 1])
    semilogy(t{nF}, K(nF,1)*ones(size(t{nF})), '--', 'color', 0.7*[1 1 1])
    if t_lag(nF,1)>0
        semilogy(t_lag(nF,1)*[1 1], [1 ax(4)], 'k:')
    end
    axis([ax(1) ax(2) 1 ax(4)])
    xlabel('Time from start of imaging, hrs.','fontsize', 18)
    ylabel('Number of bacteria','fontsize', 18)
    title(sprintf('Fish %d', nF),'fontsize', 20, 'fontweight', 'bold');
    set(gca, 'fontsize', 16)
    
    % Null model, use growth rate of largest (first) population and offset by time delay
    Ksum(nF) = sum(K(nF,:));  % sum of the two individual carrying capacities
    islargest = find(K(nF,:)==max(K(nF,:)));
    forN1 = [r(nF,islargest) K(nF,islargest), N0(nF,islargest), t_lag(nF,islargest)];
    % Nthoffset = logistic_growth_null_2ndpop(t, Ksum(j), forN1,  N0(j,3-islargest), t_lag(j,3-islargest));
    Nthoffset = logistic_growth_null_2ndpop(t{nF}, Ksum(nF), forN1,  N0(nF,islargest), tdelay+t_lag(nF,islargest));
    semilogy(t{nF}, Nthoffset, '--', 'color', 0.7*[1 1 1]);
    
    
    if( fitLotkaVolterra == true)     
        % Lotka-Volterra model
        [rLV(nF,:), KLV(nF,:), alpha(nF,:), sigrLV(nF,:), sigKLV(nF,:), sigalphaLV(nF,:)] = ...
            fit_Lotka_Volterra_same_r(t{nF}, [p{nF}(:,1); p{nF}(:,2)], N0(nF,:), t_lag(nF,:), halfboxsize);
        NthLV = Lotka_Volterra(t{nF}, rLV(nF,:)*[1 1], KLV(nF,:), N0(nF,:), t_lag(nF,:), alpha(nF,:));
        semilogy(t{nF}, NthLV(1,:), ':', 'color', 0.75*colors1(2,:));
        semilogy(t{nF}, NthLV(2,:), ':', 'color', 0.75*colors1(2,:));
    end
    
    if 2==1
        % time-varying growth rate
        t_window = 3.1*dt;  % +/- time window size
        for k=1:length(t{nF})
            fitt = t{nF}(abs(t{nF}-t{nF}(k))<t_window);
            fitp = p{nF}( abs(t{nF}-t{nF}(k))<t_window);
            if length(fitp)>=3
                [~, ~, logslope(nF,k), ~] = fitline(fitt, log(fitp));
            end
        end
        % compare to slope of (fitted) logistic curve
        logslope_th = r(nF)*(1-Nth/K(nF));
        figure('name', sprintf('Growth rate., Fish %d', nF), 'Position', [650 378 560 420]);
        plot(t{nF}, logslope(nF,:), 'o-', 'color', 0.75*colors{1}(nF,:))
        hold on
        plot(t{nF}, logslope_th, 'r-')
        t_floor = (-1/r(nF))*log((K(nF)-N0(nF))/(K(nF)-1)/N0(nF));  % t at which logistic curve crosses floor
        plot(t_floor*[1 1], [min(logslope_th) max(logslope_th)], 'k:')
        xlabel('Time from imaging start, hrs.','fontsize', 18)
        ylabel('Inst. growth rate (1/hr)','fontsize', 18)
        title(sprintf('Fish %d', nF),'fontsize', 20, 'fontweight', 'bold');
        set(gca, 'fontsize', 16)
    end
    
    % disp('Press enter')
    pause (0.25)
end


pause
%% Display fit values
displayvalues = true;
if displayvalues
    for nF=1:Nfish
        % Display fit values
        fs = sprintf('Fish %d: Logistic growth. ', nF); disp(fs);
        
        fs = '     Growth rates:  ';
        for nC=1:numColor          
            fs = [fs sprintf('  r = %.2f +/- %.2f   ' ,r(nF,nC), sigr(nF,nC))];           
        end
        fs = [fs '1/hr '];
        disp(fs)
        
        
        fs = sprintf('       Doubling time:  ');
        for nC = 1:numColor
           fs = [fs sprintf(' %.2f +/- %.2f     ', log(2)/r(nF,nC), log(2)*sigr(nF,1)/(r(nF,1)^2))];
            
        end
        fs = [fs 'hr']; disp(fs);
        
        
        %fs = sprintf('         [Doubling time   %.2f +/- %.2f  and %.2f  +/- %.2f hr]', ...
         %   log(2)/r(nF,1), log(2)*sigr(nF,1)/(r(nF,1)^2), log(2)/r(nF,2), log(2)*sigr(nF,2)/(r(nF,2)^2)); disp(fs);
        
        fs = sprintf('   Carrying capacity: ' );
        for nC = 1:numColor
           fs = [fs sprintf('   %.2e   ', K(nF,nC))];
        end
        disp(fs)
        
        
        %fs = sprintf('         Carrying capacity %.2e and %.2e', K(nF,1), K(nF,2)); disp(fs);
        
        fs = sprintf('   lag time:   ');
        for nC= 1:numColor
            fs = [fs sprintf('%.1f  ', t_lag(nF, nC))];
        end
        disp(fs);
        
        %fs = sprintf('         lag time %.1f and %.1f', t_lag(nF,1), t_lag(nF,2)); disp(fs);
        
        fs = sprintf('  Nucleaution size N0:  ');
        
        for nC = 1:numColor
            fs = [fs sprintf('%.1f  ', N0(nF, nC))];
        end
        disp(fs);
        
        
        %fs = sprintf('         Nucleation size N0 %.1f and %.1f', N0(nF,1), N0(nF,2)); disp(fs);
        
        if(numColor==2 &&  fitLotkaVolterra ==true)
            fs = sprintf('         Lotka-Volterra alpha: ');
            for nC=1:2
                fs = [fs sprintf(' %.1e', alpha(nF, nC))];
            end
        end
        
        
    end
end

%% Plot "collapsed" plots

switch numColor
    
    case 1
        
        h{1} = figure;
        
        xlabel('Time from start, hrs.','fontsize', 18)
        ylabel('(Number of bacteria - N_0) / Capacity','fontsize', 18)
        title('Second Group', 'fontsize', 20)
        
    case 2
        h{1} = figure;
        xlabel('Time from start, hrs.','fontsize', 18)
        ylabel('(Number of bacteria - N_0) / Capacity','fontsize', 18)
        title('Second Group', 'fontsize', 20)
        h{2} = figure;
        xlabel('Time from start, hrs.','fontsize', 18)
        ylabel('(Number of bacteria - N_0) / Capacity','fontsize', 18)
        title('First Group', 'fontsize', 20)
        
end
% Turn off negative numbers in semilogy warning:
wid = 'MATLAB:Axes:NegativeDataInLogAxis';
warning('off',wid)


for nF=1:Nfish
    
    for nC=1:numColor
        figure(h{nC})
        
        semilogy(t{nF}-t_lag(nF,1),(p{nF}(:,1)-N0(nF,1))/K(nF,1), 'o', 'color', 0.8*colors{nC}(nF,:), 'markerfacecolor', colors{nC}(nF,:))
        hold on
    end

end
% Turn on negative numbers in semilogy warning:
wid = 'MATLAB:Axes:NegativeDataInLogAxis';
warning('on',wid)

%% Plot growth rate vs. lag time
% column 2 is the first group; add tdelay to its lag times to approximage
% the true lag time
if plot_lagtime_and_growthrate
    figure; 
    
    for nC = 1:numColor
        plot(t_lag(:,nC), r(:,nC), 'ko', 'markerfacecolor', colors{nC}(4,:), 'markersize', 12)
        hold on
    end
    xlabel('lag time, hrs.')
    ylabel('Growth rate, 1/hrs.')
end

%% Plot universal curves
if plotuniversal
    % plot universal curve from 1st population
    
    figure(h{1});
    % mK2 = mean(K(:,2));
    semilogy(t,1./(1 + (mean(K(:,2))-1).*exp(-mean(r(:,2))*t)), 'k--')
    figure(h{2})
    semilogy(t,1./(1 + (mean(K(:,2))-1).*exp(-mean(r(:,2))*t)), 'k--')
end


end
