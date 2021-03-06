#!/bin/bash

# 测速阈值
base_speed=15

fping_count=30

start_seconds=$(date +%s)

if [ -f ip.txt ]; then
    echo "Test current ip ? ${base_speed}Mb/s"
    ip=$(cat ip.txt)
    speed=$(($(curl --resolve speed.cloudflare.com:443:$ip https://speed.cloudflare.com/__down?bytes=1000000000 -o /dev/null -s -w '%{speed_download}\n' --connect-timeout 5 --max-time 15 | sed "s/.000//") / 1024 / 1024 * 8))
    if [ $speed -gt $base_speed ]; then
        echo "current ip $ip ${speed}Mb/s > ${base_speed}Mb/s"
        exit 1
    else
        higher_speed=$speed
        speed=$(($(curl --resolve apple.freecdn.workers.dev:443:$ip https://apple.freecdn.workers.dev/105/media/us/iphone-11-pro/2019/3bd902e4-0752-4ac1-95f8-6225c32aec6d/films/product/iphone-11-pro-product-tpl-cc-us-2019_1280x720h.mp4 -o /dev/null -s -w '%{speed_download}\n' --connect-timeout 5 --max-time 15 | sed "s/.000//") / 1024 / 1024 * 8))
        if [ $speed -gt $base_speed ]; then
            echo "current ip $ip ${speed}Mb/s > ${base_speed}Mb/s"
            exit 1
        fi
        if [ $speed -gt $higher_speed ]; then higher_speed=$speed; fi
    fi
    current_ip=$ip
    current_speed=$higher_speed
    echo "current ip $current_ip ; current speed ${current_speed}Mb/s"
fi


echo "init..."
rm ip-random.txt
rm ip-100.txt
rm ip-3.txt
rm ip-tmp.txt
rm ip
rm /tmp/*

echo "ip-core.txt to ip-random.txt"
for ip in $(cat ip-core.txt); do
    r=$((($RANDOM * 2 + 1) % 255))
    echo $ip | sed "s/.$/$r/" >>ip-random.txt
done

echo "ip-random.txt to ip-100.txt"
# 2>/dev/null 不显示错误提示
fping -f ip-random.txt -c $fping_count -i 0 2>/dev/null | grep "\[$(($fping_count - 1))\]" | sort -n -k 10 | head -100 >ip-100.txt

echo "ip-100.txt to ip-3.txt"
for ip in $(cat ip-100.txt | awk '{print $1}'); do
    curl --resolve speed.cloudflare.com:443:$ip https://speed.cloudflare.com/__down?bytes=1000000000 -o /tmp/$ip -s --connect-timeout 2 --max-time 10 &
    sleep 0.5
done
sleep 10
ls -S /tmp | head -3 >ip-3.txt
rm -rf /tmp/*

echo "ip-3.txt to ip-tmp.txt"
for ip in $(cat ip-3.txt); do
    curl --resolve speed.cloudflare.com:443:$ip https://speed.cloudflare.com/__down?bytes=1000000000 -o /dev/null -s -w '%{speed_download}\n' --connect-timeout 5 --max-time 15 | sed "s/.000/\t$ip/" >>ip-tmp.txt
    sleep 0.5
    curl --resolve apple.freecdn.workers.dev:443:$ip https://apple.freecdn.workers.dev/105/media/us/iphone-11-pro/2019/3bd902e4-0752-4ac1-95f8-6225c32aec6d/films/product/iphone-11-pro-product-tpl-cc-us-2019_1280x720h.mp4 -o /dev/null -s -w '%{speed_download}\n' --connect-timeout 5 --max-time 15 | sed "s/.000/\t$ip/" >>ip-tmp.txt
    sleep 0.5
done

echo "ip-tmp.txt to ip.txt"
last=$(cat ip-tmp.txt | sort -r -n -k 1 | head -1)
last_ip=$(echo $last | awk '{print $2}')
last_speed=$(($(echo $last | awk '{print $1}') / 1024 / 1024 * 8))
# last_speed vs current_speed
if [ $current_speed -gt $last_speed ]; then
    last_speed=$current_speed
    last_ip=$current_ip
fi
echo $last_ip >ip.txt
echo $last_ip >/root/res/ip.txt

end_seconds=$(date +%s)
echo "$last_ip 满足要求，速度是 ${last_speed}Mb/s，耗时 $(($end_seconds - $start_seconds)) 秒！"
