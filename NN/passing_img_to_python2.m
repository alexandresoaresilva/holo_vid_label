clear all, clc


% Set the options for WEBWRITE
tic

test_img_name = 'A2-0R4_fr6.png';
I = imread(['/home/alex/Dropbox/training experiments/resized_dataset/400x400/test/' test_img_name]);
% imwrite(I, test_img_name);

msg_json.req_no = randi(1e6);

%image is transposed because Matlab linearizes matrices row-by-row
%so result row vector is transposed
I = I'; 

msg_json.img = I(:);
% msg_json.img = test_img_name;

opt.RequestMethod = 'post';
opt.ContentType = 'json';

% opt.ContentType = 'image';
opt.ArrayFormat = 'json';
% opt.MediaType = 'im';
opt.CharacterEncoding = 'UTF-8';
opt.RequestMethod = 'post';


sqrtresponse = webwrite('http://localhost:6006/process_request', msg_json);

if msg_json.req_no == sqrtresponse.req_no
    sqrtresponse.bboxes = str2num(regexprep(sqrtresponse.bboxes,'\[+|\]+',''));
end

%shutdown on windows: kill $(lsof -t -i :PORT_NUMBER)
%shutdown on ubuntu: fuser -k 6006/tcp
% 

toc