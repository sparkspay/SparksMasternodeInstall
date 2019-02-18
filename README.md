![Example-Logo](https://i.imgur.com/IPrlf78.png)
# SparksPay Masternode Setup Guide (Ubuntu 16.04 and 18.04)
This guide will assist you in setting up a SparksPay Masternode on a Linux Server running Ubuntu 16.04 or 16.04. (Use at your own risk)

If you require further assistance contact the support team @ [Discord](https://discord.gg/6ktdN8Z)
***
## Requirements
1) **1,000 Sparks coins.**
2) **Any VPS running Linux Ubuntu 16.04 or 18.04**
3) **A Windows/MAC Sparks wallet.**
4) **An SSH client such as kitty or putty**
***
## Contents
* **Section A**: Downloading and Running Auto Installer script  
* **Section B**: Preparing the local wallet.
* **Section C**: Connecting & Starting the masternode.
***

* Make sure your Linux has Git installer. Execute the following on your VPS
* `git --version`
* If the reply is a version number, you can continue.
* If not, use [this guide](https://www.digitalocean.com/community/tutorials/how-to-install-git-on-ubuntu-14-04) to install Git:

## The short version  
* install the Sparks wallet on your Mac or Windows PC
* Send exactly 1000spk to your self
* document the address you sent the spk tools
* mastenode outputs

* Log onto your VPS and execute the following
* `git clone https://github.com/sparkspay/SparksMasternodeInstall`
* `cd SparksMasternodeInstall
* Make sure you have the latest version of the script
* `git pull`
* `chmod +x sparks_AutoInstaller.sh`
* `bash sparks_AutoInstaller.sh`
* Follow the on-screen instructions

* If you are not sure of anything press Ctrl+c to exit
* wait for the tests to loop
* press start in HOT wallet when instructed
* reboot VPS

***

## Section A: Downloading and running Auto Installer script

***Step 1***
* Connect to your VPS
* log in as root or any other user


***

***Step 2***
* Paste the code below into terminal then press enter
`git clone https://github.com/sparkspay/SparksMasternodeInstall`
`cd SparksMasternodeInstall`
`git pull`
***
***Step 3***

* if you are not logged in as the root user execue the folloing
`chmod +x sparks_AutoInstaller.sh`

* the run the Auto Installer with the following command

`bash sparks_AutoInstaller.sh`

![Example-Bash](https://i.imgur.com/5DAJNbd.png)

***

***Step 9***
* Sit back and wait for the install (this will take 10-20 mins)
***

***Step 10***
* When prompted to enter your private key - press enter

![Example-installing](https://i.imgur.com/UTjCtrL.png)
***

***Step 11***
* You will now see all of the relavant information for your server.
* Keep this terminal open as we will need the info for the wallet setup.
![Example-installing](https://i.imgur.com/P0PLUeq.png)
***

## Section D: Preparing the Local wallet

***Step 1***
* Download and install the Sparks wallet [here](https://github.com/sparkspay/sparks/releases)
***

***Step 2***
* Send EXACLY 1,000 SPK to a receive address within your wallet.
***

***Step 3***
* Create a text document to temporarily store information that you will need.
***

***step 4***
* Go to the console within the wallet

![Example-console](https://i.imgur.com/rumxdpO.png)
***

***Step 5***
* Type the command below and press enter

`masternode outputs`

![Example-outputs](https://i.imgur.com/LNBjk1Q.png)
***

***Step 6***
* Copy the long key (this is your transaction ID) and the 1 or 2 at the end (this is your output index)
* Paste these into the text document you created earlier as you will need them in the next step.
***

# Section E: Connecting & Starting the masternode

***Step 1***
* Go to the tools tab within the wallet and click open "masternode configuration file"
![Example-create](https://i.imgur.com/2vozmrA.png)
***

***Step 2***

* Fill in the form.
* For `Alias` type something like "MN01" **don't use spaces**
* The `Address` is the IP and port of your server (this will be in the Bitvise terminal that you still have open).
* The `PrivKey` is your masternode Gen key (This is also in the Bitvise terminal that you have open).
* The `TxHash` is the transaction ID/long key that you copied to the text file.
* The `Output Index` is the 0 or 1 that you copied to your text file.
![Example-create](https://i.imgur.com/CP7TjlL.png)

Click "File Save"
***

***Step 3***
* Close out of the wallet and reopen Wallet
*Click on the Masternodes tab "My masternodes"
* Click start all in the masternodes tab
***

***step 4***
* Check the status of your masternode within the VPS by using the command below:

`sparks-cli masternode status`

*You should see ***status 9***

If you do, congratulations! You have now setup a masternode. If you do not, please contact support and they will assist you.  
