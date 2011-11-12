% make2Dgaussian.m
% 
% function to make a noisy 2D Gaussian, with which to test particle 
% tracking functions.
% z = A*exp(-(x-x0)^2 / (2*sigma_x^2))*exp(-(y-y0)^2 / (2*sigma_y^2))
%
% Should previously initialize random number stream:
% RandStream.setDefaultStream(RandStream('mt19937ar','seed',sum(100*clock)));
%
% inputs
%   N   : image size -- output will be (2N+1 x 2N+1)
%   x0  : Gaussian center, x (0 means the center of the output array)
%         Can be an array, in which case the function will output one image
%         per x0 element
%   y0  : Gaussian center, y .  Can be an array; see above
%   sigma : standard deviation
%         two columns: [sigma_x sigma_y], or one column to use same val.
%         for x and y width
%         Can be an array with #rows = Nimages to use different values for 
%         each output, or a single row for the same value for all outputs
%   A   : amplitude
%   ns  : standard deviation of Gaussian-distributed noise
%   bk  : background intensity
% output
%   z  : 2D array
%
% Raghuveer Parthasarathy
% March 19, 2011
% last modified March 20, 2011

function z = make2Dgaussian(N, x0, y0, sigma, A, ns, bk)

x0 = x0(:);
y0 = y0(:);
if length(x0) ~= length(y0)
    disp('ERROR: [make2Dgaussian.m] arrays x0 and y0 should be the same size')
end
Nimages = length(x0);

if size(sigma,2)==1
    % one col. only; duplicate to use same value for x, y
    sigma = repmat(sigma, [1,2]);
end

if size(sigma,1)==1 && Nimages > 1
    % just one row, so duplicate to use same value for all images
    sigma = repmat(sigma, [Nimages 1]);
end

[x,y] = meshgrid(-N:N,-N:N);

z = zeros(2*N+1,2*N+1,Nimages);
for k=1:Nimages
    znsbk = bk + ns*randn(2*N+1);
    z(:,:,k) = znsbk + A*exp(-(x-x0(k)).*(x-x0(k)) / (2*sigma(k,1)*sigma(k,1))).*...
        exp(-(y-y0(k)).*(y-y0(k)) / (2*sigma(k,2)*sigma(k,2)));
end

          

