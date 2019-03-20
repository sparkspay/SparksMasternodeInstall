sudo apt-get install python-pip
sudo pip install pssh
edit host_file with vps info
format is IP:PORT


To read hosts file, include the -h host_file-name or –hosts host_file_name option.
To include a default username on all hosts that do not define a specific user, use the -l username or –user username option.
You can also display standard output and standard error as each host completes. By using the -i or –inline option.
You may wish to make connections time out after the given number of seconds by including the -t number_of_seconds option.
To save standard output to a given directory, you can use the -o /directory/path option.
To ask for a password and send to ssh, use the -A option.

pssh -h userXhosts l userX -A command

parallel-ssh  -A -i -H "me@my.server.home" -x "-i ~/.ssh/my_key"  'echo fu'

pssh -A -i -h rootsshkeyhosts -l root -x "-i ~/Aruba-Key-PVT.ppk"  'echo fu'