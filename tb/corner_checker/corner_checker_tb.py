import cocotb
import os
import numpy as np

import matplotlib.pyplot as plt

from cocotb.triggers import FallingEdge, Timer
from cocotb.types import LogicArray, Logic, Range

# async def generate_clock(dut):
#     """Generate clock pulses."""

#     for _ in range(10):
#         dut.clk.value = 0
#         await Timer(1, unit="ns")
#         dut.clk.value = 1
#         await Timer(1, unit="ns")
#         cocotb.start_soon(generate_clock(dut))
        
@cocotb.test()
async def corner_checker_tb(dut):
    


    # Load and process image
    img = np.fromfile("image.bin", dtype=np.uint8).reshape(720, 1280)


    # Pipe data into DUT

    xpoints = []
    ypoints = []

    for i in range(0 + 3,720 - 3):
        for j in range(0 + 3, 1280 - 3):
            # dut.candidate.value = int(img[i][j])
            
            # dut.adjacent[0].value = int(img[i - 1][j - 3])
            # dut.adjacent[1].value = int(img[i][j - 3])
            # dut.adjacent[2].value = int(img[i + 1][j - 3])
            # dut.adjacent[3].value = int(img[i + 2][j - 2])
            # dut.adjacent[4].value = int(img[i + 3][j - 1])
            # dut.adjacent[5].value = int(img[i + 3][j])
            # dut.adjacent[6].value = int(img[i + 3][j + 1])
            # dut.adjacent[7].value = int(img[i + 2][j + 2])
            # dut.adjacent[8].value = int(img[i + 1][j + 3])
            # dut.adjacent[9].value = int(img[i][j + 3])
            # dut.adjacent[10].value = int(img[i - 1][j + 3])
            # dut.adjacent[11].value = int(img[i - 2][j + 2])
            # dut.adjacent[12].value = int(img[i - 3][j + 1])
            # dut.adjacent[13].value = int(img[i - 3][j])
            # dut.adjacent[14].value = int(img[i - 3][j - 1])
            # dut.adjacent[15].value = int(img[i - 2][j - 2])

            circle = np.array([
            img[i-3][j],   img[i-3][j+1], img[i-2][j+2], img[i-1][j+3],
            img[i][j+3],   img[i+1][j+3], img[i+2][j+2], img[i+3][j+1],
            img[i+3][j],   img[i+3][j-1], img[i+2][j-2], img[i+1][j-3],
            img[i][j-3],   img[i-1][j-3], img[i-2][j-2], img[i-3][j-1],
            ], dtype=np.uint8)

            dut.candidate.value = int(img[i][j])
            dut.adjacent.value = int.from_bytes(circle[::-1].tobytes(), byteorder='big')
            
            await Timer(1, unit="ps")
            if dut.is_corner.value:
                ypoints.append(i)
                xpoints.append(j)

    
    img = np.repeat(img[...,None],3,axis=2)

    print(img.shape)


    plt.imshow(img)
    plt.plot(xpoints, ypoints, 'o')

    plt.show()

    