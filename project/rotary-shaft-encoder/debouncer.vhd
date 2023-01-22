-- ---------------------------
-- Debouncer
-- ---------------------------

-- Assuming three transitions per bounce
-- Spartan Board
Entity Spartan is
port (
		--|Inputs
		CLK_50MHZ 		: in STD_LOGIC; -- For receiving the main Spartan clock signal
		
		--|Rotary Shaft encoder
		A				: in STD_LOGIC; -- Channel A of the Rotary
		B				: in STD_LOGIC; -- Channel B of the Rotary
);
End Spartan;

Architecture Behavioral of Spartan is

-- Signal assignment
signal D_Input			: STD_LOGIC_VECTOR (2 downto 0);
signal Q_Output			: STD_LOGIC_VECTOR (2 downto 0);
signal ROT_Conclusion	: STD_LOGIC;

-- Rotary tick-detector control
signal code      		: std_logic_vector(1 downto 0) := "00"; -- Stores rotary wave-form values
signal code_prev 		: std_logic_vector(1 downto 0) := "00"; -- Stores last states of wave-form values
signal MOV_del  		: std_logic := '0';
signal MOV				: std_logic;
signal CW, CCW	 		: std_logic := '1'; -- Clock-wise and Counter-clock-wise states interpreted from the A & B rotary inputs

-- Define D Flip Flop Component
Component DFF
	Port (
		D			: in	STD_LOGIC; -- DFF Input
		Clk			: in	STD_LOGIC; -- Clock Input
		Q			: out	STD_LOGIC  -- Output
	);
End Component;

Begin

-- Reset ROT_Conclusion to zero
ROT_Conclusion <= '0';

--|ROTARY Tick Detection
--   The following code was adapted from Ben Jordan, Altium Limited on 11/26/2015.
Rotary_turn: process(CLK_50MHZ) is -- Receives clock ticks
begin
	if (rising_edge(CLK_50MHZ) AND ROT_Conclusion = '1') then -- If there is a rising edge
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

-- We need to find a way to link external input CW_state and CCW_state with
-- the multiple DFFs.
-- (NOTE: This may destroy our ability to differentiate between CW_state and CCW_state)
D_Input(0) <= CW OR CCW; -- Here we are linking the input from the rotary shaft encoder into the first DFF
D_Input(1) <= Q_Output(0); -- Link the output of the first DFF into the second
D_Input(2) <= Q_Output(1); -- Link the output of the second DFF into the third


DFF1: DFF
port map (
	D => D_Input(0),
	Q => Q_Output(0),
	Clk => CLK_50MHZ
);
DFF2: DFF
port map (
	D => D_Input(1),
	Q => Q_Output(1),
	Clk => CLK_50MHZ
);
DFF3: DFF
port map (
	D => D_Input(2),
	Q => Q_Output(2),
	Clk => CLK_50MHZ
);

-- Pass the conclusion into an and gate as per the Debouncer logic
ROT_Conclusion <= (Q_Output(0) AND Q_Output(1) AND Q_Output(2));

End Behavioral;
	
	