#!/bin/bash
export PATH=/data/apps/bin:$PATH
cd /home/lacuna/server/bin
perl summarize_spies.pl >>/tmp/four_hourly.log 2>>/tmp/four_hourly.log

