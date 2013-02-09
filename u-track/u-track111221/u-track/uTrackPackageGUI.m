function varargout = uTrackPackageGUI(varargin)
% Launch the GUI for the u-Track Package
%
% This function calls the generic packageGUI function, passes all its input
% arguments and returns all output arguments of packageGUI
%
%
% Sebastien Besson 5/2011
%

varargout{1} = packageGUI(@UTrackPackage,varargin{:});

end