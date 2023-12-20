JTAG (Joint Test Action Group) IEEE 1149.1<br />
# Architecure<br />
### Components
- TAP ACCESS PORT (TAP)
- TAP Controller
- Registers
- Instruction Decoder
<br />
<p align="center"><img src="https://github.com/MuntasirBabul/DFT/assets/100906324/7a26ebcd-52c5-44cd-b2ba-3532f355eb24" /></p><br /><br />

## Registers
Registers are two types
- Instruction Register
- Data Register (Bypass Register, Boundary Scan Register, Device ID Register(optional), User Data Register(optional))

## TAP ACCESS PORT (TAP)
The JTAG interface called a TAP or Test Access Port uses different signals for supporting the boundary scan operation like TCK, TMS, TDI, TDO, and TRST.<br />
- TCK - Test clock
- TMS - Test Mode Select
- TDI - Test Data Input
- TDO - Test Data Output
- TRST - Test Reset

## TAP Controller
The TCK and TMS signals drive a finite state machine in the TAP controller. TMS is sampled on the rising edge of TCK and used to advance the state.
<br />
<br />
<p align="center">
<img src="https://github.com/MuntasirBabul/DFT/assets/100906324/6f9d52a3-523f-4b61-b32b-ae8e4b3c0126" />
</p>
<br />

The actions taken in each state are as follows:

**Test-Logic-Reset**<br />
In this state all test-modes (for example extest-mode) are reset, which will disable their operation, allowing the chip to follow its normal operation.

At start-up the external logic will drive TMS high for at least 5 TCK cycles. This guarantees to reach the Test-Logic-Reset state and remain there.

**Run-Test/Idle**<br />
This is the resting state during normal operation.

**Select-DR-Scan , Select-IR-Scan**<br />
These are the starting states respectively for accessing one of the data registers (the boundary-scan or bypass register in the minimal configuration) or the instruction register.

**Capture-DR , Capture-IR**<br />
These capture the current value of one of the data registers or the instruction register respectively into the scan cells.

This is a slight misnomer for the instruction register, since it is usual to capture status information, rather than the actual instruction with Capture-IR.

**Shift-DR , Shift-IR**<br />
Shift a bit in from TDI (on the rising edge of TCK) and out onto TDO (on the falling edge of TCK) from the currently selected data or instruction register respectively.

**Exit1-DR , Exit1-IR**<br />
These are the exit states for the corresponding shift state. From here the state machine can either enter a pause state or enter the update state.

**Pause-DR , Pause-IR**<br />
Pause in shifting data into the data or instruction register. This allows for example test equipment supplying TDO to reload buffers etc.

**Exit2-DR , Exit2-IR**<br />
These are the exit states for the corresponding pause state. From here the state machine can either resume shifting or enter the update state.

**Update-DR , Update-IR**<br />
The value shifted into the scan cells during the previous states is driven into the chip (from inputs) or onto the interconnect (for outputs).

So we have a simple state machine, which allows either data registers or the instruction register to go through its capture-shift-update cycle, with an option to pause during the shifting.
 
## Reference Link:
https://vlsitutorials.com/jtag-architecture-overview/ <br />
https://www.embecosm.com/appnotes/ean5/html/ch02s01s02.html <br />
https://www.elprocus.com/jtag/ <br />

