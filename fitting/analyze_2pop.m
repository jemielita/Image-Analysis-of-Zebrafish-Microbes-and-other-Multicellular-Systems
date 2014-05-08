% analyze_2pop.m
%
% USAGE analyze_2pop(totPop)
%       analyze_2pop(totPop,colorScheme)
%       analyze_2pop(totPop, colorScheme, plotStyle)
%       analyze_2pop(totPop, colorScheme, plotStyle, fitParam)
%
% INPUT totPop: cell array containing the total population for a number of
%               different fish. Each of these cell arrays contains an array of size
%               number Scans X number Colors containing the total population for each
%               color and time point.
%        colorScheme: (optional, default: 'unique'). Use a different color
%        scheme for each time series ('unique') or use a red and green
%        color scheme for each fish data ('redgreen').
%        plotStyle: (optional, default style for figures, if empty use default). Contains a
%        structure that will be used to adjust the features of the plots.
%        Features will be added to this as we construct our figures.
%        fitParam: (optional. default: Use default fit param). Allow the user to
%        input the parameters for the logistic growth fit. Useful for
%        forcing certain values of the fit. 
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
fitParam =[];
plotStyle = [];
switch nargin
    case 1
        colorScheme = 'unique';
        adjustStyle = false;
        
        adjustFitParam = false;
    case 2
        colorScheme = varargin{1};
        adjustStyle = false;
        adjustFitParam = false;
    case 3
        colorScheme = varargin{1};
        adjustStyle = true;
        plotStyle = varargin{2};
        adjustFitParam = false;
    case 4
        
        colorScheme = varargin{1};
        adjustStyle = true;
        plotStyle = varargin{2};
        fitParam = varargin{3};
        adjustFitParam  = true;
    otherwise
        fprintf(2, 'Analyze_2pop take 1 -3 inputs!\n');
end


if(isempty(plotStyle))
    adjustStyle = false;
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


[halfboxsize, alt_fit, tolN, params0, LB, UB, lsqoptions, fitRange] = getFitParameters(adjustFitParam, fitParam);


tdelay = 3; % hours
fs = sprintf('Using time delay %.1f hrs. for second inoculation', tdelay); disp(fs);


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
                        colors{1}(nF,:) = 0.8*[1, mod(nF,4)/3, mod(nF,2)];
                    case 2
                        colors{2}(nF,:) = 0.8*[mod(nF,3)/2, 1-mod(nF,4)/3, mod(nF,2)];
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




%% 
% Plot all data and fit to a logistic model with a carrying capacity.

allT = t;

for nF=1:Nfish
    figure('name', sprintf('Pop., Fish %d', nF), 'Position', [50 378 560 420]);
    
 
    for nC=1:numColor
        % load experimental data
        p{nF} = totPop{nF};
        
        [p{nF},t{nF}] = removeDroppedFrames(p{nF}, allT{nF}, fitParam,nF,nC);
        
        %Where the logistic curve fit is stored.
        Nth = zeros(numColor,length(t{nF}));
        
        
     
        
        if(iscell(alt_fit))
            if(numColor==1)
                thisAlt_fit = alt_fit{nF};
            else
                thisAlt_fit = alt_fit{nF,nC};
            end
        else
            thisAlt_fit = alt_fit;
        end
        
        
        %Find range of data to fit over
        if(~iscell(fitRange)||strcmp(fitRange{nF, nC},'all'))
            minS = 1;
            maxS = length(p{nF});
        else
            minS = fitRange{nF, nC}(1);
            maxS = fitRange{nF, nC}(2);
        end
      
        % fit, using fit_logistic_growth.m
        [r(nF,nC), K(nF,nC), N0(nF,nC), t_lag(nF,nC), sigr(nF,nC), sigK(nF,nC), sigN0(nF,nC), sigt_lag(nF,nC)] = ...
            fit_logistic_growth(t{nF}(minS:maxS),p{nF}(minS:maxS,nC), thisAlt_fit, halfboxsize, tolN, params0, LB, UB, lsqoptions);
        
        % Logistic fit curves, for each population
        Nth(nC,:) = logistic_N_t(t{nF}, r(nF,nC), K(nF,nC), N0(nF,nC), t_lag(nF,nC));
        
        
        
        %Plotting the result
        hLogPlot(nC) = semilogy(t{nF},p{nF}(:,nC), 'o', 'color', 0.8*colors{nC}(nF,:), 'markerfacecolor', colors{nC}(nF,:));
        hold on
   
        ax = axis;
        
        % Plot
        lineFit(nC) = semilogy(t{nF}, Nth(nC,:), '-', 'color', 0.5*colors{nC}(nF,:));
        
        
    end
    
    
    carrCapLine = semilogy(t{nF}, N0(nF,1)*ones(size(t{nF})), ':', 'color', 0.7*[1 1 1]);
    initPopLine = semilogy(t{nF}, K(nF,1)*ones(size(t{nF})), '--', 'color', 0.7*[1 1 1]);
    
    %mlj: no longer necessary: Used for checking validity of fitting
    %function
    %if t_lag(nF,1)>0
     % lagTimeLine = semilogy(t_lag(nF,1)*[1 1], [1 ax(4)], 'k:');
    %end
    
    
    axis([ax(1) ax(2) 1 ax(4)])
    xL = xlabel('Time from start of imaging, hrs.','fontsize', 18);
    yL = ylabel('Number of bacteria','fontsize', 18);
    tL = title(sprintf('Fish %d', nF),'fontsize', 20, 'fontweight', 'bold');
    set(gca, 'fontsize', 16)
    
    %Adjust the figure parameters
    if(adjustStyle)
        adjustIndivPlot();
    end

    
    % Null model, use growth rate of largest (first) population and offset by time delay
    Ksum(nF) = sum(K(nF,:));  % sum of the two individual carrying capacities
    islargest = find(K(nF,:)==max(K(nF,:)));
    forN1 = [r(nF,islargest) K(nF,islargest), N0(nF,islargest), t_lag(nF,islargest)];
    % Nthoffset = logistic_growth_null_2ndpop(t, Ksum(j), forN1,  N0(j,3-islargest), t_lag(j,3-islargest));
   % Nthoffset = logistic_growth_null_2ndpop(t{nF}, Ksum(nF), forN1,  N0(nF,islargest), tdelay+t_lag(nF,islargest));
    
    %mlj: don't need this anymore-this is for comparing to the null model.
    %semilogy(t{nF}, Nthoffset, '--', 'color', 0.7*[1 1 1]);
    
    
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
    
    
    if(adjustStyle)
       if(plotStyle.printFigure)
           fileName = ['fish_', num2str(nF), '.eps'];
           set(gcf, 'PaperPositionMode', 'auto');

           print('-r600', '-depsc', fileName);
       end
    end
    
    
