#!/bin/bash
cat ../hikki.txt | awk '{print "http://www.sword-girls.co.kr/Img/Card/" $1 "L.jpg"}' | xargs -P 20 -n 1 wget -N
