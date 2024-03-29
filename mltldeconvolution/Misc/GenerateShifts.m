function [vargrid, n0] = GenerateShifts(shifttype, N, K)
% [vargrid, n0] = GenerateShifts(shifttype, N, K)
%
% Generate a shift sequence for an iterative algorithm.
%
% shifttype: One of
%            - 'none': no shifts;
%            - 'random': random shifts;
%            - 'cycle': shift by 1 sample per iteration, cycle through all dimensions.
% N:         Signal dimensions.
% K:         Number of iterations.
%
% vargrid:   Whether shifttype is not 'none' (true or false).
% n0:        Shift sequence for each dimension, or empty array if vargrid == false.
%
% (c) Cedric Vonesch, Biomedical Imaging Group, EPFL, 2008.04.03-2009.04.17

D = numel(N);

switch shifttype
	case 'none' % No shifts
		vargrid = false;
		n0 = [];
	case 'random' % Random shifts
		vargrid = true;
		n0 = zeros(D, K+1);
		for d = 1:D
			n0(d, 2:end) = N(d)*rand(1, K);
			n0 = floor(n0);
		end
	case 'cycle' % Deterministic shifts
		vargrid = true;
		n0 = zeros(D, K+1);
		for d = 1:D
			n0(d, 2:end) = floor((0:K)/2^(param.jmax*(d-1)));
		end
end