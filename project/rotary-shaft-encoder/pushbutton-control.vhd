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
		
		--|Pushbuttons
		BTN_EAST		: in STD_LOGIC;		-- East pushbutton to increment
		BTN_WEST		: in STD_LOGIC;		-- West pushbutton to decrement
		
		--|Outputs
		PWM 			: out  STD_LOGIC 	-- The generated signal
);
End Spartan;

Architecture Behavioral of Spartan is

-- Store percentage on and off
signal ONN				: STD_LOGIC_VECTOR (25 downto 0); -- Ticks spent on active-high
signal OFF				: STD_LOGIC_VECTOR (25 downto 0); -- Ticks spent on active-low

signal count			: STD_LOGIC_VECTOR (25 downto 0); -- Used to measure ticks for the counter
signal produce			: STD_LOGIC := '0'; 			  -- Produced signal, zero upon declaration
signal Duty_Cycle		: INTEGER range 0 to 100 := 100;  -- The percentage of time spent on active-high

Begin

MAIN: process (CLK_50MHZ)
begin
	--|BUTTON LOGIC
	--   Receives input from the EAST and WEST pushbuttons and adjusts
	--   the Duty_Cycle accordingly. If the EAST button is pressed then
	--   the Duty_Cycle is increased by 10. If the WEST button is pressed
	--   then the Duty_Cycle is decreased by 10.
	
	-- If EAST is pressed but WEST if not and the Duty_Cycle can be increased
	if (BTN_EAST = '1' AND BTN_WEST = '0' AND Duty_Cycle /= '100') then
		Duty_Cycle <= Duty_Cycle + 10; -- Increase Duty_Cycle by ten percent
	-- If EAST is not pressed but WEST is and the Duty_Cycle can be decreased
	elsif (BTN_EAST = '0' AND BTN_WEST = '1' AND Duty_Cycle /= '0') then
		Duty_Cycle <= Duty_Cycle - 10; -- Decrease Duty_Cycle by ten percent
	end if;
	
	--|DUTY CYCLE Splitter
	--   Simply assigns percentages of the clock to variables ONN and
	--   OFF. These will be used later in the counter/PWM_creater.
	--   We could develop a complex algorithm to do what I'm about
	--   to do but "NO NEW THEORIES!!!", and I happen to agree here.
	--   To do this we need to instantiate two variables, ONN and OFF.
	
	-- EMERGENCY NOTE: THE FOLLOWING VALUES PRODUCE A 1 HERTZ SIGNAL AND NEED ADJUSTMENT.
	-- 				   PLEASE ADJUST BEFORE PRESENTING ON THE MOTOR!!!
	
	if (Duty_Cycle = 10) then -- Set ONN to 10% of 50million and OFF to 90% of 50million.
		ONN <= "00010011000100101101000000"; -- Multiple bit must be in 
		OFF <= "10101011101010010101000000";
	elsif (Duty_Cycle = 20) then -- Set ONN to 20% of 50million and OFF to 80% of 50million.
		ONN <= "00100110001001011010000000";
		OFF <= "10011000100101101000000000";
	elsif (Duty_Cycle = 30) then -- Set ONN to 30% of 50million and OFF to 70% of 50million.
		ONN <= "00111001001110000111000000";
		OFF <= "10000101100000111011000000";
	elsif (Duty_Cycle = 40) then -- Set ONN to 40% of 50million and OFF to 60% of 50million.
		ONN <= "01001100010010110100000000";
		OFF <= "01110010011100001110000000";
	elsif (Duty_Cycle = 50) then -- Set ONN to 50% of 50million and OFF to 50% of 50million.
		ONN <= "00000000000001001110001000";
		OFF <= "00000000000001001110001000";
	elsif (Duty_Cycle = 60) then -- Set ONN to 60% of 50million and OFF to 40% of 50million.
		ONN <= "01110010011100001110000000";
		OFF <= "01001100010010110100000000";
	elsif (Duty_Cycle = 70) then -- Set ONN to 70% of 50million and OFF to 30% of 50million.
		ONN <= "10000101100000111011000000";
		OFF <= "00111001001110000111000000";
	elsif (Duty_Cycle = 80) then -- Set ONN to 80% of 50million and OFF to 20% of 50million.
		ONN <= "10011000100101101000000000";
		OFF <= "00100110001001011010000000";
	elsif (Duty_Cycle = 90) then -- Set ONN to 90% of 50million and OFF to 10% of 50million.
		ONN <= "10101011101010010101000000";
		OFF <= "00010011000100101101000000";
	elsif (Duty_Cycle = 100) then -- Set ONN to 100% of 50million and OFF to 0% of 50million.
		ONN <= "00000000000010011100010000";
		OFF <= "00000000000000000000000000";
	else -- Set ONN to 0% of 50million and OFF to 100% of 50million.
		ONN <= "00000000000000000000000000";
		OFF <= "10111110101111000010000000";
	end if;

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
	
end process MAIN;
	
-- Now set the produced signal value to the PWM output
PWM <= produce;

End Behavioral;