end

close all
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
        
        
        fs = sprintf('    Doubling time:  ');
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
        
        fs = sprintf('   Lag time:   ');
        for nC= 1:numColor
            fs = [fs sprintf('%.1f  ', t_lag(nF, nC))];
        end
        disp(fs);
        
        %fs = sprintf('         lag time %.1f and %.1f', t_lag(nF,1), t_lag(nF,2)); disp(fs);
        
        fs = sprintf('  Nucleation size N0:  ');
        
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
        
        xLColl = xlabel('Time from start, hrs.','fontsize', 18);
        xLColl = ylabel('(Number of bacteria - N_0) / Capacity','fontsize', 18);
        title('Second Group', 'fontsize', 20);
        
    case 2
        h{1} = figure;
        xLColl = xlabel('Time from start, hrs.','fontsize', 18);
        xLColl = ylabel('(Number of bacteria - N_0) / Capacity','fontsize', 18);
        title('Second Group', 'fontsize', 20);
        h{2} = figure;
        xLColl = xlabel('Time from start, hrs.','fontsize', 18);
        xLColl = ylabel('(Number of bacteria - N_0) / Capacity','fontsize', 18);
        title('First Group', 'fontsize', 20);
        
end
% Turn off negative numbers in semilogy warning:
wid = 'MATLAB:Axes:NegativeDataInLogAxis';
warning('off',wid)

if(isfield(plotStyle, 'noTimeLagCollapsed')&&plotStyle.noTimeLagCollapsed==true)
    t_lagPlot = zeros(size(t_lag));
else
    t_lagPlot = t_lag;
end

for nC=1:numColor
    nCi = nC; %mlj: cludge-variable collision that I don't want to deal with now.
    
    figure(h{nC});
    for nF=1:Nfish       
        %        collPlot{nF, nC} = semilogy(t{nF}-t_lag(nF,1),(p{nF}(:,1)-N0(nF,1))/K(nF,1), 'o', 'color', 0.8*colors{nC}(nF,:), 'markerfacecolor', colors{nC}(nF,:))
        collPlot{nF} = semilogy(t{nF}-t_lagPlot(nF,nC),(p{nF}(:,nC))/K(nF,nC), 'o', 'color', 0.8*colors{nC}(nF,:), 'markerfacecolor', colors{nC}(nF,:));
        
        hold on
        
        
        
        if(isfield(plotStyle, 'collapsedAddLine')&&plotStyle.collapsedAddLine==true)
            % Logistic fit curves, for each population
            Nth = logistic_N_t(t{nF}, r(nF,nC), K(nF,nC), N0(nF,nC), t_lag(nF,nC));
            
            % Plot
            lineFit(nF) = semilogy(t{nF}, Nth/K(nF,nC), '-', 'color', 0.5*colors{nC}(nF,:));
        end
        
    
    
     xLColl = xlabel('Time from start, hrs.','fontsize', 18);
     yLColl = ylabel('(Number of bacteria - N_0) / Capacity','fontsize', 18);
     
    end
     %Adjust the figure parameters
     if(adjustStyle)
         adjustCollapsedPlot(nCi);
     end
    
     
     pL = 10e-5:10e1;
     %timeLine = semilogy(zeros(length(pL),1), pL,'--', 'color', 0.3*[1 1 1], 'LineWidth', 3);
     %uistack(timeLine,'bottom');
     
     
     if(adjustStyle)
         if(plotStyle.printFigure)
             fileName = ['collapsedData_color', num2str(nCi), '.eps'];
             set(gcf, 'PaperPositionMode', 'auto');
             
             print('-r600', '-depsc', fileName);
         end
     end
     
     
