#!/system/bin/sh
echo "$(date "+%Y年%m月%d日%H时%M分%S秒") *提示用户输入 ram_expand_size 的值"
echo "请输入 RAM 扩展大小（例如：8192）："
read USER_RAM_EXPAND_SIZE

echo "$(date "+%Y年%m月%d日%H时%M分%S秒") *确保用户输入的值是有效的数字"

case "$USER_RAM_EXPAND_SIZE" in
    ''|*[!0-9]*)  
        echo "无效的输入，请输入一个有效的数字。"
        exit 1
        ;;
    *) 
        su -c cmd settings put global ram_expand_size "$USER_RAM_EXPAND_SIZE"
        ;;
esac
VM="/proc/sys/vm"
ZRAM_DEV="/dev/block/zram0"
ZRAM_SYS="/sys/block/zram0"
ALGORITHM="/sys/block/zram0/comp_algorithm"
total_ram_kb=$(grep [0-9] /proc/meminfo | awk '/kB/{print $2}' | head -1)
AVAILABLE_ALGS=$(cat "$ALGORITHM")
echo "$(date "+%Y年%m月%d日%H时%M分%S秒") *可用的压缩算法: $AVAILABLE_ALGS"
TOTAL_RAM=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
TOTAL_RAM_GB=$(echo "scale=2; $TOTAL_RAM / 1024 / 1024" | bc)
echo "$(date "+%Y年%m月%d日%H时%M分%S秒") *总内存: $TOTAL_RAM_GB GB"

if (( $(echo "$TOTAL_RAM_GB < 12.5 && $TOTAL_RAM_GB > 10.5" | bc -l) )); then
  RAM=12
  echo "$(date "+%Y年%m月%d日%H时%M分%S秒") *设置 RAM 大小为 12 GB"
elif (( $(echo "$TOTAL_RAM_GB < 16.5 && $TOTAL_RAM_GB > 13" | bc -l) )); then
  RAM=16
  echo "$(date "+%Y年%m月%d日%H时%M分%S秒") *设置 RAM 大小为 16 GB"
else
  RAM=$(echo "$TOTAL_RAM_GB" | awk '{print ($0-int($0)>0)?int($0)+1:int($0)}')
  echo "$(date "+%Y年%m月%d日%H时%M分%S秒") *设置 RAM 大小为 $RAM GB"
fi

if [ "$RAM" -lt 4 ] && echo "$AVAILABLE_ALGS" | grep -q "zstd"; then
    if su -c "echo zstd > $ALGORITHM"; then
        echo "$(date "+%Y年%m月%d日%H时%M分%S秒") *成功设置压缩算法为 zstd"
    else
        echo "$(date "+%Y年%m月%d日%H时%M分%S秒") *设置压缩算法为 zstd 失败"
    fi
elif [ "$RAM" -ge 4 ] && echo "$AVAILABLE_ALGS" | grep -q "lz4"; then
    if su -c "echo lz4 > $ALGORITHM"; then
        echo "$(date "+%Y年%m月%d日%H时%M分%S秒") *成功设置压缩算法为 lz4"
    else
        echo "$(date "+%Y年%m月%d日%H时%M分%S秒") *设置压缩算法为 lz4 失败"
    fi
fi

if swapoff /dev/block/zram0; then
    echo "$(date "+%Y年%m月%d日%H时%M分%S秒") *成功禁用 ZRAM"
else
    echo "$(date "+%Y年%m月%d日%H时%M分%S秒") *禁用 ZRAM 失败，可能未启用"
fi

if swapon -p 0 /dev/block/zram0; then
    echo "$(date "+%Y年%m月%d日%H时%M分%S秒") *成功启用 ZRAM 交换"
else
    echo "$(date "+%Y年%m月%d日%H时%M分%S秒") *启用 ZRAM 交换失败"
    exit 1
fi

if [ "$(cat /proc/swaps | grep "$ZRAM_DEV")" != "" ]; then
    echo "$(date "+%Y年%m月%d日%H时%M分%S秒") *检测到 ZRAM 设备存在"
    if [ "$(sed -n 's/.*\[\([^]]*\)\].*/\1/p' "$ZRAM_SYS"/comp_algorithm)" == "$RAM" ] && [ "$(cat "$ZRAM_SYS"/disksize)" -le "$USER_RAM_EXPAND_SIZE" ]; then
        echo "$(date "+%Y年%m月%d日%H时%M分%S秒") *ZRAM 磁盘大小小于等于用户输入的 RAM 扩展大小"
		SWAPPINESS_VALUE=200
    else
	    echo "$(date "+%Y年%m月%d日%H时%M分%S秒") *ZRAM 磁盘大小大于用户输入的 RAM 扩展大小"
        SWAPPINESS_VALUE=160
    fi
else
    echo "$(date "+%Y年%m月%d日%H时%M分%S秒") *未检测到 ZRAM 设备，设置 SWAPPINESS 值为 60"
    SWAPPINESS_VALUE=60
fi
echo "$(date "+%Y年%m月%d日%H时%M分%S秒") *设置 SWAPPINESS 值为: $SWAPPINESS_VALUE"
echo "$SWAPPINESS_VALUE" > /dev/memcg/memory.swappiness
echo "$SWAPPINESS_VALUE" > /dev/memcg/apps/memory.swappiness
NEW_SWAPPINESS_VALUE=$((SWAPPINESS_VALUE / 2))
echo "$NEW_SWAPPINESS_VALUE" > /dev/memcg/system/memory.swappiness
echo "$(date "+%Y年%m月%d日%H时%M分%S秒") *设置 watermark_scale_factor 值为: $((377487360 / $total_ram_kb))"
echo "$((377487360 / $total_ram_kb))" > /proc/sys/vm/watermark_scale_factor 

