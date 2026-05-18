import cocotb
import os
import numpy as np

@cocotb.test()
async def corner_checker_tb(dut):
    pass


cock = np.fromfile("image.bin", dtype=np.byte)

print(cock.shape)

print(cock[len(cock)-1])