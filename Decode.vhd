library ieee; 
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.instrSet.all;

entity Decode is
	generic
	(
		reg_adr_length	: integer := 5;
		addr_length: integer := 32;
		instr_length : integer := 32;
		reg_data_length	: integer  :=	32
	);


	port
	(
		clk : in std_logic;
		reset: in std_logic;
		PC_addr: in std_logic_vector((addr_length-1) downto 0); --Vrednost PC dobijena iz if faze
		instr_from_if:in std_logic_vector((instr_length-1) downto 0); -- instrukcija iz if-a
		
		--PC ka EXE fazi za bezuslovne skokove
		PC_addr_out: out std_logic_vector((addr_length-1) downto 0);
		
		stall: in std_logic;
		flush_out: out std_logic;
		flush_if: in std_logic;
		flush: in std_logic; --ne koristi se
		
		wr: in std_logic;
		wr_adr: in std_logic_vector((reg_adr_length-1) downto 0); --adresa registra za upis u regfile
		wr_data: in std_logic_vector((reg_data_length-1) downto 0);
		rs1_data: out std_logic_vector((reg_data_length-1) downto 0); -- vrednost registra ka exe
		rs2_data: out std_logic_vector((reg_data_length-1) downto 0); -- vrednost registra ka exe
		
		
		
		forward_rs1_ex: in std_logic;
		forward_rs1_mem: in std_logic;
		forward_rs1_wb: in std_logic;
		
		fwd_value_ex: in std_logic_vector(31 downto 0);
		fwd_value_mem: in std_logic_vector(31 downto 0);
		fwd_value_wb: in std_logic_vector(31 downto 0);
		
		forward_rs2_ex: in std_logic;
		forward_rs2_mem: in std_logic;
		forward_rs2_wb: in std_logic;
		
		opcode_out : out std_logic_vector((opcode_length-1) downto 0);
		rd_adr: out std_logic_vector(4 downto 0);
		imm_value_out : out std_logic_vector (15 downto 0);
		op1_adr_out : out std_logic_vector((reg_adr_length-1) downto 0); -- adr registra -> forward 
		op2_adr_out : out std_logic_vector((reg_adr_length-1) downto 0); -- adr registra -> forward 
		op1_data: inout std_logic_vector((reg_data_length-1) downto 0); 
		op2_data: inout std_logic_vector((reg_data_length-1) downto 0);
		
		pc_predicted : in std_logic_vector (addr_length-1 downto 0); -- prediktovana vrednost pc-a
		pc_predicted_out : out std_logic_vector (addr_length-1 downto 0);
		branch_predicted : in std_logic; -- predvidjanje da li ce doci do skoka
		branch_predicted_out : out std_logic;
		misprediction : in std_logic;
		
		idle : in std_logic
	);
end Decode;


architecture impl of Decode is
	
	signal op1_adr, op2_adr : std_logic_vector((reg_adr_length-1) downto 0);
	signal imm_value : std_logic_vector (15 downto 0);
	signal flush_next : std_logic;
	signal instr, instr_next : std_logic_vector((instr_length-1) downto 0);
	
	
begin

	regFile: entity work.Regfile(rtl)
	port map (
		reset=>reset,
		rd=>'1',
		wr=>wr,
		op1_rd_adr=>op1_adr,
		op2_rd_adr=>op2_adr,
		wr_adr=>wr_adr,
		wr_data=>wr_data,
		op1_data=>op1_data,
		op2_data=>op2_data
	);
	
	
	
	process(clk, reset) is
		variable opcode : std_logic_vector (5 downto 0);
	begin
		if (reset = '1') then
			op1_adr <= (others=> 'Z');
			op2_adr <= (others=> 'Z');
			rd_adr <= (others=> 'Z');
			
		elsif (rising_edge(clk)) then
		
			opcode := instr((instr_length-1) downto (instr_length-opcode_length));
			opcode_out <= opcode;
			op1_adr <= (others=> 'Z');
			op2_adr <=	(others=> 'Z');
			rd_adr <=	(others=> 'Z');
			PC_addr_out <= PC_addr;
			
			pc_predicted_out <= pc_predicted;
			branch_predicted_out <= branch_predicted;
		if (idle = '0') then	
			if (opcode = "000000") then -- load
				op1_adr <= instr (20 downto 16);
				rd_adr <= instr (25 downto 21);
				imm_value <= instr (15 downto 0);
			end if;
			if (opcode = "000001" or (opcode >= "101000" and opcode <= "101101")) then -- store, instrukcije uslovnog skoka
				op1_adr <= instr (20 downto 16);
				op2_adr <= instr (15 downto 11);
				imm_value(15 downto 11) <= instr(25 downto 21);
				imm_value(10 downto 0) <= instr( 10 downto 0);
			end if;
			if (opcode = "000100") then -- mov
				op1_adr <= instr (20 downto 16);
				rd_adr <= instr (25 downto 21);
			end if;
			if (opcode = "000101") then -- movi
				imm_value <= instr(15 downto 0);
				rd_adr <= instr (25 downto 21);
			end if;
			if (opcode = "001000" or opcode = "001001" or (opcode >= "010000" and opcode <= "010010")) then --add, sub, and, or, xor
				op1_adr <= instr (20 downto 16);
				op2_adr <= instr (15 downto 11);
				rd_adr <= instr (25 downto 21);
			end if;
			if (opcode = "010011") then --not
				op1_adr <= instr (20 downto 16);
				rd_adr <= instr (25 downto 21);
			end if;
			
			if (opcode = "001100" or opcode = "001101") then --addi, subi
				op1_adr <= instr (20 downto 16);
				imm_value <= instr (15 downto 0);
				rd_adr <= instr (25 downto 21);
			end if;
			if (opcode >= "011000" and opcode <= "011100") then --pomeracke instrukcije
				op1_adr <= instr (25 downto 21);
				imm_value(4 downto 0) <= instr (15 downto 11);
				imm_value(15 downto 5)<= (others => '0');
				rd_adr <= instr (25 downto 21);
			end if;
			if (opcode = "100000" or opcode = "100001") then --jmp, jsr
				op1_adr <= instr(20 downto 16);
				imm_value <= instr (15 downto 0);
			end if;
			if (opcode = "100100") then --push
				op1_adr <= instr (20 downto 16);
			end if;
			
			if (opcode = "100101") then --pop
				rd_adr <= instr (25 downto 21);
			end if;
			
			instr_next <= instr;
			
			if(stall='1') then
				op1_adr <= op1_adr; 
				op2_adr <= op2_adr;
				instr_next <= instr_next;
			end if;
			
			
			--rts nema prosledjivanje vrednosti registra
		
			if(misprediction ='1' or flush_if='1') then
				flush_next<='1';
			else
				flush_next<='0';
			end if;
			
		end if;
		end if;
	end process;
	op1_adr_out <= op1_adr;
	op2_adr_out <= op2_adr;
	imm_value_out <= imm_value;
	
	rs1_data <= fwd_value_ex when forward_rs1_ex = '1' else
					fwd_value_mem when forward_rs1_mem = '1' else
					fwd_value_wb when forward_rs1_wb = '1' else 
					op1_data;
					
	rs2_data <= fwd_value_ex when forward_rs2_ex = '1' else
					fwd_value_mem when forward_rs2_mem = '1' else
					fwd_value_wb when forward_rs2_wb = '1' else 
					op2_data;
	
	flush_out <= '1' when stall = '1' else flush_next;
	instr <= instr_from_if when stall = '0' else instr_next;
	
end impl;