end




% Turn on negative numbers in semilogy warning:
wid = 'MATLAB:Axes:NegativeDataInLogAxis';
warning('on',wid)


%Adjust style, if desired

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


function [] = adjustIndivPlot()

for nC=1:numColor
    if(length(plotStyle.markerSize)>1)
        set(hLogPlot(nC), 'markerSize', plotStyle.markerSize(nF));
    else        
        set(hLogPlot(nC), 'markerSize', plotStyle.markerSize);
    end
    
    uistack(hLogPlot(nC),'top')
end

set(xL, 'FontSize', plotStyle.fontSize);
set(gca, 'FontSize', plotStyle.fontSize);
set(yL, 'FontSize', plotStyle.fontSize);


set(xL, 'String', 'Time (hours)');
set(yL, 'String', 'Number of bacteria');

% set(xL, 'FontName', plotStyle.fontName);
%set(yL, 'FontName', plotStyle.fontName);
%set(gca, 'FontName', plotStyle.fontName);

%Default for limit type is auto
if(~isfield(plotStyle, 'limType'))
    plotStyle.limType = 'auto';
end

switch plotStyle.limType
    case 'auto'
        %Do nothing
    case 'maxVal'
        %Set limit based on maximum value of population
        maxPop = max([p{nF}(:,1); p{nF}(:,2)]);
        
        set(gca, 'YLim', [0 1.05*maxPop]);
        
    case 'manual'
        %Set values outside this program
        set(gca, 'YLim', plotStyle.yLim);
        set(gca, 'YTick', plotStyle.yTick);
        set(gca, 'XLim', plotStyle.xLim);
        set(gca, 'XTick', plotStyle.xTick);
    case 'manualIndiv'
        %Set values outside this program-Use different limits for
        %each fish
        set(gca, 'YLim', plotStyle.yLim{nF});
        set(gca, 'YTick', plotStyle.yTick{nF});
        set(gca, 'XLim', plotStyle.xLim{nF});
        set(gca, 'XTick', plotStyle.xTick{nF});
        
        if(isfield(plotStyle, 'xTickLabel'))
            set(gca, 'XTickLabel', plotStyle.xTickLabel);
        end
end



for nC=1:numColor
    
    if(isfield(plotStyle, 'lineWidth'))
        set(lineFit(nC), 'LineWidth', plotStyle.lineWidth(nC));
    end
    
    if(isfield(plotStyle, 'lineStyle'))
        set(lineFit(nC), 'LineStyle', plotStyle.lineStyle{nC});
    end
    
    if(isfield(plotStyle, 'lineColor'))
        set(lineFit(nC),  'Color', plotStyle.lineColor{nF,nC});
    end
end
%       set(lineFit(2), 'LineWidth', plotStyle.lineWidth);

%      set(lineFit(2), 'LineStyle', plotStyle.lineStyle{2});

%set(carrCapLine, 'LineWidth', plotStyle.lineWidth);
%set(initPopLine, 'LineWidth', plotStyle.lineWidth);

set(carrCapLine, 'Visible', 'off');
set(initPopLine, 'Visible', 'off');
set(gca, 'lineWidth', plotStyle.axisWidth);

if(plotStyle.titleVisible==false)
    set(tL, 'Visible', 'off')
end


if(isfield(plotStyle, 'color'))
    if(size(plotStyle.color,1)==1)
        set(hLogPlot(nC), 'Color', plotStyle.color{nF});
        set(hLogPlot(nC), 'MarkerFaceColor', plotStyle.color{nF});
        set(hLogPlot(nC), 'MarkerEdgeColor', plotStyle.color{nF});
    else
       set(hLogPlot(nC), 'Color', plotStyle.color{nC,nF});
        set(hLogPlot(nC), 'MarkerFaceColor', plotStyle.color{nC,nF});
        set(hLogPlot(nC), 'MarkerEdgeColor', plotStyle.color{nC, nF}); 
    end
   %mlj: let's keep the color of the fit line black.
  % set(lineFit(1), 'Color', [0 0 0]);
