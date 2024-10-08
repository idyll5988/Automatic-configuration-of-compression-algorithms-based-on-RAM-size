#!/system/bin/sh

ALGORITHM="/sys/block/zram0/comp_algorithm"
AVAILABLE_ALGS=$(cat "$ALGORITHM")
echo "$( date "+%Y年%m月%d日%H时%M分%S秒") *可用的压缩算法: $AVAILABLE_ALGS"
DISKSIZE="/sys/block/zram0/disksize"

TOTAL_RAM=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
TOTAL_RAM_GB=$(echo "scale=2; $TOTAL_RAM / 1024 / 1024" | bc)
echo "$( date "+%Y年%m月%d日%H时%M分%S秒") *总内存: $TOTAL_RAM_GB GB"

if (( $(echo "$TOTAL_RAM_GB < 12.5 && $TOTAL_RAM_GB > 10.5" | bc -l) )); then
  RAM=12
  echo "$( date "+%Y年%m月%d日%H时%M分%S秒") *设置 RAM 大小为 12 GB"
elif (( $(echo "$TOTAL_RAM_GB < 16.5 && $TOTAL_RAM_GB > 13" | bc -l) )); then
  RAM=16
  echo "$( date "+%Y年%m月%d日%H时%M分%S秒") *设置 RAM 大小为 16 GB"
else
  RAM=$(echo "$TOTAL_RAM_GB" | awk '{print ($0-int($0)>0)?int($0)+1:int($0)}')
  echo "$( date "+%Y年%m月%d日%H时%M分%S秒") *设置 RAM 大小为 $RAM GB"
fi

if [ "$RAM" -lt 4 ] && echo "$AVAILABLE_ALGS" | grep -q "zstd"; then
    if su -c "echo zstd > $ALGORITHM"; then
        echo "$( date "+%Y年%m月%d日%H时%M分%S秒") *成功设置压缩算法为 zstd"
    else
        echo "$( date "+%Y年%m月%d日%H时%M分%S秒") *设置压缩算法为 zstd 失败"
    fi
elif [ "$RAM" -ge 4 ] && echo "$AVAILABLE_ALGS" | grep -q "lz4"; then
    if su -c "echo lz4 > $ALGORITHM"; then
        echo "$( date "+%Y年%m月%d日%H时%M分%S秒") *成功设置压缩算法为 lz4"
    else
        echo "$( date "+%Y年%m月%d日%H时%M分%S秒") *设置压缩算法为 lz4 失败"
    fi
fi

if swapoff /dev/block/zram0; then
    echo "$( date "+%Y年%m月%d日%H时%M分%S秒") *成功禁用 ZRAM"
else
    echo "$( date "+%Y年%m月%d日%H时%M分%S秒") *禁用 ZRAM 失败，可能未启用"
fi

if swapon -p 0 /dev/block/zram0; then
    echo "$( date "+%Y年%m月%d日%H时%M分%S秒") *成功启用 ZRAM 交换"
else
    echo "$( date "+%Y年%m月%d日%H时%M分%S秒") *启用 ZRAM 交换失败"
    exit 1
fi
