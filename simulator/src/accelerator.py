from dataclasses import dataclass
from bitstring import Bits
from .processing_element import ProcessingElement, ProcessingElementConfiguration
from .main_buffer import MainBuffer, MainBufferConfiguration
from .instruction import Instruction, MemoryInstruction, ProcessingElementInstruction


@dataclass
class AcceleratorConfiguration:

    # Top Level Specific Values
    COUNTER_BITWIDTH : int
    PE_COUNT         : int

    # Internal Buffer/PE Configurations
    PE_CONFIG        : ProcessingElementConfiguration
    BUFFER_CONFIG    : MainBufferConfiguration

    # Function to Validate Configuration
    def validate(self) -> None:

        # Ensuring the Width of the Main Buffer Matches the
        # Number of PEs in the Array accounting for Input Width
        if (self.PE_COUNT != (self.BUFFER_CONFIG.MEM0_BITWIDTH/self.PE_CONFIG.INPUT_BITWIDTH)):
            raise ValueError(f"Incorrect number of PEs ({self.PE_COUNT}) with input bitwidth {self.PE_CONFIG.INPUT_BITWIDTH} for memory output bitwidth {self.BUFFER_CONFIG.MEM0_BITWIDTH}.")

        # Ensuring the Width of the Main Buffer Matches the PE input bitwidth
        if (self.PE_CONFIG.INPUT_BITWIDTH != self.BUFFER_CONFIG.MEM1_BITWIDTH):
            raise ValueError(f"Incorrect PE input bitwidth {self.PE_CONFIG.INPUT_BITWIDTH} for memory bitwidth {self.BUFFER_CONFIG.MEM1_BITWIDTH}.")

        # Ensuring the Width of the Main Buffer Matches the PE output bitwidth
        if (self.PE_COUNT != (self.BUFFER_CONFIG.MEM2_BITWIDTH/self.PE_CONFIG.OUTPUT_BITWIDTH)):
            raise ValueError(f"Incorrect number of PEs ({self.PE_COUNT}) with output bitwidth {self.PE_CONFIG.OUTPUT_BITWIDTH} for memory input bitwidth {self.BUFFER_CONFIG.MEM2_BITWIDTH}.")
AccelConfig=AcceleratorConfiguration


class Accelerator:

    def __init__(
        self,
        controller_config : AcceleratorConfiguration,
        default_counter_value = 0
    ):

        # Saving the Configuration and Validating
        self._controller_config = controller_config
        self._controller_config.validate()

        # Creating a Bit-Accurate Representation of the Counter
        self._counter = Bits(uint=default_counter_value, length=self._controller_config.COUNTER_BITWIDTH)

        # Creating an Array of PEs
        self._pe_array = [
            ProcessingElement(self._controller_config.PE_CONFIG) for _ in range(self._controller_config.PE_COUNT)
        ]

        # Creating a Main Buffer
        self._main_buffer = MainBuffer(self._controller_config.BUFFER_CONFIG)

    def set_memory(self, mem0 : list[Bits], mem1 : list[Bits]) -> None:
        self.set_mem0(mem0)
        self.set_mem1(mem1)

    def set_mem0(self, mem : list[Bits]) -> None:
        self._main_buffer.set_mem0_bits(mem)

    def set_mem1(self, mem : list[Bits]) -> None:
        self._main_buffer.set_mem1_bits(mem)

    def get_mem2(self) -> list[Bits]:
        return self._main_buffer.read_mem2_bits()

    def execute_instructions(self, instructions : list[Instruction]):
        for inst in instructions:
            self.execute_instruction(inst)

    def execute_instruction(self, instruction : Instruction):
        # Iterating for "Counter" number of times
        iteration_count = 0
        while True:

            # Sending the Instruction to the Main Buffer
            self._main_buffer.execute_instruction(instruction.get_mem_instruction())

            # Sending the Main Buffer Output to the PEs
            mem0_out = self._main_buffer.read_mem0_output()
            mem1_out = self._main_buffer.read_mem1_output()

            # Splitting Mem0 Output and Sending to Each PE while Running Command
            for i, elem in enumerate(mem0_out.cut(self._controller_config.PE_CONFIG.INPUT_BITWIDTH)):

                # Sending Elements
                self._pe_array[i].input_a(elem)
                self._pe_array[i].input_b(mem1_out)

                # Running Instruction
                self._pe_array[i].execute_instruction(instruction.get_pe_instruction())

            # Collating Outputs And Writing to Mem2 Input
            output_bits = Bits().join([
                self._pe_array[i].get_output() for i in range(self._controller_config.PE_COUNT)
            ])
            self._main_buffer.write_mem2_output(output_bits)

            # Incremeting the Offsets for MemA and MemB
            new_mema_offset = instruction.get_mem_instruction().get_mema_offset().uint + instruction.get_mema_inc().uint
            new_memb_offset = instruction.get_mem_instruction().get_memb_offset().uint + instruction.get_memb_inc().uint

            # Setting the new offsets
            instruction.get_mem_instruction().set_mema_offset(new_mema_offset)
            instruction.get_mem_instruction().set_memb_offset(new_memb_offset)

            # Exiting if Condition Met
            if iteration_count >= instruction.get_count().uint:
                break
            iteration_count = iteration_count + 1
