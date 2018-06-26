### An efficient FPGA implementation of the Harris Corner feature detector
This is the Vivado source code for Digilent Zedboard, including Verilog and VHDL design files, XDC constraints and test brench.

### Video demo
https://www.youtube.com/watch?v=mswuIDjOzO4&feature=youtu.be

### Credit
This project is built based on his work.
http://hamsterworks.co.nz/mediawiki/index.php/Zedboard_OV7670

### Where to buy the FPGA board
https://store.digilentinc.com/zedboard-zynq-7000-arm-fpga-soc-development-board/
https://www.avnet.com/shop/us/products/avnet-engineering-services/aes-z7ev-7z020-g-3074457345635221599/
Education purpose can get cheaper.

### Where to buy the camera
https://item.taobao.com/item.htm?spm=a230r.1.14.20.46257d77l7aJzf&id=522575685481&ns=1&abbucket=17#detail
Or any OV7670 module without FIFO with the same pinout.

### How to connect between the FPGA board and the camera
See the PCB.pdf. The schematic has been loss. R1, R2 are 4.7k pull up resistors. R3, R4 are 100ohm protection resistors. The MPU9150 part is not necessary for this project.
