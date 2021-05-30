function holo_vid_labeler()
    if exist('pathdef.m','file') ~= 2 % if path files does not exist yet 
        %path file is created at the end of the app's execution
        add_app_folders_to_path();
    end
%     desktop = com.mathworks.mde.desk.MLDesktop.getInstance();
%     mf = desktop.getMainFrame();
%     mf.setMinimized(true);
    ui_holo;
end
