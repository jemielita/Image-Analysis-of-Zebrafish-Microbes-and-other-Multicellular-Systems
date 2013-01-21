%plotGutData: plot a variety of different graphs of information about the
%bacterial distribution in the gut
%
% USAGE: plotGutData(graphType,popTot, popXpos, bkgDiff)
%
% INPUT: graphType: cell array of strings giving which plots to produce
% AUTHOR: Matthew Jemielita, Dec 6, 2012

function [] = plotGutData(graphType, popTot, popXpos, bkgDiff,dataTitle,...
    timeinfo, printData, outputTitle)

NtimePoints = size(popTot,1);
totalgreen = popTot(:,1)'; totalred = popTot(:,2)';
timestep = 0.33;
tdelay = abs(diff(timeinfo)); % difference between inoculation start times, hr.

%Parameters for font size and type
plotFontSize = 18;
plotFontType = 'Calibri';
plotAxisLabelSize = 18;

%Plot a fit line that shows predicted growth of second wave.
plotFitLine= true;

%Limits of y range for log plot
yMin = 0;
yMax = 100100;

for nG = 1:length(graphType)
    figHandle = [];
    switch lower(graphType{nG})
        case 'totalintensity'
            
        case 'totalintensitylog'
            thisFigHandle = plotTotalInten(totalgreen, totalred);
        case 'lineplots'
            thisFigHandle = plotLineInten(popXpos);
        case 'bkgdiff'
            
        case 'bkgdiffhist'        
    end
    
    %Update the 
    figHandle = [figHandle; thisFigHandle];
    
end

if(printData==true)
    printFigures(figHandle);
