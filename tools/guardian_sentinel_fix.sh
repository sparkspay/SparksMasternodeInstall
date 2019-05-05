#!/bin/bash

sed -i "s/'masternode'/'guardian'/g" ~/.sparkscore/sentinel/lib/sparksd.py
sed -i "s/'masternodelist'/'guardianlist'/g" ~/.sparkscore/sentinel/lib/sparksd.py