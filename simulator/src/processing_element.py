from bitstring import Bits
from .instruction import ProcessingElementInstruction, PEI
from dataclasses import dataclass

@dataclass
class ProcessingElementConfiguration:
    INPUT_BITWIDTH        : int
    ACCUMULATION_BITWIDTH : int
    OUTPUT_BITWIDTH       : int

class ProcessingElement:

    def __init__(
        self,
        config : ProcessingElementConfiguration,
        default_value = 0
    ):

        # Saving Inputs
        self._config = config

        # Creating Bitstrings
        self._input_a_value = Bits(int=default_value, length=self._config.INPUT_BITWIDTH)
        self._input_b_value = Bits(int=default_value, length=self._config.INPUT_BITWIDTH)
        self._acc_value     = Bits(int=default_value, length=self._config.ACCUMULATION_BITWIDTH)
        self._output_value  = Bits(int=default_value, length=self._config.OUTPUT_BITWIDTH)

    def input_a(self, value : Bits) -> None:
        self._input_a_value = value

    def input_b(self, value : Bits) -> None:
        self._input_b_value = value

    # Handling Each Instruction
    def execute_instruction(self, instruction : ProcessingElementInstruction) -> None:
        match int(instruction.get_opcode().uint):
            case PEI.NO_VALUE:
                match int(instruction.get_value().uint):
                    case PEI.MAC:
                        self._handle_mac(instruction)
                    case PEI.NOP:
                        return
                    case PEI.OUT:
                        self._handle_out(instruction)
                    case PEI.PASS:
                        self._handle_pass(instruction)
                    case PEI.CLR:
                        self._handle_clr(instruction)
                    case _:
                        raise ValueError(f"Invalid Value for Opcode {PEI.NOP_OUT} (NOP/OUT): {int(instruction.get_value().uint)}, should be {PEI.OUT} or {PEI.NOP}.")
            case PEI.RND:
                self._handle_rnd(instruction)
            case _:
                raise ValueError(f"Invalid Opcode: {int(instruction.get_opcode().uint)}")

    def _handle_mac(self, instruction : ProcessingElementInstruction):

        # Splitting the Bitstring on the Mode
        sectioned_input_a      = [elem for elem in self._input_a_value.cut(instruction.get_mode_bitwidth())]
        sectioned_input_b      = [elem for elem in self._input_b_value.cut(instruction.get_mode_bitwidth())]
        sectioned_accumulation = [elem for elem in self._acc_value.cut(instruction.get_mode_bitwidth() * (self._config.ACCUMULATION_BITWIDTH // self._config.INPUT_BITWIDTH))]

        # Performing MAC for each element
        for i in range(len(sectioned_input_a)):
            result = sectioned_accumulation[i].int + (sectioned_input_a[i].int * sectioned_input_b[i].int)
            sectioned_accumulation[i] = Bits(int=result, length=(instruction.get_mode_bitwidth() * (self._config.ACCUMULATION_BITWIDTH // self._config.INPUT_BITWIDTH)))

        # Storing the Result in the Accumulation
        self._acc_value = Bits().join(sectioned_accumulation)

    def _handle_out(self, instruction : ProcessingElementInstruction):
        sectioned_accumulation = [elem for elem in self._acc_value.cut(instruction.get_mode_bitwidth() * (self._config.ACCUMULATION_BITWIDTH // self._config.INPUT_BITWIDTH))]
        sectioned_output = [elem[(-1 * instruction.get_mode_bitwidth()):] for elem in sectioned_accumulation]
        self._output_value = Bits().join(sectioned_output)

    def _handle_pass(self, instruction : ProcessingElementInstruction):
        sectioned_input_a      = [elem for elem in self._input_a_value.cut(instruction.get_mode_bitwidth())]
        acc_length = instruction.get_mode_bitwidth() * (self._config.ACCUMULATION_BITWIDTH // self._config.INPUT_BITWIDTH)
        self._acc_value = Bits().join([Bits(int=elem.int, length=acc_length) for elem in sectioned_input_a])

    def _handle_clr(self, instruction : ProcessingElementInstruction):
        self._acc_value    = Bits(uint=0, length=self._config.ACCUMULATION_BITWIDTH)
        self._output_value = Bits(uint=0, length=self._config.OUTPUT_BITWIDTH)

    def _handle_rnd(self, instruction : ProcessingElementInstruction):
        sectioned_accumulation = [elem.int for elem in self._acc_value.cut(instruction.get_mode_bitwidth() * (self._config.ACCUMULATION_BITWIDTH // self._config.INPUT_BITWIDTH))]
        shifted_accumulation = [elem // (2 ** instruction.get_value().uint) for elem in sectioned_accumulation]
        acc_length = instruction.get_mode_bitwidth() * (self._config.ACCUMULATION_BITWIDTH // self._config.INPUT_BITWIDTH)
        self._acc_value = Bits().join([Bits(int=elem, length=acc_length) for elem in shifted_accumulation])

    def get_output(self) -> Bits:
        return self._output_value

    def get_accumulation(self) -> Bits:
        return self._acc_value
