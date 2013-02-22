---------------------------------------------------------
--
--  AVR CPU TEST BENCH
--
---------------------------------------------------------

--
--  AVR_CPU
--
--  This is the complete entity declaration for the AVR CPU.  It is used to
--  test the complete design.
--
--  Inputs:
--    ProgDB - program memory data bus (16 bits)
--    Reset  - active low reset signal
--    INT0   - active low interrupt
--    INT1   - active low interrupt
--    clock  - the system clock
--
--  Outputs:
--    ProgAB - program memory address bus (16 bits)
--    DataAB - data memory address bus (16 bits)
--    DataWr - data write signal
--    DataRd - data read signal
--
--  Inputs/Outputs:
--    DataDB - data memory data bus (8 bits)
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.opcodes.all;
use work.avr_cpu;

entity AVRCPU_tb is
end AVRCPU_tb;

architecture  TB_AVR_CPU  of AVRCPU_tb is

    -- Component Declaration

    component  AVR_CPU
        port(
            ProgDB  :  in     std_logic_vector(15 downto 0);   -- program memory data bus
            Reset   :  in     std_logic;                       -- reset signal (active low)
            INT0    :  in     std_logic;                       -- interrupt signal (active low)
            INT1    :  in     std_logic;                       -- interrupt signal (active low)
            clock   :  in     std_logic;                       -- system clock
            ProgAB  :  out    std_logic_vector(15 downto 0);   -- program memory address bus
            DataAB  :  out    std_logic_vector(15 downto 0);   -- data memory address bus
            DataWr  :  out    std_logic;                       -- data memory write enable (active low)
            DataRd  :  out    std_logic;                       -- data memory read enable (active low)
            DataDB  :  inout  std_logic_vector(7 downto 0)     -- data memory data bus
        ); 
    end  component;

    -- Signals
    signal ProgDB : std_logic_vector(15 downto 0);
    signal Reset  : std_logic;                    
    signal INT0   : std_logic;                    
    signal INT1   : std_logic;                    
    signal clock  : std_logic;                    
    signal ProgAB : std_logic_vector(15 downto 0);
    signal DataAB : std_logic_vector(15 downto 0);
    signal DataWr : std_logic;                    
    signal DataRd : std_logic;                    
    signal DataDB : std_logic_vector(7 downto 0);  
    --Signal used to stop clock signal generators
    signal  END_SIM     :  BOOLEAN := FALSE;

    -- Constants
 --
    -- OPCODE TYPE DEFINITION ENUM
    --
    type curr_op is(
        OP_JMP,
        OP_RJMP,
        OP_IJMP,
        OP_CALL,
        OP_RCALL,
        OP_ICALL,
        OP_RET,
        OP_RETI,
        OP_BRBC,
        OP_BRBS,
        OP_CPSE,
        OP_SBRC,
        OP_SBRS
    );

    begin

    UUT : AVR_CPU
        port map(
            ProgDB => ProgDB,
            Reset  => Reset,
            INT0   => INT0,
            INT1   => INT1,
            clock  => clock,
            ProgAB => ProgAB,
            DataAB => DataAB,
            DataWr => DataWr,
            DataRd => DataRd,
            DataDB => DataDB
    );

    -- Make the interrupt lines high
    INT0 <= '1';
    INT1 <= '1';

    --
    -- ACTUALLY TEST THE CPU INSTRUCTIONS
    --
    do_test: process

        -- Variables for generating random inputs
        variable seed1, seed2: positive;
        variable rand1, rand2: real;
        variable int_randA, int_randB: integer;
        variable rand_inptA, rand_inptB, expected: std_logic_vector(7 downto 0);
        variable op : curr_op;
        variable temp_op : std_logic_vector(15 downto 0);
        variable check_bit : std_logic;
        variable stat_lp : integer;
        variable prev_zero : std_logic;

    begin

        --
        -- Reset the system, to get it into the correct state
        --
        reset <= '0';
        wait for 20 ns;
        reset <= '1';
        wait for 9 ns;

        -- Loop forever
        while ( END_SIM = FALSE ) loop

            -- Loop over all of the instructions, testing them
            --  with random inputs
            for op in curr_op loop 

                --
                -- Create the random variables
                --
                UNIFORM(seed1, seed2, rand1);
                UNIFORM(seed1, seed2, rand2);
                int_randA := INTEGER(TRUNC(rand1*256.0));
                int_randB := INTEGER(TRUNC(rand2*256.0));
                rand_inptA := std_logic_vector(to_unsigned(int_randA, rand_inptA'length));
                rand_inptB := std_logic_vector(to_unsigned(int_randB, rand_inptB'length));
                --
                --
                -- Break out the test cases
                --
                --

                --
                -- INSTRUCTION: JMP
                --
                if ( op = OP_JMP) then

                    temp_op := OpJMP;
                    temp_op(0) := '0';
                    temp_op(8 downto 4) := "00000";
                    ProgDB<= temp_op;
                    wait for 20 ns;
                    ProgDB <= rand_inptB & rand_inptA;
                    wait for 20 ns;
                    wait for 20 ns;

                --
                -- INSTRUCTION: RJMP
                --
                elsif (op = OP_RJMP) then

                    temp_op := OpRJMP;
                    temp_op(11 downto 0) := rand_inptA(11 downto 0);
                    ProgDB <= temp_op;
                    wait for 20 ns;
                    wait for 20 ns;

                --
                -- INSTRUCTION: IJMP
                --

                elsif (op = OP_IJMP) then

                    -- FProgDBst, do two LDIs to load the Z register
                    temp_op := OpLDI;
                    temp_op(7 downto 4) := "1110";
                    temp_op(11 downto 8) := rand_inptA(7 downto 4);
                    temp_op(3 downto 0) := rand_inptA(3 downto 0);
                    ProgDB <= temp_op;
                    wait for 20 ns;
                    temp_op(7 downto 4) := "1111";
                    temp_op(11 downto 8) := rand_inptB(7 downto 4);
                    temp_op(3 downto 0) := rand_inptB(3 downto 0);
                    ProgDB <= temp_op;
                    wait for 20 ns;

                    -- Now that Z is loaded and equals rand_inptB | rand_inptA
                    -- we can do the IJMP
                    ProgDB <= OpIJMP;
                    wait for 20 ns;
                    wait for 20 ns;

                --
                -- INSTRUCTION: CALL
                --

                elsif (op = OP_CALL) then
                    ProgDB <= OpCALL;
                    wait for 20 ns;
                    ProgDB <= rand_inptB & rand_inptA;
                    wait for 20 ns;
                    wait for 20 ns;
                    wait for 20 ns;

                --
                -- INSTRUCTION: RCALL
                --

                elsif (op = OP_RCALL) then
                    temp_op := OpRCALL;
                    temp_op(11 downto 0) := rand_inptA(11 downto 0);
                    ProgDB <= temp_op;
                    wait for 20 ns;
                    wait for 20 ns;
                    wait for 20 ns;

                --
                -- INSTRUCTION: ICALL
                --

                elsif( op = OP_ICALL) then
                    -- First, do two LDIs to load the Z register
                    temp_op := OpLDI;
                    temp_op(7 downto 4) := "1110";
                    temp_op(11 downto 8) := rand_inptA(7 downto 4);
                    temp_op(3 downto 0) := rand_inptA(3 downto 0);
                    ProgDB <= temp_op;
                    wait for 20 ns;
                    temp_op(7 downto 4) := "1111";
                    temp_op(11 downto 8) := rand_inptB(7 downto 4);
                    temp_op(3 downto 0) := rand_inptB(3 downto 0);
                    ProgDB <= temp_op;
                    wait for 20 ns;

                    ProgDB <= OpICALL;
                    wait for 20 ns;
                    wait for 20 ns;
                    wait for 20 ns;

                --
                -- INSTRUCTION: RET
                --

                elsif( op = OP_RET ) then

                    wait for 20 ns;
                    wait for 20 ns;
                    wait for 20 ns;
                    wait for 20 ns;

                --
                -- INSTRUCTION: RETI
                --
                elsif( op = OP_RETI ) then

                    wait for 20 ns;
                    wait for 20 ns;
                    wait for 20 ns;
                    wait for 20 ns;

                --
                -- INSTRUCTION: BRBC
                --
                elsif( op = OP_BRBC ) then

                    -- Will do two BRBCs to test to see
                    -- if it works. First one should not
                    -- branch, second will

                    -- First, need to set the bit of the
                    -- status register in question with a BSET

                    temp_op := OpBSET;
                    temp_op(6 downto 4) := rand_inptA(2 downto 0);
                    ProgDB <= temp_op;
                    wait for 20 ns;

                    -- Now the bit is set, so PC should not change
                    -- on this BRBC
                    temp_op := OpBRBC;
                    temp_op(2 downto 0) := rand_inptA(2 downto 0);
                    temp_op(9 downto 3) := rand_inptB(7 downto 0);
                    ProgDB <= temp_op;

                    -- wait for 40 ns to make sure it doesn't branch
                    wait for 20 ns;
                    wait for 20 ns;

                    -- Now clear the bit
                    temp_op := OpBCLR;
                    temp_op(6 downto 4) := rand_inptA(2 downto 0);
                    ProgDB <= temp_op;
                    wait for 20 ns;

                    -- And do another BRBC, and PC should update to 
                    -- add B value to it

                    -- Now the bit is set, so PC should not change
                    -- on this BRBC
                    temp_op := OpBRBC;
                    temp_op(2 downto 0) := rand_inptA(2 downto 0);
                    temp_op(9 downto 3) := rand_inptB(7 downto 0);
                    ProgDB <= temp_op;

                    wait for 20 ns;
                    wait for 20 ns;

                --
                -- INSTRUCTION: BRBS
                --
                elsif( OP = OP_BRBS ) then

                    -- Will do two BRBSs to test to see
                    -- if it works. First one should not
                    -- branch, second will

                    -- First, need to set the bit of the
                    -- status register in question with a BCLR

                    temp_op := OpBCLR;
                    temp_op(6 downto 4) := rand_inptA(2 downto 0);
                    ProgDB <= temp_op;
                    wait for 20 ns;

                    -- Now the bit is set, so PC should not change
                    -- on this BRBC
                    temp_op := OpBRBS;
                    temp_op(2 downto 0) := rand_inptA(2 downto 0);
                    temp_op(9 downto 3) := rand_inptB(7 downto 0);
                    ProgDB <= temp_op;

                    -- wait for 40 ns to make sure it doesn't branch
                    wait for 20 ns;
                    wait for 20 ns;

                    -- Now clear the bit
                    temp_op := OpBSET;
                    temp_op(6 downto 4) := rand_inptA(2 downto 0);
                    ProgDB <= temp_op;
                    wait for 20 ns;

                    -- And do another BRBC, and PC should update to 
                    -- add B value to it

                    -- Now the bit is set, so PC should not change
                    -- on this BRBC
                    temp_op := OpBRBS;
                    temp_op(2 downto 0) := rand_inptA(2 downto 0);
                    temp_op(9 downto 3) := rand_inptB(7 downto 0);
                    ProgDB <= temp_op;

                    wait for 20 ns;
                    wait for 20 ns;

                --
                -- INSTRUCTION: CPSE
                --
                elsif( op = OP_CPSE ) then

                    -- Do some LDIs to load registers to unequal values
                    temp_op := OpLDI;
                    temp_op(7 downto 4) := rand_inptA(4 downto 0);
                    temp_op(11 downto 8) := "1010";
                    temp_op(3 downto 0) := "1010";
                    ProgDB <= temp_op;
                    wait for 20 ns;
                    temp_op(7 downto 4) := rand_inptB(4 downto 0);
                    temp_op(11 downto 8) := "0101";
                    temp_op(3 downto 0) := "0101";
                    ProgDB <= temp_op;
                    wait for 20 ns;

                    -- Now, do a CPSE, and it should just increment PC by 1
                    -- and load the next instruction
                    temp_op := OpCPSE;
                    temp_op(3 downto 0) := rand_inptA(3 downto 0);
                    temp_op(9) := rand_inptA(4);
                    temp_op(8 downto 4) := rand_inptB(4 downto 0);
                    ProgDB <= temp_op;
                    wait for 20 ns;

                    -- Do an LDI to load registers to equal values
                    temp_op := OpLDI;
                    temp_op(7 downto 4) := rand_inptB(4 downto 0);
                    temp_op(11 downto 8) := "1010";
                    temp_op(3 downto 0) := "1010";
                    ProgDB <= temp_op;
                    wait for 20 ns;

                    -- Now, do a CPSE and it should increment the program 
                    -- counter by 2, since the next instruction will be a LDI
                    temp_op := OpCPSE;
                    temp_op(3 downto 0) := rand_inptA(3 downto 0);
                    temp_op(9) := rand_inptA(4);
                    temp_op(8 downto 4) := rand_inptB(4 downto 0);
                    ProgDB <= temp_op;
                    wait for 20 ns;

                    -- IR should not be updated, and this CPSE should 
                    -- last 2 clocks
                    ProgDB <= OpLDI;
                    wait for 20 ns;

                    -- Now this CPSE should last 3 clocks
                    temp_op := OpCPSE;
                    temp_op(3 downto 0) := rand_inptA(3 downto 0);
                    temp_op(9) := rand_inptA(4);
                    temp_op(8 downto 4) := rand_inptB(4 downto 0);
                    ProgDB <= temp_op;
                    wait for 20 ns;

                    -- IR should not be updated, and this CPSE should 
                    -- last 2 clocks
                    ProgDB <= OpADIW;
                    wait for 20 ns;
                    ProgDB <= rand_inptB & rand_inptA;
                    wait for 20 ns;

                --
                -- INSTRUCTION: SBRC
                --
                elsif( op = OP_SBRC ) then

                    -- First, set the bit, and make sure no skip occurs
                    temp_op := OpLDI;
                    temp_op(7 downto 4) := rand_inptA(4 downto 0);
                    temp_op(11 downto 8) := "0010";
                    temp_op(3 downto 0) := "0000";
                    ProgDB <= temp_op;
                    wait for 20 ns;

                    -- Do the skip
                    temp_op := OpSBRC;
                    temp_op(2 downto 0) := "101";
                    temp_op(8 downto 4) := rand_inptA(4 downto 0);
                    ProgDB <= temp_op;
                    wait for 20 ns;

                    -- Now it should load with the bit cleared
                    temp_op := OpLDI;
                    temp_op(7 downto 4) := rand_inptA(4 downto 0);
                    temp_op(11 downto 8) := "1101";
                    temp_op(3 downto 0) := "1111";
                    ProgDB <= temp_op;
                    wait for 20 ns;

                    -- It should do the skip
                    temp_op := OpSBRC;
                    temp_op(2 downto 0) := "101";
                    temp_op(8 downto 4) := rand_inptA(4 downto 0);
                    ProgDB <= temp_op;
                    wait for 20 ns;

                    -- This should be skipped
                    ProgDB <= OpADD;
                    wait for 20 ns;

                    -- This should be executed
                    ProgDB <= OpSUB;
                    wait for 20 ns;

                --
                -- INSTRUCTION: SBRS
                --
                elsif ( op = OP_SBRS ) then

                    -- First, clear the bit, and make sure no skip occurs
                    temp_op := OpLDI;
                    temp_op(7 downto 4) := rand_inptA(4 downto 0);
                    temp_op(11 downto 8) := "1111";
                    temp_op(3 downto 0) := "0111";
                    ProgDB <= temp_op;
                    wait for 20 ns;

                    -- Do the skip
                    temp_op := OpSBRS;
                    temp_op(2 downto 0) := "011";
                    temp_op(8 downto 4) := rand_inptA(4 downto 0);
                    ProgDB <= temp_op;
                    wait for 20 ns;

                    -- Now it should load with the bit set
                    temp_op := OpLDI;
                    temp_op(7 downto 4) := rand_inptA(4 downto 0);
                    temp_op(11 downto 8) := "0000";
                    temp_op(3 downto 0) := "1000";
                    ProgDB <= temp_op;
                    wait for 20 ns;

                    -- It should do the skip
                    temp_op := OpSBRS;
                    temp_op(2 downto 0) := "011";
                    temp_op(8 downto 4) := rand_inptA(4 downto 0);
                    ProgDB <= temp_op;
                    wait for 20 ns;

                    -- This should be skipped
                    ProgDB <= OpADD;
                    wait for 20 ns;

                    -- This should be executed
                    ProgDB <= OpSUB;
                    wait for 20 ns;

                end if;


            end loop;
        end loop;
    end process;

    -- MAKE THE CLOCK

    CLOCK_CLK : process
    begin

    -- this process generates a 20 ns period, 50% duty cycle clock
    -- only generate clock if still simulating

    if END_SIM = FALSE then
      clock <= '0';
      wait for 10 ns;
    else
      wait;
    end if;

    if END_SIM = FALSE then
      clock <= '1';
      wait for 10 ns;
    else
      wait;
    end if;

  end process;

end architecture;























