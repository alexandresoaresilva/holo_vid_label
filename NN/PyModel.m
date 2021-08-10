classdef PyModel < handle
    properties(Access=private)
        opt
        server_port
        curr_req_no
    end
    methods(Access=public)
        function self = PyModel(server_port, test_mode)
            if nargin < 1
%                 x = hdldaemon('socket', 0);
%                 server_port = str2double(x.ipc_id);
%                 hdldaemon('kill');
                server_port = 6006;
            end 
            
            if nargin <2 
                
               test_mode = false; 
            end
            self.load_webwrite_opt();
            self.server_port = num2str(server_port);
            if ~test_mode
                self.load_model_server();
            end
        end
        function [bbox, scores] = predict(self, I)
            if length(I(1,1,:)) > 1 %3 channels
                I = I(:,:,1); %it's really just grayscale
            end

            %image is transposed because Matlab linearizes matrices row-by-row
            %so result row vector is transposed
            I = I';
            self.gen_request_id();
            msg_json.req_no = self.curr_req_no;
            msg_json.img = I(:);
            response = webwrite(['http://localhost:' self.server_port '/process_request'], msg_json, self.opt);
            bbox = [];  scores = [];
            if msg_json.req_no == self.curr_req_no
                bbox = str2num(regexprep(response.bboxes,'\[+|\]+',''));
                if any(bbox)
                    bbox(:,3:4) = bbox(:,3:4) - bbox(:,1:2);
                    str_scores = strip(regexprep(response.scores,'\[+|\]+',''));
                    cell_list = strsplit(str_scores, {' ','\t'});
                    scores = cell2mat(cellfun(@(x)str2num(x),cell_list,'UniformOutput',false));
                end
            end
        end
        function set_new_obj_score_n_nms_thresh(self, score_thresh, nms_thresh)
            if nargin < 3
                nms_thresh = 0.45; %larger than the default (for the container) 0.39
            end
            self.gen_request_id();
            msg_json.req_no = self.curr_req_no;
            msg_json.set.score_thresh = score_thresh;
            msg_json.set.nms_thresh = nms_thresh;
            response = webwrite(['http://localhost:' self.server_port '/process_request'], msg_json, self.opt);
        end
%         function set_new_model_into_container(self)
%             
%         end
        function kill_model_server(self)
            if isunix()
                !docker stop holo_cotton_model
                !docker container rm holo_cotton_model
            end
            
%             if ismac()
%                 system(['kill $(lsof -i tcp:' self.server_port ' | tail -n +2 | awk ''{ print $2 }'')']);
%             elseif isunix() %linux
%                 system(['/bin/bash fuser -k ' self.server_port '/tcp']);
%             elseif ispc()% windows
%                 %windows 2nd ver: for /f "tokens=5" %a in ('netstat -aon ^| find ":6006" ^| find "LISTENING"') do taskkill /f /pid %a
%                 system(['kill $(lsof -t -i :' self.server_port ')']);
%             end
        end
    end
    methods(Access=private)
        function load_model_server(self)
            if ismac()
                %do nothing
            elseif isunix()
                system(['gnome-terminal -- docker run -p ' self.server_port ':5000 --name holo_cotton_model -it py_model']);
            elseif ispc()
            
            end
%             pause(0.5);
%             while ~self.model_server_is_up()
%                 pause(0.5);
%             end
        end
        function gen_request_id(self)
           self.curr_req_no = randi(1e6); 
        end
        
        function is_up = model_server_is_up(self)
            self.gen_request_id();
            msg_json.req_no = self.curr_req_no;
            msg_json.test = true;
            response = webwrite(['http://localhost:' self.server_port '/process_request'], msg_json, self.opt);
            is_up= false;
            if ~ischar(response)
                if isfield(response,'result')
                    is_up = strcmpi(response.result,'received');
                end
            end
        end
        function load_webwrite_opt(self)
            self.opt = weboptions;
            self.opt.RequestMethod = 'post';
            self.opt.ContentType = 'json';
            self.opt.ArrayFormat = 'json';
            self.opt.CharacterEncoding = 'UTF-8';
            self.opt.RequestMethod = 'post';
        end
    end
end