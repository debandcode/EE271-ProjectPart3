from bitstring import Bits
from .instruction import MemoryInstruction, MI, Mode
from dataclasses import dataclass
import numpy as np

@dataclass
class MainBufferConfiguration:
    MEM0_BITWIDTH : int
    MEM0_DEPTH    : int
    MEM1_BITWIDTH : int
    MEM1_DEPTH    : int
    MEM2_BITWIDTH : int
    MEM2_DEPTH    : int

class MainBuffer:

    def __init__(
        self,
        config : MainBufferConfiguration,
        default_value = 0
    ):

        # Saving the Config
        self._buffer_config = config

        # Creating the Individual Memories
        self._mem0 = [Bits(int=default_value, length=self._buffer_config.MEM0_BITWIDTH) for _ in range(self._buffer_config.MEM0_DEPTH)]
        self._mem1 = [Bits(int=default_value, length=self._buffer_config.MEM1_BITWIDTH) for _ in range(self._buffer_config.MEM1_DEPTH)]
        self._mem2 = [Bits(int=default_value, length=self._buffer_config.MEM2_BITWIDTH) for _ in range(self._buffer_config.MEM2_DEPTH)]

        # Creating the Output And Input Ports
        self._mem0_output_port = Bits(int=default_value, length=self._buffer_config.MEM0_BITWIDTH)
        self._mem1_output_port = Bits(int=default_value, length=self._buffer_config.MEM1_BITWIDTH)
        self._mem2_input_port  = Bits(int=default_value, length=self._buffer_config.MEM2_BITWIDTH)

    def execute_instruction(self, instruction : MemoryInstruction) -> None:
        match int(instruction.get_opcode().uint):
            case MI.READ:
                self._handle_read(instruction)
            case MI.WRITE:
                self._handle_write(instruction)
            case MI.NOP:
                return
            case _:
                raise ValueError(f"Invalid Opcode: {int(instruction.get_opcode().uint)}")

    def _handle_read(self, instruction : MemoryInstruction) -> None:

        # Setting the Mem0 Output Port
        self._mem0_output_port = self._mem0[instruction.get_mema_offset().uint]

        # Setting the Mem1 Output Port
        memb_offset = instruction.get_memb_offset().uint
        shift_amount = int(np.ceil(np.log2(self._buffer_config.MEM1_BITWIDTH/Mode.bitwidth(instruction.get_mode().uint))))
        memory_address = memb_offset >> shift_amount
        cut_index = memb_offset - (memory_address << shift_amount)
        output = [elem for elem in self._mem1[memory_address].cut(Mode.bitwidth(instruction.get_mode().uint))]

        # Recombining
        output_port_value = Bits().join(
            [output[-1 * (cut_index + 1)] for _ in range(int(self._buffer_config.MEM1_BITWIDTH/Mode.bitwidth(instruction.get_mode().uint)))]
        )
        self._mem1_output_port = output_port_value

    def _handle_write(self, instruction : MemoryInstruction) -> None:
        self._mem2[instruction.get_mema_offset().uint] = self._mem2_input_port

    def read_mem0_output(self) -> Bits:
        return self._mem0_output_port

    def read_mem1_output(self) -> Bits:
        return self._mem1_output_port

    def write_mem2_output(self, value : Bits) -> None:
        self._mem2_input_port = value

    def set_mem0(self, mem : list[int]) -> None:
        # Ensuring the Memory List is the Proper Length and Writing
        if len(mem) != self._buffer_config.MEM0_DEPTH:
            raise ValueError(f"Length of Memory [{len(mem)}] is incorrect for depth [{self._buffer_config.MEM0_DEPTH}] ")
        self._mem0 = [Bits(int=elem, length=self._buffer_config.MEM0_BITWIDTH) for elem in mem]

    def set_mem1(self, mem : list[int]) -> None:
        # Ensuring the Memory List is the Proper Length and Writing
        if len(mem) != self._buffer_config.MEM1_DEPTH:
            raise ValueError(f"Length of Memory [{len(mem)}] is incorrect for depth [{self._buffer_config.MEM1_DEPTH}] ")
        self._mem1 = [Bits(int=elem, length=self._buffer_config.MEM1_BITWIDTH) for elem in mem]

    def set_mem0_bits(self, mem : list[Bits]) -> None:
        # Ensuring the Memory List is the Proper Length and Writing
        if len(mem) != self._buffer_config.MEM0_DEPTH:
            raise ValueError(f"Length of Memory [{len(mem)}] is incorrect for depth [{self._buffer_config.MEM0_DEPTH}] ")
        self._mem0 = mem

    def set_mem1_bits(self, mem : list[Bits]) -> None:
        # Ensuring the Memory List is the Proper Length and Writing
        if len(mem) != self._buffer_config.MEM1_DEPTH:
            raise ValueError(f"Length of Memory [{len(mem)}] is incorrect for depth [{self._buffer_config.MEM1_DEPTH}] ")
        self._mem1 = mem

    def read_mem2(self) -> list[int]:
        return [elem.int for elem in self._mem2]

    def read_mem2_bits(self) -> list[Bits]:
        return self._mem2
