#!/bin/bash
. ~/.profile
url=$1
wd=`pwd`

if [ ! -d "$url" ];then

         mkdir $url
         
    if [ ! -d "$url/recon" ];then

		mkdir $url/recon
          if [ ! -d "$url/assetfinder" ] ;then

                 mkdir $url/recon/assetfinder
          fi
          if [ ! -d "$url/amass" ] ;then
          
                 mkdir $url/recon/amass
          fi
          if [ ! -d "$url/httprobe" ] ;then
          
                 mkdir $url/recon/httprobe
          fi
          if [ ! -d "$url/gowitness" ] ;then
          
                 mkdir $url/recon/gowitness
          fi
          if [ ! -d "$url/subjack" ] ;then
          
                 mkdir $url/recon/subjack
          fi
          if [ ! -d "$url/nmap" ] ;then
          
                 mkdir $url/recon/nmap
          fi
          if [ ! -d "$url/waybackurls" ] ;then
          
                 mkdir $url/recon/waybackurls
          fi
           
     fi
          

 fi

# assetfinder 
echo "[+] Harvesting subdomains with assetfinder..."
assetfinder --subs-only $url >> $url/recon/assetfinder/$url.subs

#amass		
echo "[+] Harvesting subdomains with amass..."
amass enum -d $url >> $url/recon/amass/$url.subs

echo "[+] Merging & sorting sobdomain lists..."
cat $url/recon/assetfinder/$url.subs >> $url/recon/amass/$url.subs
sort -u $url/recon/amass/$url.subs > $url/recon/$url.subs.unique
 
#httprobe 
echo "[+] Probing for live subdomains with httprobe..."
cat $url/recon/$url.subs.unique | httprobe >> $url/recon/httprobe/$url.subs.unique.live
rm $url/recon/$url.subs.unique
 		 
#nmap list setup           
cat $url/recon/httprobe/$url.subs.unique.live | grep https | cut -b 9- | sed 's/:443/''/g' >> $url/recon/$url.subs.unique.live.nmap.https
cat $url/recon/httprobe/$url.subs.unique.live | grep http: | cut -b 8- | sed 's/:443/''/g' >> $url/recon/$url.subs.unique.live.nmap.http
cat $url/recon/$url.subs.unique.live.nmap.https >> $url/recon/$url.subs.unique.live.nmap.http
sort -u $url/recon/$url.subs.unique.live.nmap.http > $url/recon/nmap/$url.subs.unique.live.nmap_list
                
#removing temporary files
rm $url/recon/$url.subs.unique.live.nmap.https $url/recon/$url.subs.unique.live.nmap.http
 		
#nmap
echo "[+] Scanning unique live Domains with nmap..."
nmap -iL $url/recon/nmap/$url.subs.unique.live.nmap_list -T4 -oA $url/recon/nmap/$url.subs.unique.live.nmap.scan

#subjack
echo "[+] Checking for possible Domain Takeovers with subjack..."
                
# setting up subjack
cd $url/recon/subjack/ && rm fingerprints.json
wget  https://raw.githubusercontent.com/haccer/subjack/master/fingerprints.json 
cd $wd             
if [ ! -f $url/recon/subjack/$url.subs.unique.live.takeover ];then
touch $url/recon/subjack/$url.subs.unique.live.takeover
fi        
                        
subjack -w $url/recon/nmap/$url.subs.unique.live.nmap_list -t 100 -timeout 30 -ssl -c $url/recon/subjack/fingerprints.json -o -v 3 $url/recon/subjack/$url.subs.unique.live.takeover

# waybackurl         
echo "[+] Scraping data with waybackurls..."
cat $url/recon/nmap/$url.subs.unique.live.nmap_list | waybackurls >> $url/recon/waybackurls/$url.subs.waybackurl
sort -u $url/recon/waybackurls/$url.subs.waybackurl > $url/recon/waybackurls/$url.subs.waybackurl.sort 
echo "[+] Pulling & Compiling all possible data found in waybackurl..."
cat $url/recon/waybackurls/$url.subs.waybackurl.sort |  grep '?*='| grep json | cut -d '=' -f 1 | sort -u > $url/recon/waybackurls/$url.subs.waybackurl.sort.json_txt
cat $url/recon/waybackurls/$url.subs.waybackurl.sort |  grep '?*='| grep php | cut -d '=' -f 1 | sort -u > $url/recon/waybackurls/$url.subs.waybackurl.sort.php_txt
cat $url/recon/waybackurls/$url.subs.waybackurl.sort |  grep '?*='| grep aspx | cut -d '=' -f 1 | sort -u > $url/recon/waybackurls/$url.subs.waybackurl.sort.aspx_txt
cat $url/recon/waybackurls/$url.subs.waybackurl.sort |  grep '?*='| grep js | cut -d '=' -f 1 | sort -u > $url/recon/waybackurls/$url.subs.waybackurl.sort.js_txt
cat $url/recon/waybackurls/$url.subs.waybackurl.sort |  grep '?*='| grep jsp | cut -d '=' -f 1 | sort -u > $url/recon/waybackurls/$url.subs.waybackurl.sort.jsp_txt
cat $url/recon/waybackurls/$url.subs.waybackurl.sort |  grep '?*='| grep html | cut -d '=' -f 1 | sort -u > $url/recon/waybackurls/$url.subs.waybackurl.sort.html_txt


# gowitness
echo "[+] Getting Pictures with gowitness..."
cd $url/recon/gowitness/
gowitness file --source=$wd/$url/recon/httprobe/$url.subs.unique.live -T 30              
cd $wd



