function [] = draw_stim(wh, index, color)
    % Stimuli 1 deg radius.
    % if idx is 1 | 2 | 3 then colour is a 3 (rgb) x 2 (inner|outer) matrix 
    ppd = get_ppd();
    [w, h] = Screen('WindowSize', wh);
    xc = round(w / 2);
    yc = round(h / 2);
    radius = 0.8*ppd;
    cm = Screen('ColorRange', wh);
    ch = round(cm / 2);
    pw = 5; % pen width for directional cue
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
            Screen('DrawLines', wh, lines, 2, color(1));
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
            % arrow left
            
            % outer poly
            numSides = 4;
            anglesDeg = linspace(0, 360, numSides + 1);
            anglesRad = anglesDeg * (pi/180);
            yPosVector = sin(anglesRad) .* radius + yc;
            xPosVector = cos(anglesRad) .* radius + xc;
            isConvex = 1;
            Screen('FillPoly', wh, color(:,1), [xPosVector; yPosVector]', isConvex);
            
            % inner poly
            scale = .8;
            anglesRad = anglesDeg( 2:5 ); 
            anglesRad(4) = anglesRad(4) + 90;
            anglesRad = anglesRad * (pi/180);
            yPosVector = sin(anglesRad) .* radius .* scale + yc;
            xPosVector = cos(anglesRad) .* radius .* scale + xc;
            Screen('FillPoly', wh, color(:,2), [xPosVector; yPosVector]', pw);
            
        case 2
            % arrow right

            % outer poly
            numSides = 4;
            anglesDeg = linspace(0, 360, numSides + 1);
            anglesRad = anglesDeg * (pi/180);
            yPosVector = sin(anglesRad) .* radius + yc;
            xPosVector = cos(anglesRad) .* radius + xc;
            isConvex = 1;
            Screen('FillPoly', wh, color(:,1), [xPosVector; yPosVector]', isConvex);
            
            % inner poly
            scale = .8;
            anglesRad = [0 90 270 360] * (pi/180);
            yPosVector = sin(anglesRad) .* radius .* scale + yc;
            xPosVector = cos(anglesRad) .* radius .* scale + xc;
            Screen('FillPoly', wh, color(:,2), [xPosVector; yPosVector]', pw);
        case 3
            
            % neutral arrow
            
            % outer poly
            numSides = 4;
            anglesDeg = linspace(0, 360, numSides + 1);
            anglesRad = anglesDeg * (pi/180);
            yPosVector = sin(anglesRad) .* radius + yc;
            xPosVector = cos(anglesRad) .* radius + xc;
            isConvex = 1;
            Screen('FillPoly', wh, color(:,1), [xPosVector; yPosVector]', isConvex);
            
            % inner poly
            scale = .8;
            yPosVector = sin(anglesRad) .* radius .* scale + yc;
            xPosVector = cos(anglesRad) .* radius .* scale + xc;
            Screen('FillPoly', wh, color(:,2), [xPosVector; yPosVector]', pw);
        otherwise
            sprintf('ERROR: draw_stim received invalid index %d', index);
    end
    
end % function draw_stim
