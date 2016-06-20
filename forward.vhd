library ieee; 
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Forward is
	
	port
	(
		-- Input ports
		rd_adr_ex	: in  std_logic_vector(4 downto 0); --adr rd registra iz exe
		rd_adr_mem	: in  std_logic_vector(4 downto 0); --adr rd registra iz mem
		rd_adr_wb	: in  std_logic_vector(4 downto 0); --adr rd registra iz wb
		
		rs1_adr: in  std_logic_vector(4 downto 0); --adrese rs reg iz decode faze
		rs2_adr: in  std_logic_vector(4 downto 0);
		
		fwd_rs1_ex : out std_logic;
		fwd_rs1_mem : out std_logic;
		fwd_rs1_wb : out std_logic;
		
		fwd_rs2_ex : out std_logic;
		fwd_rs2_mem : out std_logic;
		fwd_rs2_wb : out std_logic;
		
		
		stall_if: out std_logic := '0';
		stall_id: out std_logic := '0';
		
		valid:  in std_logic
		
		
	);
end Forward;



architecture rtl of Forward is

signal ind : std_logic_vector (1 downto 0);

begin

	process(rd_adr_ex,rd_adr_mem,rd_adr_wb,rs1_adr,rs2_adr)
	
	begin
		stall_id <= '0';
		stall_if <= '0';
		fwd_rs1_ex <= '0';
		fwd_rs1_mem <= '0';
		fwd_rs1_wb <= '0';
		
		fwd_rs2_ex <= '0';
		fwd_rs2_mem <= '0';
		fwd_rs2_wb <= '0';
		ind <= "00";
		
		if(rd_adr_ex=rs1_adr and rd_adr_ex /= "ZZZZZ" and rs1_adr /= "ZZZZZ") then 
			if (valid = '1') then
				fwd_rs1_ex <= '1';
				ind <= "01";
			else
				fwd_rs1_ex <= '0';
				stall_if <= '1';
				stall_id <= '1';
				ind <= "01";
			end if;
		elsif(rd_adr_mem=rs1_adr and rd_adr_mem /= "ZZZZZ"and rs1_adr /= "ZZZZZ") then 
			fwd_rs1_mem <= '1';
			ind <= "10";
		elsif(rd_adr_wb=rs1_adr and rd_adr_wb /= "ZZZZZ" and rs1_adr /= "ZZZZZ") then 
			fwd_rs1_wb <= '1';
			ind <= "11";
		end if;
		
		if(rd_adr_ex=rs2_adr and rd_adr_ex /= "ZZZZZ" and rs2_adr /= "ZZZZZ") then 
			if (valid = '1') then
				fwd_rs2_ex <= '1';
				ind <= "01";
			else
				fwd_rs2_ex <= '0';
				stall_if <= '1';
				stall_id <= '1';
				ind <= "01";
			end if;
		elsif(rd_adr_mem=rs2_adr and rd_adr_mem /= "ZZZZZ"and rs2_adr /= "ZZZZZ") then 
			fwd_rs2_mem <= '1';
			ind <= "10";
		elsif(rd_adr_wb=rs2_adr and rd_adr_wb /= "ZZZZZ" and rs2_adr /= "ZZZZZ") then 
			fwd_rs2_wb <= '1';
			ind <= "11";
		end if;
		
	end process;
end rtl;
