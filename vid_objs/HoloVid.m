classdef HoloVid < matlab.mixin.Copyable
    properties(Access=public)
        vid_name
        vid_file_path
        no_of_frames
        selected_fr_no
        curr_select_fr
        princ_frames
        deriv_frames
        cutoff_frame_no
        frames
        bboxes_have_been_consolidated
        is_empty
    end
    properties(Access=private)
        bboxes_have_just_been_added
        framerate
        txt_xy
        show_I_minmax
        parent_ax_obj
        sqr_fr_side_sz
        total_labels
        no_labels_map
        princip_bboxes
        previous_cutoff
        frs_to_which_bboxes_have_been_applied
        fr_data_cleared
    end
    methods(Access=public)
        function self = HoloVid(vid_path_n_name, parent_ax_obj, sqr_fr_side_sz)
            if nargin < 1
                vid_path_n_name = '';
            end
            if nargin < 2
                parent_ax_obj = [];
            end
            if nargin < 3
                sqr_fr_side_sz = 1002;
            end
            if isempty(vid_path_n_name)
                self.is_empty = true;
            else
                self.is_empty = false;
                self.framerate = 5;
                self.bboxes_have_been_consolidated = false;
                if isunix()
                    self.vid_name = regexprep(vid_path_n_name,'.*/','');
                else
                    self.vid_name = regexprep(vid_path_n_name,'.*\\','');
                end
                self.vid_file_path = regexprep(vid_path_n_name, self.vid_name,'');
                self.vid_file_path = self.vid_file_path(1:end-1); %eliminates \
                self.sqr_fr_side_sz = sqr_fr_side_sz;
                self.parent_ax_obj = parent_ax_obj;
                self.show_I_minmax = false;
                self.load_vid(vid_path_n_name);
                self.update_axes_with_selected_frame();
                self.txt_xy = round(self.sqr_fr_side_sz/8);
                self.frs_to_which_bboxes_have_been_applied = [];
                self.fr_data_cleared = false;
            end
        end
    end
    methods(Access=public)
        function add_bbox_to_selected_fr(self, bbox)
            if nargin < 2
                bbox = [];
            end
            
            if isempty(bbox)
                bbox = drawrectangle(self.parent_ax_obj);
            end
            fr = self.get_frame();
            fr.add_bbox_to_rect_array(bbox);
            
            if self.selected_fr_no < self.cutoff_frame_no
                self.bboxes_have_just_been_added = true;
                %                 bbox_copy = fr.copy_last_added_bbox();
                %                 fr_that_follows = self.get_frame(self.selected_fr_no+1);
                %                 fr_that_follows.add_bbox_to_rect_array(bbox_copy);
            end
            self.add_princip_fr_no();
        end
        %         function set_parent_ax_obj(self, parent_ax_obj)
        %             self.parent_ax_obj = parent_ax_obj;
        %         end
        
        function delete_selected_bbox(self)
            fr = self.get_frame();
            fr.del_bbox();
            %             if isempty(fr.get_all_rect_bboxes())
            %
            %             end
        end
        
        function change_bbox_color(self)
            fr = self.get_frame();
            fr.change_color_if_diff_from_def();
        end
        
        function paste_selected_bbox(self)
            fr = self.get_frame();
            fr.duplicate_selected_bbox();
        end
        
        function change_color_of_selected_bbox(self) %used when bbox was suggested by
            fr = self.get_frame();
            fr.duplicate_selected_bbox();
        end
        
        function set_show_I_minmax(self, checkbox_value)
            self.clear_ax_obj_parent_for_bboxes();
            self.show_I_minmax = checkbox_value;
            self.update_axes_with_selected_frame()
        end
        function next_fr(self, apply_bboxes_to_next_fr)
            
            if apply_bboxes_to_next_fr
                self.copy_bboxes_to_subsequent_frame();
            end
            self.clear_ax_obj_parent_for_bboxes();
            
            self.selected_fr_no = self.selected_fr_no + 1;
            if self.selected_fr_no > self.no_of_frames
                self.selected_fr_no = 1;
            end
            self.update_axes_with_selected_frame()
        end
        function prev_fr(self)
            self.clear_ax_obj_parent_for_bboxes();
            
            self.selected_fr_no = self.selected_fr_no - 1;
            if self.selected_fr_no < 1
                self.selected_fr_no = self.no_of_frames;
            end
            self.update_axes_with_selected_frame()
        end
        function select_fr(self, fr_no)
            self.clear_ax_obj_parent_for_bboxes();
            self.selected_fr_no = fr_no;
            
            if self.selected_fr_no < 1
                self.selected_fr_no = self.no_of_frames;
            elseif self.selected_fr_no > self.no_of_frames
                self.selected_fr_no = 1;
            end
            
            self.get_frame();
            self.update_axes_with_selected_frame();
        end
        function set_cutoff_fr(self, new_cutoff)
            self.previous_cutoff = self.cutoff_frame_no;
            if new_cutoff > self.no_of_frames
                new_cutoff = self.no_of_frames;
            elseif new_cutoff <  1
                new_cutoff = 1;
            end
            self.cutoff_frame_no = new_cutoff;
            
            %             if self.bboxes_have_been_consolidated
            %                 self.apply_princ_bboxes_to_all_fr_above_cutoff();
            %             end
        end
        function combine_bboxes_from_all_fr(self)
            idx = [self.frames(:).is_principal];
            princip_fr = [self.frames(idx)];
            if ~isempty(princip_fr)
                self.princip_bboxes = princip_fr(1).get_all_rect_bboxes();
                for i=2:length(princip_fr)
                    self.princip_bboxes = [self.princip_bboxes; princip_fr(i).get_all_rect_bboxes()];
                end
                %                 self.apply_princ_bboxes_to_all_fr_above_cutoff();
                %                 self.bboxes_have_been_consolidated = true;
                %                 self.update_axes_with_selected_frame();
            end
        end
        function ret = vid_has_at_least_one_bbox(self)
            idx = [self.frames(:).is_principal];
            princip_fr = [self.frames(idx)];
            ret = ~isempty(princip_fr);
        end
        %this function fixes issue with Matlab deleting the ROI
        % Rectangles; it's a fucking hack to preserve the Rectangle objects
        % in the array in the Frame obj
        function clear_ax_obj_parent_for_bboxes(self)
            fr = self.frames(self.selected_fr_no); %gets currently selected frame
            fr.erase_axes_info_from_bboxes();
        end
        
        function I = get_fr_img(self)
            fr = self.get_frame();
            I = fr.get_fr_img(self.show_I_minmax);
        end
        function I = get_I_orig(self)
            fr = self.get_frame();
            I = fr.get_fr_img();
        end
        function I = get_I_min_max_norm(self)
            fr = self.get_frame();
            I = fr.get_fr_img(true);
        end
        function set_parent_axes_obj(self, parent_axes_obj)
            self.parent_ax_obj = parent_axes_obj;
            for i=1:length(self.frames)
                self.frames(i).set_parent_ax_obj(parent_axes_obj);
            end
        end
        
        function fr_rate = get_fr_rate(self)
            fr_rate = self.framerate;
        end
        
        function clear_frame_imgs_for_saving_labels(self)
            for i=1:self.no_of_frames
                fr = self.get_frame(i);
                fr.clear_I_data();
                fr.set_parent_ax_obj([]);
            end
            self.fr_data_cleared = true;
            self.parent_ax_obj = [];
        end
        function reload_saved_vid(self, external_vid_path)
            if self.fr_data_cleared
                internal_vid_path = [self.vid_file_path '\' self.vid_name];
                external_vid_path = [external_vid_path '\' self.vid_name];
                ME = MException.empty();
                try
                    internal_vid_path = regexprep(internal_vid_path,'\\+','\');
                    if isunix()
                        internal_vid_path = regexprep(internal_vid_path, '\\','/');
                    end
                    self.store_fr_imgs_into_Frame_objs(internal_vid_path);
                catch ME
                    external_vid_path = regexprep(external_vid_path,'\\+','\');
                    if isunix()
                        external_vid_path = regexprep(external_vid_path, '\\','/');
                    end
                    self.store_fr_imgs_into_Frame_objs(external_vid_path);
                end
                %                 if ~isempty(ME)
                %                    errordlg(ME.message,ME.identifier);
                %                 end
            end
            self.fr_data_cleared = false;
        end
        function store_fr_imgs_into_Frame_objs(self, vid_file_path)
            vid = VideoReader(vid_file_path);
            i = 1;
            %             dummy_frames = Frame();
            while hasFrame(vid)
                I = readFrame(vid);
                if i > self.no_of_frames
                    break;
                end
                fr = self.get_frame(i);
                fr.store_I_into_Frame(I);
                i = i + 1;
            end
        end
    end
    
    methods(Access=private)
        function load_vid(self, vid_file_path)
            vid = VideoReader(vid_file_path);
            i = 1;
            dummy_frames = Frame();
            while hasFrame(vid)
                I = readFrame(vid);
                dummy_frames(i) = Frame(i, I, self.parent_ax_obj, self.sqr_fr_side_sz);
                i = i + 1;
            end
            self.framerate = vid.FrameRate;
            self.frames = dummy_frames;
            self.selected_fr_no = 1;
            self.curr_select_fr = self.frames(self.selected_fr_no);
            self.no_of_frames = length(self.frames);
            self.cutoff_frame_no = round(self.no_of_frames/2);
            self.princ_frames = [];
            self.deriv_frames = 1:self.no_of_frames;
        end
        function update_axes_with_selected_frame(self)
            if ~isempty(self.parent_ax_obj)
                fr = self.get_frame(); %gets currently selected frame
                fr.update_axes_with_frame(self.show_I_minmax);
                
                
                if self.bboxes_have_just_been_added
                    self.bboxes_have_just_been_added = false;
                    % add bboxes to frames that follow here
                    %                     self.apply_bboxes_to_all_fr_that_follow_above_cutoff();
                end
            end
        end
        
        function copy_bboxes_to_subsequent_frame(self)
            if self.selected_fr_no < self.no_of_frames
                fr = self.get_frame();
                all_bboxes_copy_fr = fr.get_all_rect_bboxes();
                fr_subsequent = self.get_frame(self.selected_fr_no + 1);
                fr_subsequent.replace_all_bboxes(all_bboxes_copy_fr);
            end
        end
        
        function apply_bboxes_to_all_fr_that_follow_above_cutoff(self)
            for i = self.selected_fr_no:self.cutoff_frame_no
                fr_previous = self.get_frame(i-1);
                all_bboxes_copy_prev_fr = fr_previous.get_all_rect_bboxes();
                fr_that_follows = self.get_frame(i);
                fr_that_follows.replace_all_bboxes(all_bboxes_copy_prev_fr);
            end
        end
        function fr = get_frame(self, fr_no)
            if nargin < 2
                fr_no = self.selected_fr_no;
            end
            
            if fr_no > self.no_of_frames
                fr_no = self.no_of_frames;
            elseif fr_no < 1
                fr_no = 1;
            end
            
            fr = self.frames(fr_no);
        end
        function add_princip_fr_no(self)
            if isempty(self.princ_frames)
                self.princ_frames = self.selected_fr_no;
            else
                %check 1st if principal frame no. is already there
                idx = find(self.princ_frames == self.selected_fr_no,1);
                if isempty(idx)
                    self.princ_frames(end+1) = self.selected_fr_no;
                end
            end
            idx = find(self.deriv_frames == self.selected_fr_no,1);
            self.deriv_frames(idx) = [];
        end
    end
end