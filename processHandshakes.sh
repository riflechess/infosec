#!/bin/bash

baseUrl="/Users/x/dev/pwnagotchi"

# make temp dir for processing
mkdir /tmp/process-pcaps

# gather pcap files
find $baseUrl/handshakes -name "*.pcap" -exec cp {} /tmp/process-pcaps/ \;

# convert pcap -> hashcat/hccapx
echo "Converting handshakes..."
for file in /tmp/process-pcaps/*.pcap ; do
  fbasename=$(basename $file) 
  $baseUrl/hashcat/cap2hccapx $file $baseUrl/hccapx/captures/${fbasename/pcap/hccapx}
done;

# remove empties and consolidated capture from prev run
find $baseUrl/hccapx/captures/ -empty -exec rm {} \;
rm -f $baseUrl/hccapx/final.hccapx 

# append hccapx to one file
cat $baseUrl/hccapx/captures/* > $baseUrl/hccapx/final.hccapx

# cleanup
rm -R /tmp/process-pcaps
