function [t] = waitPulse

% this is just like a regular KbCheck for keyboard responses. the scanner
% essentially sends a '5' keyboard press at the end of each TR

%time.start = GetSecs;
noTTLpulse = 1;
back1 = KbName('5');
back2 = KbName('5%');
while (noTTLpulse)
    [keyIsDown,secs,keyCode] = KbCheck;
    if (keyIsDown)
        if (keyCode(back1)) || (keyCode(back2))
            %fprintf('Pulse detected.\n');
            noTTLpulse = 0;
            FlushEvents('keyDown');
        end
    end
end

t = GetSecs;

return;
