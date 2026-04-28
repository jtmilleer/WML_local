#!/bin/bash

docker run --rm \
	--gpus all \
	--user $(id -u):$(id -g) \
	-v /home/jmiller182/INPUTS:/INPUTS \
	-v /home/jmiller182/OUTPUTS:/OUTPUTS \
	-v /home/jmiller182/tractSeg_MODEL:/MODEL \
	wml \
	/INPUTS \
	/OUTPUTS
