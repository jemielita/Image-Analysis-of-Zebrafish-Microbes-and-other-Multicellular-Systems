% Rar! FFT method of characterizing peaks

% Initialize variables
fps=5;

% load file

% Do FFT on data
fftVVM=fft(velVectMaxes);
freqDomain=fps*(0:(length(fftVVM)/2-1))/length(fftVVM);

% Plot results
plot(freqDomain(2:end),abs(fftVVM(2:end/2)));