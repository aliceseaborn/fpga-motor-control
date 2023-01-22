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
		A				: in STD_LOGIC; -- Channel A of the Rotary
		B				: in STD_LOGIC; -- Channel B of the Rotary
		
		--|Outputs
		PWM 			: out  STD_LOGIC := '0' 	-- The generated signal
);
End Spartan;

Architecture Behavioral of Spartan is

-- Store percentage on and off
signal ONN				: STD_LOGIC_VECTOR (25 downto 0);
signal OFF				: STD_LOGIC_VECTOR (25 downto 0);

signal count			: STD_LOGIC_VECTOR (25 downto 0); -- Used to measure ticks for the counter
signal produce			: STD_LOGIC := '0'; -- Produced signal, zero upon declaration
signal Duty_Cycle		: INTEGER range 0 to 100;

-- Rotary tick-detector control
signal code      		: std_logic_vector(1 downto 0) := "00"; -- Stores rotary wave-form values
signal code_prev 		: std_logic_vector(1 downto 0) := "00"; -- Stores last states of wave-form values
signal MOV_del  		: std_logic := '0';
signal MOV				: std_logic;
signal CW, CCW	 		: std_logic := '1'; -- Clock-wise and Counter-clock-wise states interpreted from the A & B rotary inputs

-- Counter for PWM Counter
signal counter			: STD_LOGIC_VECTOR(25 downto 0);

Begin

--|ROTARY Tick Detection
--   The following code was adapted from Ben Jordan, Altium Limited on 11/26/2015.
Rotary_turn: process(CLK_50MHZ) is -- Receives clock ticks
begin
	if rising_edge(CLK_50MHZ) then -- If there is a rising edge
		code_prev <= code; -- Refresh the storage of previous states
		code(0) <= A; -- Reassign code vector with current rotary states
		code(1) <= B; -- Reassign code vector with current rotary states
		MOV <= MOV_del;
		if (code(0) = '1' and code_prev(0) = '0') then -- A rising edge
			if (B='0') then -- rotary forward CW
				CW <= '1';
				MOV_del <= '1';
				CCW <= '0';
			elsif (B='1') then -- rotary reverse CCW
				CW <= '0';
				MOV_del <= '1';
				CCW <= '1';
			end if;
		elsif (code(1) = '1' and code_prev(1) = '0') then -- B rising edge
			if (A='1') then -- rotary forward CW
				CW <= '1';
				MOV_del <= '1';
				CCW <= '0';
			elsif (A='0') then -- rotary reverse CCW
				CW <= '0';
				MOV_del <= '1';
				CCW <= '1';
			end if;
		elsif (code(0) = '0' and code_prev(0) = '1') then -- A falling edge
			if (B='1') then -- rotary forward CW
				CW <= '1';
				MOV_del <= '1';
				CCW <= '0';
			elsif (B='0') then -- rotary reverse CCW
				CW <= '0';
				MOV_del <= '1';
				CCW <= '1';
			end if;
		elsif (code(1) = '0' and code_prev(1) = '1') then -- B falling edge
			if (A='0') then -- rotary forward CW
				CW <= '1';
				MOV_del <= '1';
				CCW <= '0';
			elsif (A='1') then -- rotary reverse CCW
				CW <= '0';
				MOV_del <= '1';
				CCW <= '1';
			end if;
		else -- If there is no rising or falling edge for rotary (standing still)
			CW <= '0'; -- Not forward (Clock-Wise)
			CCW <= '0'; -- Nor backward (Counter-Clock-Wise) 
			MOV_del <= '0';
		end if;           
	end if;
end process;


--|ROTARY LOGIC
--   If CW or CCW change then this process is called.
--   (This is called a sessitivity list)
Rotary_Logic: process (CW, CCW) is
begin
	-- If user attempts to increase duty cycle and it's not already at it's maximum then
	if ((CW = '1') and (Duty_Cycle /= 100)) then
		-- Increase by ten percent
		Duty_Cycle <= (Duty_Cycle + 10);
	-- If user attemtps to decrease duty cycle and it's not at it's minimum then
	elsif ((CCW = '1') and (Duty_Cycle /= 0)) then
		-- Decrease by ten percent
		Duty_Cycle <= (Duty_Cycle - 10);
	else
		Duty_Cycle <= Duty_Cycle;
	end if;
	
end process Rotary_Logic;

--|DUTY CYCLE Splitter
--   Simply assigns percentages of the clock to variables ONN and
--   OFF. These will be used later in the counter/PWM_creater.
--   We could develop a complex algorithm to do what I'm about
--   to do but "NO NEW THEORIES!!!", and I happen to agree here.
--   To do this we need to instantiate two variables, ONN and OFF.
--   Process is called under the sensitivity of Duty_Cycle, if this
--   variable changes then the process runs.
Duty_Cycle_Splitter: process (Duty_Cycle) is
begin

	if (Duty_Cycle = 10) then -- Set ONN to 10% of 50million and OFF to 90% of 50million. (CLK_50MHZ)
		ONN <= "00010011000100101101000000"; -- Multiple bit must be in 
		OFF <= "10101011101010010101000000";
	elsif (Duty_Cycle = 20) then -- Set ONN to 20% of 50million and OFF to 80% of 50million. (CLK_50MHZ)
		ONN <= "00100110001001011010000000";
		OFF <= "10011000100101101000000000";
	elsif (Duty_Cycle = 30) then -- Set ONN to 30% of 50million and OFF to 70% of 50million. (CLK_50MHZ)
		ONN <= "00111001001110000111000000";
		OFF <= "10000101100000111011000000";
	elsif (Duty_Cycle = 40) then -- Set ONN to 40% of 50million and OFF to 60% of 50million. (CLK_50MHZ)
		ONN <= "01001100010010110100000000";
		OFF <= "01110010011100001110000000";
	elsif (Duty_Cycle = 50) then -- Set ONN to 50% of 50million and OFF to 50% of 50million. (CLK_50MHZ)
		ONN <= "01011111010111100001000000";
		OFF <= "01011111010111100001000000";
	elsif (Duty_Cycle = 60) then -- Set ONN to 60% of 50million and OFF to 40% of 50million. (CLK_50MHZ)
		ONN <= "1110010011100001110000000";
		OFF <= "1001100010010110100000000";
	elsif (Duty_Cycle = 70) then -- Set ONN to 70% of 50million and OFF to 30% of 50million. (CLK_50MHZ)
		ONN <= "10000101100000111011000000";
		OFF <= "111001001110000111000000";
	elsif (Duty_Cycle = 80) then -- Set ONN to 80% of 50million and OFF to 20% of 50million. (CLK_50MHZ)
		ONN <= "10011000100101101000000000";
		OFF <= "100110001001011010000000";
	elsif (Duty_Cycle = 90) then -- Set ONN to 90% of 50million and OFF to 10% of 50million. (CLK_50MHZ)
		ONN <= "10101011101010010101000000";
		OFF <= "10011000100101101000000";
	elsif (Duty_Cycle = 100) then -- Set ONN to 100% of 50million and OFF to 0% of 50million. (CLK_50MHZ)
		ONN <= "10111110101111000010000000";
		OFF <= "0";
	else -- Set ONN to 0% of 50million and OFF to 100% of 50million. (CLK_50MHZ)
		ONN <= "0";
		OFF <= "10111110101111000010000000";
	end if;
end process Duty_Cycle_Splitter;

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