end

    function figHandle = plotTotalInten(totalgreen, totalred)
       
        %Total intensity
        hTotInten = figure; plot(timestep*(1:NtimePoints), totalgreen, 'ko', 'markerfacecolor', [0.2 0.8 0.4]);
        hold on
        plot(timestep*(1:NtimePoints), totalred, 'kd', 'markerfacecolor', [0.8 0.4 0.2]);
        hLabels(1) = xlabel('Time, hrs.');
        hLabels(2) = ylabel('# of bacteria');
       % title(dataTitle)
        
        % Total intensity, log scale
        hTotIntenLog = figure('name', 'Total intensity, log scale');
        semilogy(timestep*(1:NtimePoints), totalgreen, 'ko', 'markerfacecolor', [0.2 0.8 0.4]);
        hold on
        semilogy(timestep*(1:NtimePoints), totalred, 'kd', 'markerfacecolor', [0.8 0.4 0.2]);
        hLabels(3) = xlabel('Time, hrs.');
        hLabels(4) = ylabel('# of bacteria');
        
        %Set font size of numbers
        set(gca, 'FontSize', plotFontSize);
        set(gca, 'FontName', plotFontType);
        
       % title(dataTitle);
        %% Get fit to the desired time interval
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
        
        if(plotFitLine==true)
            offsetLineWidth = 3;
            if timeinfo(1)>timeinfo(2)
                % first red, then green; so scale red
                semilogy(timehours(timehours>=logfitrange(1) & timehours<=logfitrange(2)), ...
                    exp(-k_red*tdelay)*I0_red*exp(k_red*timehours(timehours>=logfitrange(1) & timehours<=logfitrange(2))), ...
                    'r', 'LineWidth', offsetLineWidth)
            else
                % first green, then red; so scale red
                semilogy(timehours(timehours>=logfitrange(1) & timehours<=logfitrange(2)), ...
                    exp(-k_green*tdelay)*I0_green*exp(k_green*timehours(timehours>=logfitrange(1) & timehours<=logfitrange(2))), ...
                    'g', 'LineWidth', offsetLineWidth)
            end
        end
        set(hTotInten, 'Tag', [dataTitle '_TotInten']);
        set(hTotIntenLog, 'Tag', [dataTitle '_TotIntenLog']);
        
        %Tweak the label sizes and fonts
        for i=1:length(hLabels)
            set(hLabels(i), 'FontName', 'Calibri');
            set(hLabels(i), 'FontSize', plotAxisLabelSize);
        end
        
        %mlj: (temporary) to make all the axis on our plots the same scale
        set(gca, 'YLim', [yMin yMax]);
         figHandle = [hTotInten, hTotIntenLog];
        
         set(gca, 'XTick', [0 4 8 12 16]);
         set(gca, 'XTickLabel', [0 4 8 12 16]);
        %set(gca, 'XLim', [0 16]);
        
        set(gca, 'YTick', [ 10 100 1000 10000 100000]);
        set(gca, 'YLim', [1 yMax]);
    end

    function figHandle = plotLineInten(popXpos)
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
        
        
        
        %% Line-by-line plots
        scrsz = get(0,'ScreenSize');

        hFig_green = figure('Position',[1+500 scrsz(4)/2 - 300 scrsz(3)/2 scrsz(4)/2]);
        hold on
        hFig_red = figure('Position',[1+300 scrsz(4)/2 - 300 scrsz(3)/2 scrsz(4)/2]);
        hold on

        % Plot all green data, line-by-line
        figure(hFig_green);
        minT = 10;
        for j=minT:NtimePoints
            plot3(popXpos{j,1}(2,:), popXpos{j,1}(3,:), popXpos{j,1}(1,:), 'Color', cData_green(j,:));
        
            %Get maximum value-used for setting scale on graph
            maxgreen(j) = max(popXpos{j,1}(1,:));
        end
        % Plot all red data, line-by-line
        figure(hFig_red);
        for j=minT:NtimePoints
            plot3(popXpos{j,2}(2,:), popXpos{j,2}(3,:), popXpos{j,2}(1,:), 'Color', cData_red(j,:));
            maxred(j) = max(popXpos{j,2}(1,:));
        end
        
        %Making the plots prettier
        viewangle = [-10 50];  % alt, az
        
        figure(hFig_green);
        plotTitleGreen = strcat(dataTitle, ': GFP');
        set(gca, 'FontSize',plotAxisLabelSize);
        
       % figurethings(hFig_green, plotTitleGreen, viewangle);
        agreen = axis;

        
        figure(hFig_red);
        plotTitleRed = strcat(dataTitle, ': TdTomato');
        set(gca, 'FontSize',plotAxisLabelSize);
      %  figurethings(hFig_red, plotTitleRed, viewangle);
        
        % Axis ranges
        % make axis ranges the same
        maxgreenall = max(maxgreen);
        maxredall = max(maxred);
        
        sameax = [0 min([ agreen(2)]) 1 NtimePoints*timestep 0 1.1*max([maxgreenall maxredall])];
        figure(hFig_green);
        axis(sameax)
        figure(hFig_red);
        axis(sameax)
       
        figurethings(hFig_red, plotTitleRed, viewangle);
        figurethings(hFig_green, plotTitleGreen, viewangle);

        %Set name to save figure as
        set(hFig_red, 'Tag', [dataTitle '_LineDist_Red']);
        set(hFig_green, 'Tag', [dataTitle '_LineDist_Green']);
        
        %Output figure handles
        figHandle = [hFig_red, hFig_green];
        
    end

    function figurethings(hFig, plotTitle, viewangle)
        figure(hFig)
        title(plotTitle, 'interpreter', 'none', 'FontSize', plotFontSize);
        label(1) = xlabel('Position, \mum');
        label(2) = ylabel('Time, hrs.');
        label(3) = zlabel('# of bacteria');
        view(viewangle);
        
        for i=1:3
            set(label(i), 'FontSize', plotFontSize);
            set(label(i), 'FontName', plotFontType);
        end
        %Prettify the location of the axis labels
       %When numbers are small
        % set(label(1), 'Position', [-901.579 -112.852 10058.79])
        % set(label(2), 'Position', [-1654.77 -108.666 10997.04])
        
        %When numbers are big
        set(label(2), 'Position', [-1591, -95, 10114]);
        set(label(1), 'Position', [-715, -100.6, 9838.8]);
    end

    function printFigures(figHandle)
        
        for nF=1:length(figHandle)
            thisFig = figHandle(nF);
            %Save .png file
            outFile = [get(thisFig, 'Tag') '.png'];
            
            set(thisFig, 'PaperPosition', [0.25 2.5 6 4])  % to get a decent aspect ratio
            print(thisFig, '-dpng', outFile, '-r300')
            
            %Save .fig file
            outFileFig = [get(thisFig, 'Tag'), '.fig'];
            saveas(thisFig, outFileFig, 'fig');
        end
        
    end
end


