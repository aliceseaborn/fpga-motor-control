-- ----------------------------------
-- PWM Control
-- ----------------------------------

Library IEEE;
Use IEEE.STD_LOGIC_1164.ALL;
Use IEEE.STD_LOGIC_ARITH.ALL; -- Base 10 functions (+/-/etc.)
Use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Spartan Board
Entity Spartan is
port (
		--|Inputs
		CLK_50MHZ 		: in STD_LOGIC; 	-- For receiving the main Spartan clock signal
		clear			: in STD_LOGIC; 	-- For resetting motor control
		
		--|Rotary Shaft encoder
		-- A				: in STD_LOGIC; -- Channel A of the Rotary
		-- B				: in STD_LOGIC; -- Channel B of the Rotary
		
		--|Outputs
		PWM 			: out  STD_LOGIC := '0' 	-- The generated signal
);
End Spartan;

Architecture Behavioral of Spartan is

-- Store percentage on and off
signal ONN				: STD_LOGIC_VECTOR (25 downto 0) := "01001100010010110100000000";
signal OFF				: STD_LOGIC_VECTOR (25 downto 0) := "10111110101111000010000000"

signal count			: STD_LOGIC_VECTOR (25 downto 0); -- Used to measure ticks for the counter
signal produce			: STD_LOGIC := '0'; -- Produced signal, zero upon declaration
signal Duty_Cycle		: INTEGER range 0 to 100;

-- Rotary tick-detector control
-- signal code      		: std_logic_vector(1 downto 0) := "00"; -- Stores rotary wave-form values
-- signal code_prev 		: std_logic_vector(1 downto 0) := "00"; -- Stores last states of wave-form values
-- signal MOV_del  		: std_logic := '0';
-- signal MOV				: std_logic;
-- signal CW, CCW	 		: std_logic := '1'; -- Clock-wise and Counter-clock-wise states interpreted from the A & B rotary inputs

-- Counter for PWM Counter
-- signal counter			: STD_LOGIC_VECTOR(25 downto 0);

Begin

--|PWM COUNTER
--   The purpose of this process is to design PWM widths. It will
--   set the PWM value to one for the time it takes to count to the
--   number ONN, then switch PWM to zero and count to the number OFF
--   then repeat.
--   There was confusion as to how we should differentiate between the 
--   counter counting ONN or counting OFF. The solution was to instantiate
--   a control structure and set PWM to 0 upon declaration, see the signal
--   declaration before architecture's BEGIN statement. By assigning a 
--   default value for PWM we effectively make it possible to define a 
--   control structure without worrying about errors on the first 
--   declaration of the following process.
PWM_Counter: process (CLK_50MHZ) is
begin
	
	-- If clear is active HIGH then stop the motor
	if (clear = '1') then
		-- Reset counter
		count <= "00000000000000000000000000";
		-- Set PWM control to active LOW
		produce <= '0';
	
	-- If clear is otherwise not active HIGH
	elsif (clear = '0') then
		-- Then begin the counting proceedure.
		-- Because PWM is already assigned the value of zero, we can
		-- begin a control structure on PWM to distinguish between
		-- counting ONN and counting OFF.
		
		-- When CLK_50MHZ rises then measure PWM 
		if rising_edge(CLK_50MHZ) then
		
			--||COUNTING TO OFF
			if (produce = '0' and count < OFF) then
				-- Add one to count and continue
				count <= count + 1;
			elsif (produce = '0' and count = OFF) then
				-- Assign active HIGH to produce
				produce <= not produce;
				-- Reset count
				count <= "00000000000000000000000000";
				
			--||COUNTING TO ONN
			elsif (produce = '1' and count < ONN) then
				-- Add one to count and continue
				count <= count + 1;
			elsif (produce = '1' and count = ONN) then
				-- Assign active LOW to produce
				produce <= not produce;
				-- Reset count
				count <= "00000000000000000000000000";
			end if;
		end if;
	end if;
end process PWM_Counter;
	
-- Now set the produced signal value to the PWM output
PWM <= produce;

End Behavioral;