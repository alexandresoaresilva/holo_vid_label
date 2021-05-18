function add_app_folders_to_path()
    addpath(pwd);
    folders = dir();
    folders = folders([folders(:).isdir]);
    folders = {folders(3:end).name};
    for d=folders
        if ~isempty(d{1})
            back_folder = cd(d{1});
            add_app_folders_to_path();
            cd(back_folder);
        end
    end
end