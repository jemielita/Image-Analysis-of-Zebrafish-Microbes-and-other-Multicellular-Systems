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
        
        
        %Total intensity
        hTotInten = figure; plot(timestep*(1:NtimePoints), totalgreen, 'ko', 'markerfacecolor', [0.2 0.8 0.4]);
        hold on
        plot(timestep*(1:NtimePoints), totalred, 'kd', 'markerfacecolor', [0.8 0.4 0.2]);
        xlabel('Time, hrs.')
        ylabel('# of bacteria');
        title(dataTitle)
        
        % Total intensity, log scale
        hTotIntenLog = figure('name', 'Total intensity, log scale');
        semilogy(timestep*(1:NtimePoints), totalgreen, 'ko', 'markerfacecolor', [0.2 0.8 0.4]);
        hold on
        semilogy(timestep*(1:NtimePoints), totalred, 'kd', 'markerfacecolor', [0.8 0.4 0.2]);
        xlabel('Time, hrs.')
        ylabel('# of bacteria');
        title(dataTitle);
        
        if timeinfo(1)>timeinfo(2)
            % first red, then green; so scale red
            semilogy(timehours(timehours>=logfitrange(1) & timehours<=logfitrange(2)), exp(-k_red*tdelay)*I0_red*exp(k_red*timehours(timehours>=logfitrange(1) & timehours<=logfitrange(2))), 'r:')
        else
            % first green, then red; so scale red
            semilogy(timehours(timehours>=logfitrange(1) & timehours<=logfitrange(2)), exp(-k_green*tdelay)*I0_green*exp(k_green*timehours(timehours>=logfitrange(1) & timehours<=logfitrange(2))), 'g:')
        end
        
        set(hTotInten, 'Tag', [dataTitle '_TotInten']);
        set(hTotIntenLog, 'Tag', [dataTitle '_TotIntenLog']);
        
        figHandle = [hTotInten, hTotIntenLog];
        
        
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
        for j=1:NtimePoints
            plot3(popXpos{j,1}(2,:), popXpos{j,1}(3,:), popXpos{j,1}(1,:), 'Color', cData_green(j,:));
        
            %Get maximum value-used for setting scale on graph
            maxgreen(j) = max(popXpos{j,1}(1,:));
        end
        % Plot all red data, line-by-line
        figure(hFig_red);
        for j=1:NtimePoints
            plot3(popXpos{j,2}(2,:), popXpos{j,2}(3,:), popXpos{j,2}(1,:), 'Color', cData_red(j,:));
            maxred(j) = max(popXpos{j,1}(1,:));
        end
        
        %Making the plots prettier
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
        
        sameax = [0 min([ agreen(2)]) 1 NtimePoints*timestep 0 1.1*max([maxgreenall maxredall])];
        figure(hFig_green);
        axis(sameax)
        figure(hFig_red);
        axis(sameax)
       
        %Set name to save figure as
        set(hFig_red, 'Tag', [dataTitle '_LineDist_Red']);
        set(hFig_green, 'Tag', [dataTitle '_LineDist_Green']);
        
        %Output figure handles
        figHandle = [hFig_red, hFig_green];
        
    end

    function figurethings(hFig, plotTitle, viewangle)
        figure(hFig)
        title(plotTitle, 'interpreter', 'none', 'FontSize', 16);
        xlabel('Position, \mum')
        ylabel('Time, hrs.')
        zlabel('Intensity, a.u.')
        view(viewangle);
    end

    function printFigures(figHandle)
        
        for nF=1:length(figHandle)
            thisFig = figHandle(nF);
            outFile = [get(thisFig, 'Tag') '.png'];
            
            set(thisFig, 'PaperPosition', [0.25 2.5 6 4])  % to get a decent aspect ratio
            print(thisFig, '-dpng', outFile, '-r300')
        end
        
    end
end


