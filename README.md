### Infosec
Infosec and security research projects.  It behooves every engineer to be a security professional and better understand systems we rely on.

Below is some simple mobile wifi recon utilizing [pwnagotchi](https://pwnagotchi.ai/).  Beyond the basic WPA handshake capture, the software will identify other pwnogotchi's and record them as peers/friends.  Mine came back with 16 new friends from [Defcon 29](https://defcon.org/html/defcon-29/dc-29-index.html).  Beyond that, this shows us how important it is to utilize high-entropy passwords, e.g. not something shows up in [rockyou](https://en.wikipedia.org/wiki/RockYou).

*As with many security projects, it is important you understand local laws/regulations, and obtain permission from network owners if required.* 

#### Pwnogotchi (WPA handshake Capture)
 - Build a [pwnogotchi](https://pwnagotchi.ai/installation/) (or better yet, four) on a [Raspberry Pi Zero W](https://www.raspberrypi.com/products/raspberry-pi-zero-w/) platform.
 - Collect handshakes.  Go mobile, but putting one in your car or your backpack, after checking with your local laws and regulations.

#### Handshake Capture Cleanup/Conversion
 - Utilize `cap2hccapx` to convert and append your collected `.pcap` files from pwnogotch to the `.hccapx` Hashcat format.  This will remove partial captures.  In this project `processHandshakes.sh` processes them.

#### AWS Hashcat
 - Boot up and AWS GPU/accelerated-computing optimized EC2 instance (`p` or `g`).
 - Prep the instance with Nvidia drivers/configs, copy up your `.hccapx` file, then run hashcat to get get your cracked hashes list. e.g.
   `hashcat --force -D 2,1 -m 2500 ./hccapx/final.hccapx ./dict/rockyou.txt -o cracked.txt -r ./dict/my-rules.rul`
 - Don't forget to stop your AWS EC2 instance (accelerated computing instance range from $.90/hr to $32/hr)

#### Network Recon
 - Grab another Raspberry Pi Zero W, scp up `recon.sh` and your cracked hashes file from the step above, throw it on a 60/5 crontab, and go in to mobile mode.  The device will join any of the cracked hash networks, scan, and log network info.