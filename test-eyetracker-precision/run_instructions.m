function [] = run_instructions(wh, white, dur)

    Screen('TextStyle', wh, 1);
    Screen('TextSize', wh, 80);
    instructions = ...
        sprintf(['First follow the dot\nwith your eyes\n' ...
                'Then keep your eyes on\nthe fixation!\n']);
    DrawFormattedText(wh, instructions, 'Center', 'Center', white, 115);
    Screen('Flip', wh);
    WaitSecs(dur);
end