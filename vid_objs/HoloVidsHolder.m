classdef HoloVidsHolder < handle
    %BBOXESHOLDER
    % class has a map for which the keys are the holographic microscopy
    % video names and the values are HoloVid classes without data image in
    % their Frames but keeping label info (bounding boxes)
    
    properties(Access=public)
        vid_obj_map
        last_vid_added
        is_empty
        vid_data_folder
    end
    properties(Access=private)
        saved_vids_cell
        ax_obj_for_vid_disp
        %          fr_have_been_cleared
    end
    methods(Access=public)
        function self = HoloVidsHolder(vid_data_folder, ax_obj_for_vid_disp, vid_obj)
            if nargin < 1
                vid_data_folder = '';
            end
            if nargin < 2
                ax_obj_for_vid_disp = [];
            end
            if nargin < 3
                vid_obj = [];
            end
            
            %BBOXESHOLDER Construct an instance of this class
            %   Detailed explanation goes here
            self.is_empty = true;
            self.vid_obj_map = containers.Map('KeyType','char','ValueType','any');
            self.last_vid_added = '';
            self.saved_vids_cell = {};
            
            self.vid_data_folder = vid_data_folder;
            self.ax_obj_for_vid_disp = ax_obj_for_vid_disp;
            if ~isempty(vid_data_folder)
                if isempty(vid_obj) %object is being reloaded
                    self.find_n_reload_labels();
                else
                    self.add_holo_vid_obj_to_map(vid_obj);
                    self.is_empty = false;
                end
            end
        end
        
        function add_holo_vid_obj_to_map(self, vid_obj)
            vid_obj.clear_ax_obj_parent_for_bboxes();
            if vid_obj.vid_has_at_least_one_bbox()
                self.last_vid_added = vid_obj.vid_name(1:end-4);
                self.vid_obj_map(self.last_vid_added) = vid_obj;
            end
        end
        
        %removes last vid obj included if no file name is fed to the
        %function
        function remov_vid_obj(self, vid_name_no_ext)
            if nargin < 2
                vid_name_no_ext = self.last_vid_added;
            end
            if self.vid_is_in_map(vid_name_no_ext)
                remove(self.vid_obj_map,  vid_name_no_ext);
            end
        end
        
        %tries to load video from video obj map property
        function vid_obj = get_vid_obj_from_map(self, vid_name)
            vid_name_no_ex = vid_name(1:end-4);
            if self.vid_is_in_map(vid_name_no_ex)
                vid_obj = self.vid_obj_map(vid_name);
                %                 vid_obj.
            end
        end
        
        function save_labels(self, save_individ)
            if nargin < 2
                save_individ = true;
            end
            
            vid_names_cell = self.vid_obj_map.keys;
            if save_individ
                for f=vid_names_cell
                    self.save_one_vid_label(f{1});
                end
            end
        end
        
        function save_one_vid_label(self, vid_name_no_ext)
            if nargin < 2
                vid_name_no_ext = self.last_vid_added;
            end
            % if self.vid_is_in_map(vid_name_no_ext)
            vid_obj = self.vid_obj_map(vid_name_no_ext);
            vid_obj_dummy = vid_obj.copy();
            vid_obj_dummy.clear_frame_imgs_for_saving_labels();
            save(['label_files\' vid_name_no_ext '_bboxes.mat'], 'vid_obj_dummy');
            % end
        end
        
        function ret = vid_is_in_map(self, vid_name_no_ex)
            k = keys(self.vid_obj_map);
            idx = find(contains(k, vid_name_no_ex),1);
            ret = ~isempty(idx);
        end
    end
    methods(Access=private)
        function find_n_reload_labels(self, new_vid_folder)
            if nargin < 2
                new_vid_folder = self.vid_data_folder;
            end
           d = dir('label_files');
           file_names = {d(:).name};
           idx = find(contains(file_names, 'bboxes.mat'));
           if ~isempty(idx)
               for i=1:length(idx)
                    load(['label_files\' file_names{idx(i)}], 'vid_obj_dummy');
                    vid_obj_dummy.reload_saved_vid(new_vid_folder);
                    vid_obj_dummy.set_parent_axes_obj(self.ax_obj_for_vid_disp);
                    self.add_holo_vid_obj_to_map(vid_obj_dummy);
               end
           end
        end
    end
end

