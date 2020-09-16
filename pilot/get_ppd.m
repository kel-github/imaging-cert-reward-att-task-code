function [ppd] = get_ppd()
    % Get pixels per degree.
    deg2mm = 10;
    dot_pitch = 0.311; % mm, ASUS VG278
    ppd = deg2mm / dot_pitch; % pixels per degree
end

