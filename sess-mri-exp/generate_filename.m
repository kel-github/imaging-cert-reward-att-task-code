function [out] = generate_filename(base, session, ext)

    % this will print a filename according to the BIDS v1.1 convention
    % base is all of the filename required, apart from the initial sub-%d
    % and apart from the extension
    % ext = extension
    % session is a structure that contains the variables sub_num and
    % session.
    % sub_nums < 10 are zero padded
    subj = session.sub_num;
    sess = session.session;
    if subj < 10
        subj_str = '00%d';
    elseif subj > 9 && subj < 100
        subj_str = '0%d';
    else
        subj_str = '%d';
    end

    out = sprintf(['sub-' subj_str base ext], subj, sess);

end % function generate_log_filename
