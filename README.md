# Automatic-configuration-of-compression-algorithms-based-on-RAM-size

- 如果内存在 10.5GB 到 12.5GB 之间，设置为 12GB
-
- 如果内存在 13GB 到 16.5GB 之间，设置为 16GB
- 
- 否则，设置为总内存向上取整的值

- If memory is between 10.5GB and 12.5GB, set to 12GB.
- 
- If memory is between 13GB and 16.5GB, set to 16GB.
- 
- Otherwise, set to the value rounded up from the total memory.

- 根据 RAM 大小选择合适的压缩算法：

- 如果 RAM 小于 4GB 且支持 `zstd`，则设置为 `zstd`

- 如果 RAM 大于等于 4GB 且支持 `lz4`，则设置为 `lz4`

- Select the appropriate compression algorithm based on the RAM size:

- If RAM is less than 4GB and `zstd` is supported, set to `zstd`

- If RAM is greater than or equal to 4GB and `lz4` is supported, set to `lz4`

- 设置优先级为 0 

- Set the priority to 0 

Automatic configuration of compression algorithms based on RAM size
