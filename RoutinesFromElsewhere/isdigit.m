function y = isdigit(x)
% This function returns 'true' if a character is a digit, and 'false' otherwise.
% A function with the same name and structure already exists in Octave, but not in Matlab.

y = (x >= '0') & (x <= '9');