function [] = draw_stim(wh, index, color)
    % Stimuli 1 deg radius.
    ppd = get_ppd();
    [w, h] = Screen('WindowSize', wh);
    xc = round(w / 2);
    yc = round(h / 2);
    radius = 0.8*ppd;
    cm = Screen('ColorRange', wh);
    ch = round(cm / 2);
%     Screen('FramePoly', wh, color, get_placeholder(wh, orient), 2);
    switch index
        case -1
            % Calibration cue cross
            scale = 0.5 * cos(pi/4) * radius;
            lines = [-1, 1, -1, 1;
                      -1, 1, 1, -1];
            lines = scale * lines;
            lo = repmat([xc; yc], 1, size(lines, 2));
            lines = lines + lo;
            Screen('DrawLines', wh, lines, 2, color);
        case 0
            % Fixation cross
            scale = 0.5;
            lines = [-radius, radius, 0, 0;
                      0, 0, -radius, radius];
            lines = scale * lines;
            lo = repmat([xc; yc], 1, size(lines, 2));
            lines = lines + lo;
            Screen('DrawLines', wh, lines, 2, color);
        case 1
            % Circle
            rect = [xc - radius, yc - radius, ...
                    xc + radius, yc + radius];
            Screen('FillOval', wh, color, rect);
        case 2
            % Square
            offset = radius * cos(pi/4);
            rect = [xc - offset, yc - offset, ...
                    xc + offset, yc + offset];
            Screen('FillRect', wh, color, rect);            
        case 3
            % Triangle
            angles = 2 * pi * (0:2) / 3 - pi / 2;
            points = [xc + radius * cos(angles); ...
                      yc + radius * sin(angles)]';
            Screen('FillPoly', wh, color, points);
        case 4
            % Diamond
            angles = 2 * pi * (0:3) / 4;
            points = [xc + radius * cos(angles); ...
                      yc + radius * sin(angles)]';
            Screen('FillPoly', wh, color, points);
        case 5
            % Pentagon
            angles = 2 * pi * (0:4) / 5 - pi / 2;
            points = [xc + radius * cos(angles); ...
                      yc + radius * sin(angles)]';
            Screen('FillPoly', wh, color, points);
        case 6
            % Star
            angles = 2 * pi * (0:9) / 10 - pi / 2;
            rf = repmat([1, 0.5], 1, 5);
            points = [xc + radius * rf .* cos(angles); ...
                      yc + radius * rf .* sin(angles)]';
            Screen('FillPoly', wh, color, points);
        otherwise
            sprintf('ERROR: draw_stim received invalid index %d', index);
    end
    
end % function draw_stim
