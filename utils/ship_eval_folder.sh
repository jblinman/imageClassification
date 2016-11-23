#!/bin/bash
# Shell script to label all images in a given folder
# Get folder containing images
echo "This script takes a folder of labeled images and classifies them. The folder containing the images should have the following structure:"
echo  "
  dataDir/Label0/myAwesomeImage.png
  ...
  dataDir/Label5/myImage.jpg
  dataDir/Label5/anotherImage.jpg
  ...
"
echo "And dataDir should contain labels.txt a text file where each category is listed on a new line"
echo -n "Path to folder containing images to classify (dataDir) > "
read dataDir
# count number of images to ID
NUM=$(find $dataDir -mindepth 2 -type f | wc -l)
#echo "${NUM}"
#
echo "Generating TFRecords file"
# pass folder to script to generate TFRecords file
python3 ~/imageClassification/inception/utils/build_image_data.py --train_directory $dataDir/train --validation_directory $dataDir --output_directory $dataDir --train_shards 1 --validation_shards 1 --num_threads 1 --labels_file $dataDir/labels.txt
#
# make sure that ship_eval is built
echo "Building evaluation script"
cd /home/jessica/imageClassification/inception/inception
bazel build ship_eval
# classify the images
echo "Classifying images"
# define some variables to pass to the evaluation script
# directory that contians the newly fine-tuned checkpoints
TRAIN_DIR=/home/jessica/imageClassification/ship_model/
# directory where you want to write event logs:
EVAL_DIR=/home/jessica/imageClassification/ship_model/eval
# pass TFRecords file to ship_eval
cd ..
bazel-bin/inception/ship_eval --eval_dir="${EVAL_DIR}" --data_dir="${dataDir}" --subset=validation --num_examples=${NUM} --checkpoint_dir="${TRAIN_DIR}" --input_queue_memory_factor=1 --run_once