end

if(isfield(plotStyle, 'markerStyle'))
    set(hLogPlot(nC),'Marker', plotStyle.markerStyle{nF});
end


if(isfield(plotStyle, 'timeOffset'))
    xTick = get(gca, 'XTick');
    xTick = xTick+plotStyle.timeOffset;
    xTickLabel = get(gca, 'XTickLabel');
    
    set(gca, 'XTick', xTick);
    set(gca, 'XTickLabel', xTickLabel);
end


end

    function [] = adjustCollapsedPlot(thisColor)
            
            for nF=1:Nfish
                if(length(plotStyle.markerSize)>1)
                    
                    set(collPlot{nF}, 'MarkerSize', plotStyle.markerSize(nF));
                else
                    set(collPlot{nF}, 'MarkerSize', plotStyle.markerSize);
                end
            end
            if(isfield(plotStyle, 'color'))
               for nF=1:Nfish
                   
                   if(size(plotStyle.color,1)==1)
                       set(collPlot{nF}, 'MarkerFaceColor', plotStyle.color{nF});
                       set(collPlot{nF}, 'MarkerEdgeColor', plotStyle.color{nF});
                   else
                       
                       set(collPlot{nF}, 'MarkerFaceColor', plotStyle.color{thisColor,nF});
                       set(collPlot{nF}, 'MarkerEdgeColor', plotStyle.color{thisColor, nF});
                   end
               end
               
                
            end
            
            
            if(isfield(plotStyle, 'markerStyle'))
               for nF=1:Nfish
                   for nC=1:numColor
                       set(collPlot{nF}, 'Marker', plotStyle.markerStyle{nF});
                   end
               end
                
            end
            
        
        
        
        for nF=1:Nfish
                
                set(lineFit(nF), 'LineWidth', plotStyle.lineWidth(nC));
                set(lineFit(nF), 'LineStyle', plotStyle.lineStyle{nC});
                
                if(isfield(plotStyle, 'lineColor'))
                    set(lineFit(nF),'Color', plotStyle.lineColor{nF,nC});
                end
                uistack(lineFit(nF),'bottom')

            
        end
        
        
        set(xLColl, 'FontSize', plotStyle.fontSize);
        set(gca, 'FontSize', plotStyle.fontSize);
        set(yLColl, 'FontSize', plotStyle.fontSize);
        
        set(xLColl, 'String', 'Time (hours)');
       % set(xLColl, 'String', '');
        
        set(yLColl, 'String', 'N/K');

        % set(xL, 'FontName', plotStyle.fontName);
        %set(yL, 'FontName', plotStyle.fontName);
        %set(gca, 'FontName', plotStyle.fontName);
        
        %Default for limit type is auto
        if(~isfield(plotStyle, 'limTypeCollapsed'))
            plotStyle.limTypeCollapsed = 'auto';
        end
        
        switch plotStyle.limTypeCollapsed
            case 'auto'
                %Do nothing
                
            case 'manual'
                %Set values outside this program
                if(~iscell(plotStyle.yLimCollapsed))
                    set(gca, 'YLim', plotStyle.yLimCollapsed);
                    set(gca, 'YTick', plotStyle.yTickCollapsed);
                    set(gca, 'XLim', plotStyle.xLimCollapsed);
                    set(gca, 'XTick', plotStyle.xTickCollapsed);
                else
                    set(gca, 'YLim', plotStyle.yLimCollapsed{nC});
                    set(gca, 'YTick', plotStyle.yTickCollapsed{nC});
                    set(gca, 'XLim', plotStyle.xLimCollapsed{nC});
                    set(gca, 'XTick', plotStyle.xTickCollapsed{nC});
                end
                
        end
        
           if(isfield(plotStyle, 'timeOffset'))
              xTick = get(gca, 'XTick');
              xTick = xTick+plotStyle.timeOffset;
              xTickLabel = get(gca, 'XTickLabel');
              
              set(gca, 'XTick', xTick);
              set(gca, 'XTickLabel', xTickLabel);
           end
        
        
        
        
        if(plotStyle.titleVisible==false)
        %    set(tL, 'Visible', 'off')
        end

        %set(gca, 'XTick', []);
        set(gca, 'lineWidth', plotStyle.axisWidth);

    end


end

function [p,t ] = removeDroppedFrames(p, t,fitParam,nF,nC)
%Find frames that we want to manually remove
if(isfield(fitParam, 'droppedFrames'))
    ind = fitParam.droppedFrames{nF,nC};
    if(~isempty(ind))
        %  indKeep = setdiff(1:length(t{nF}), ind);
        t = removerows(t,'ind', ind);
        p = removerows(p, 'ind', ind);
        
    end
end


end

