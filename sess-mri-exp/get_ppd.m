function [ppd] = get_ppd()
    % Get pixels per degree.
    % note: dot pitch for projector/screen at 7T
    % screen is 358mm x 230 mm therefore d (diagonal) = sqrt(358^2 + 230^2) = 425.5162
    % 18/05/2021: screen is 330 x 210 mm therefore d = 391.1521
    % resolution is 1600 x 1200 therefore d_in_pix = sqrt(1600^2 + 1200^2)
    % = 2000
    % pixels per mm = 2000/425.5162 = 4.7002 (dot pitch)
    % 18/05/2021: pixels per mm = 2000/391.1521 = 5.11
    % viewing distance of participant from coil mirror = 1350 mm 
    % visual angle = 23.56 mm = 1 degree
    deg2mm = 23.563; % mm
    %dot_pitch = 4.7002; % mm, 
    dot_pitch = 5.1131;
    ppd = deg2mm * dot_pitch; % pixels per degree
end

