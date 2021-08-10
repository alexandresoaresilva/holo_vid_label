clear, clc;
test_img_name = 'A2-0R4_fr6.png';
I = imread(['/home/alex/Dropbox/training experiments/resized_dataset/400x400/test/' test_img_name]);
pymodel = PyModel();