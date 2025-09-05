local skynet = require "skynet"
local zstd = require "lzstd"

local compress = zstd.zstd_compress;
local decompress = zstd.zstd_decompress;

local pack = function(val)
    return compress(skynet.packstring(val, 1))
end

local unpack = function(bin)
    return skynet.unpack(decompress(bin))
end
return {
    compress = compress,
    decompress = decompress,
    pack = pack,
    unpack = unpack
}
