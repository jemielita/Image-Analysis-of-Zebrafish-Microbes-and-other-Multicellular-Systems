function W = awt(I, varargin)
% W = AWT(I) computes the A Trou Wavelet Transform of image I.
% A description of the algorithm can be found in:
% J.-L. Starck, F. Murtagh, A. Bijaoui, "Image Processing and Data
% Analysis: The Multiscale Approach", Cambridge Press, Cambridge, 2000.
%
% W = AWT(I, nBands) computes the A Trou Wavelet decomposition of the
% image I up to nBands scale (inclusive). The default value is nBands =
% ceil(max(log2(N), log2(M))), where [N M] = size(I).
%
% Output:
% W contains the wavelet coefficients, an array of size N x M x nBands+1.
% The coefficients are organized as follows:
% W(:, :, 1:nBands) corresponds to the wavelet coefficients (also called
% detail images) at scale k = 1...nBands
% W(:, :, nBands+1) corresponds to the last approximation image A_K.
%
% You can use awtDisplay(W) to display the wavelet coefficients.
%
% Sylvain Berlemont, 2009

[N, M] = size(I);

K = ceil(max(log2(N), log2(M)));

nBands = K;

if nargin > 1 && ~isempty(varargin{1})
    nBands = varargin{1};
    
    if nBands < 1 || nBands > K
        error('invalid range for nBands parameter.');
    end
end

if(nargin==3)
   W = varargin{2};
else
    W = zeros(N, M, nBands + 1);
end


I = double(I);


lastA = I;
 for k = 1:nBands
    newA = convolve(lastA, k);
    W(:, :, k) = lastA - newA;
    lastA = newA;
    
end

W(:, :, nBands + 1) = lastA;

end

function I = convolve(I, k)

%Fill in filter
h = zeros(2^(k+1) +1,1);
h(1 + 2^k) = 6;
h(1) = 1;
h(end) = 1;
h(1+ 2^(k-1)) = 4;
h(end -2^(k-1)) = 4;
h = 0.0625*h;

%hGPU = gpuArray(h);
%hGPUtrans = gpuArray(h');
%h = gpuArray(h);

I = imfilter(I, h, 'replicate');
I = imfilter(I, h', 'replicate');


end