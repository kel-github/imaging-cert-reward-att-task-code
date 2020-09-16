function [xy_pos] = get_positions(wh, positions)
%GET_POSITIONS Summary of this function goes here
%   Detailed explanation goes here
    ppd = get_ppd();
%     radii = [round(7.5*ppd), round(7.5*ppd), ...
%              round(4.5*ppd), round(4.5*ppd)];
    [w, h] = Screen('WindowSize', wh);
%     theta = [9*pi/8, 15*pi/8, 10*pi/8, 14*pi/8];
    x = [-5.5*ppd, 5.5*ppd, -5*ppd, 5*ppd];
    y = [2*ppd, 2*ppd, 5*ppd, 5*ppd];
%     r = radii(positions);
%     t = theta(positions);
%     x = round(w / 2 + r .* cos(t));
%     y = round(h / 2 + r .* -sin(t));
    x = round(w / 2 + x(positions));
    y = round(h / 2 + y(positions));
    xy_pos = [x; y];
end

