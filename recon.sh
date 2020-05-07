#!/bin/bash





echo -e "[+] Creating Folder "

mkdir $1

echo -e "[+] Folder created...."
else
	echo -e "[+] Folder was created"
fi
echo -e "[+] Subdomain scanning -- Sublist3r"
python /opt/Sublist3r/sublist3r.py -d $1  -o "$1/$1_sublist3r.txt" | sort -u
echo -e "Done .."

echo -e "[+] Subdomain scanning -- Amass"
amass enum -src -ip -brute -min-for-recursive 3 -d $1 > $1_amass.txt | sort -u 
echo -e "Done"


echo -e "[+] Subdomain scanning -- Assetfinder"
assetfinder -subs-only $1 > $1_assetfinder.txt | sort -u 
echo -e "Done"


echo -e "[+] Subdomain scanning -- Subfinder"
subfinder -d $1 > $1_subfinder.txt | sort -u
echo -e "Done"


echo -e "[+] Aquatone Scanning --[Live domain and Port opening]"
cat $1_amass.txt | aquatone
echo -e "Done"

echo -e "\n [+] Check live domain -Re-check"
cat "$1/$1_sublist3r.txt" | sort -u | httprobe >> "$1/$1_live_subdomain_sublister"
cat "$1_amass.txt" | sort -u | httprobe >> "$1/$1_live_subdomain_sublister"
cat "$1_assetfinder" | sort -u | httprobe >> "$1/$1_live_subdomain_assetfinder"
cat "$1_subfinder" | sort -u | httprobe >> "$1/$1_live_subdomain_subfinder"

echo -e "[+] Done scanning ....."


echo -e "[+] Testing Subdomain Takeover..."
cat "$1/*.txt" >> "$1/allsub.txt" | sort -u 
python /opt/takeover/takeover.py -l "$1/allsub.txt" -o "$1/allsub_resrult.txt" -v
echo -e "[+] Testing CORS Vulnerability"

while read line; do
	#statements
	cors = '$(curl -k -s -v $line -H "Origin: https://www.google.com.vn" > /dev/null)'
	if [[$cors =~ "Access-Control-Allow-Origin: *"]]; then
		echo -e $line "....it's seem like vulnarable to CORS"
		echo -e ' curl -k -s -v $line -H "Origin: https://www.google.com.vn"' >> $1/$1_CORS.txt
	fi

done < $1/allsub.txt

echo -e "[+] Done ...."

echo -e "\n [Testing HTTP Method"

while read line; do
put='$(curl -i -X OPTIONS $line > /dev/null)'
    if [[ $put =~ "PUT" ]]; then
        echo -e $line " .... it's seem vulnerable to method PUT"
	echo -e "curl -i -X OPTIONS $line " >> $1/$1_method_put.txt
    fi
done < $1/$1_subdomains.txt
echo -e "[+] Done"

echo -e "\n[+] Testing Host Header Attack"

while read line; do
host='$(curl -H "Host: https://www.google..com.vn" $line > /dev/null)'
    if [[ $host =~ "Location: https://www.google.com.vn" ]]; then
        echo -e $line " .... it's seem vulnerable to Host Header Attack"
        echo -e 'curl -H "Host: https://www.google.com.vn" $line ' >> $1/$1_hostheader.txt
    fi
done < $1/allsub.txt
echo -e "[+] Done"
