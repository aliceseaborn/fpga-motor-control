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
		-- clear			: in STD_LOGIC; 	-- For resetting motor control
		
		--|Rotary Shaft encoder
		A				: in STD_LOGIC; -- Channel A of the Rotary
		B				: in STD_LOGIC; -- Channel B of the Rotary
		
		--|Outputs
		-- PWM 			: out  STD_LOGIC := '0' 	-- The generated signal
		
		--|EXPERIMENTAL OUTPUT
		CW_state		: out STD_LOGIC; -- Used to print CW
		CCW_state		: out STD_LOGIC; -- Used to print CCW
		DUTY_state		: out STD_LOGIC_VECTOR (3 downto 0); -- Vector displays Duty_Cycle in binary
);
End Spartan;

Architecture Behavioral of Spartan is

-- Store percentage on and off
-- signal ONN				: STD_LOGIC_VECTOR (25 downto 0);
-- signal OFF				: STD_LOGIC_VECTOR (25 downto 0);

-- signal count			: STD_LOGIC_VECTOR (25 downto 0); -- Used to measure ticks for the counter
-- signal produce			: STD_LOGIC := '0'; -- Produced signal, zero upon declaration
signal Duty_Cycle		: INTEGER range 0 to 100;

-- Rotary tick-detector control
signal code      		: std_logic_vector(1 downto 0) := "00"; -- Stores rotary wave-form values
signal code_prev 		: std_logic_vector(1 downto 0) := "00"; -- Stores last states of wave-form values
signal MOV_del  		: std_logic := '0';
signal MOV				: std_logic;
signal CW, CCW	 		: std_logic := '1'; -- Clock-wise and Counter-clock-wise states interpreted from the A & B rotary inputs

-- Counter for PWM Counter
-- signal counter			: STD_LOGIC_VECTOR(25 downto 0);

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

-- Display States
CW_state <= CW;
CCW_state <= CCW;

with Duty_Cycle select
	DUTY_state <= "0000" when '0', -- Print all zero when 0
				  "0001" when '10', -- Print 1 when 10
				  "0010" when '20', -- Print 2 when 20
				  "0011" when '30', -- Etc.
				  "0100" when '40',
				  "0101" when '50',
				  "0110" when '60',
				  "0111" when '70',
				  "1000" when '80',
				  "1001" when '90',
				  "1010" when '100',
				  "1111" when others; -- Print all 1 when error

End Behavioral;