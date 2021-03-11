function [] = take_break(wh, white, task) 

    Screen('TextStyle', wh, 1);
    Screen('TextSize', wh, 30); 
    instructions = ...
        sprintf(['Good work! Take a break :) \n\n'...
        'Press %s for clockwise and %s for counterclockwise.\n'],...
        KbName(task.responses(1)), KbName(task.responses(2)));
    DrawFormattedText(wh, instructions, 'Center', 'Center', white, 115);
    Screen('Flip', wh);
    %start_ts = KbWait;

    WaitSecs(4);
end