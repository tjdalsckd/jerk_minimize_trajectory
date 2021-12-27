function s = JerkQuinticTimeScaling(Tf, t)
% *** CHAPTER 9: TRAJECTORY GENERATION ***
% Takes Tf: Total time of the motion in seconds from rest to rest,
%       t: The current time t satisfying 0 < t < Tf.
% Returns s: The path parameter s(t) corresponding to a fifth-order
%            polynomial motion that begins and ends at zero velocity and 
%            zero acceleration.
% Example Input: 
% 
% clear; clc;
% Tf = 2;
% t = 0.6;
% s = QuinticTimeScaling(Tf,t)
% 
% Output:
% s =
%    0.1631

s = -360*(t)/(Tf^4)+360*(t^2)/(Tf^5)  ;
end