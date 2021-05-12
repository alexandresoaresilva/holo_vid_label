function add_all_folders()
    addpath(pwd);
    folders = dir();
    folders = folders([folders(:).isdir]);
    folders = {folders(3:end).name};
    for d=folders
        if ~isempty(d{1})
            back_folder = cd(d{1});
            add_all_folders();
            cd(back_folder);
        end
    end
end