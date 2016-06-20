library ieee; 
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity cpu is
	generic
	(
		reg_adr_length	: integer := 5;
		addr_length: integer := 32;
		opcode_length: integer := 6;
		instr_length : integer := 32;
		reg_data_length	: integer  :=	32;
		data_length	: integer  :=	32
	);


	port
	(
		--ulazni portovi (ulaz u if fazu)
		clk : in std_logic;
		reset: in std_logic;
		
		rd_mem : out std_logic;
		wr_mem : out std_logic;
		addr_bus : out std_logic_vector(31 downto 0);
		data_bus_out: out std_logic_vector(31 downto 0);
		data_bus_in : in std_logic_vector(31 downto 0);
		
		ird : out std_logic;
		IF_addr: out std_logic_vector(31 downto 0);
		instr_IF_cache : in std_logic_vector(31 downto 0);
		initial_PC: in std_logic_vector(31 downto 0);
		stop : out std_logic

	);
end cpu;


architecture rtl of cpu is


	signal pc_out : std_logic_vector(31 downto 0);
	signal instr_IF_decode : std_logic_vector(31 downto 0);
	signal wr : std_logic;
	signal wr_adr : std_logic_vector(4 downto 0);
	signal wr_data : std_logic_vector(31 downto 0);
	
	signal rs1_data : std_logic_vector(31 downto 0);
	signal rs2_data : std_logic_vector(31 downto 0);
	
	

	
	signal opcode_s : std_logic_vector((opcode_length-1) downto 0);--out iz decode
	signal rd_adr : std_logic_vector(4 downto 0);--out iz decode
	signal imm_value_out : std_logic_vector (15 downto 0);--out iz decode
	signal PC_addr_out: std_logic_vector((addr_length-1) downto 0);
	
	signal opcode_ex : std_logic_vector((opcode_length-1) downto 0);--out iz exe
	signal rd_adr_ex : std_logic_vector(4 downto 0);--out iz exe
	signal ar_log : std_logic;--out iz exe
	signal brnch : std_logic;--out iz exe
	signal load : std_logic;--out iz exe
	signal valid : std_logic;--out iz exe
	
	--out iz mem
	
	signal opcode_mem_out: std_logic_vector((opcode_length-1) downto 0);
	signal rd_adr_mem_out: std_logic_vector(4 downto 0);
	signal rd_reg_mem: std_logic_vector(31 downto 0);
	signal data_to_wb: std_logic_vector(31 downto 0);
	signal flush_mem_out: std_logic;
	signal ar_log_out: std_logic;
	signal load_out: std_logic;
	
	--out iz WB
	signal reg_data : std_logic_vector (data_length-1 downto 0); 
	signal reg_addr : std_logic_vector (reg_adr_length-1 downto 0); 
	
	signal stall_if : std_logic;
	signal flush_if_decode : std_logic;
	signal stall_id : std_logic;
	signal flush_id_exe : std_logic;
	signal flush_id : std_logic;
	
	signal forward_rs1_ex: std_logic;
	signal forward_rs1_mem: std_logic;
	signal forward_rs1_wb: std_logic;
	
	signal forward_rs2_ex: std_logic;
	signal forward_rs2_mem: std_logic;
	signal forward_rs2_wb: std_logic;
	
	
	signal st_value : std_logic_vector((data_length - 1) downto 0);
	signal data_alu_out : std_logic_vector((data_length - 1) downto 0);
	signal flush_ex : std_logic;
	signal op1_adr_out :std_logic_vector (reg_adr_length-1 downto 0); 
	signal op2_adr_out :std_logic_vector (reg_adr_length-1 downto 0);
	
	signal op1_data : std_logic_vector(31 downto 0);
	signal op2_data : std_logic_vector(31 downto 0);
	
	signal pc_from_if: std_logic_vector(addr_length-1 downto 0 ); -- salje se prediktoru
	signal update_predictor: std_logic; -- signalizira da treba updateovati prediktor
	signal update_value: std_logic_vector(63 downto 0); -- vrednosti za koji ulaz se radi update 
	signal branch_taken: std_logic; -- da li je doslo do skoka
	signal branch_addr: std_logic_vector(addr_length-1 downto 0 );
	signal branch_addr_if_decode: std_logic_vector(addr_length-1 downto 0 );
	signal branch_addr_decode_exe: std_logic_vector(addr_length-1 downto 0 );
	signal hit: std_logic;
	signal branch_predicted_pred_if : std_logic;
	signal branch_predicted_if_decode : std_logic;
	signal branch_predicted_decode_exe : std_logic;
	
	signal misprediction : std_logic;
	signal branch_pc : std_logic_vector (addr_length-1 downto 0);
	
	signal idle : std_logic;
	
begin

	if_jedinica: entity work.if_jedinica(impl)
	port map (
		clk,reset,initial_PC,IF_addr,instr_IF_cache,
		ird,pc_out,instr_IF_decode,stall_if,flush_if_decode,
		pc_from_if,
		branch_addr,branch_addr_if_decode,branch_predicted_pred_if,branch_predicted_if_decode,
		misprediction,branch_pc,idle
	);
	
	decode_jedinica: entity work.Decode(impl)
	port map (
		clk,reset,pc_out,instr_IF_decode,PC_addr_out,stall_id,flush_id_exe,flush_if_decode,flush_id,
		wr,wr_adr,wr_data,rs1_data,rs2_data,
		forward_rs1_ex,forward_rs1_mem,forward_rs1_wb,
		data_alu_out,rd_reg_mem,wr_data,
		forward_rs2_ex,forward_rs2_mem,forward_rs2_wb,
		opcode_s,rd_adr,imm_value_out,op1_adr_out,op2_adr_out,op1_data,op2_data,
		branch_addr_if_decode,branch_addr_decode_exe,branch_predicted_if_decode,branch_predicted_decode_exe,misprediction,idle
	);
	
	
	exe_jedinica: entity work.Exe(rtl)
	port map (
		clk,rs1_data,rs2_data,st_value,PC_addr_out,branch_taken,update_predictor,update_value,
		opcode_s,opcode_ex,rd_adr,rd_adr_ex,imm_value_out,
		data_alu_out,flush_ex,flush_id_exe,
		ar_log,brnch,load,valid,
		branch_addr_decode_exe,branch_predicted_decode_exe,misprediction,branch_pc,idle
	);
	
	mem_jedinica: entity work.MEM(rtl)
	port map (
	clk,reset,rd_mem,wr_mem,opcode_ex,opcode_mem_out,data_alu_out,st_value,
	rd_adr_ex,rd_adr_mem_out,rd_reg_mem,addr_bus,data_bus_out,
	data_bus_in,flush_mem_out,flush_ex,ar_log,load,ar_log_out,load_out,idle
	);
	
	wb_jedinica: entity work.WB(rtl)
	port map (
	clk,reset,opcode_mem_out,wr,wr_data,wr_adr,
	rd_reg_mem,rd_adr_mem_out,flush_mem_out,ar_log_out,load_out,stop,idle
	);
	
	
	fwd: entity work.Forward(rtl)
	port map (
	rd_adr_ex,rd_adr_mem_out,wr_adr,op1_adr_out,op2_adr_out,
	forward_rs1_ex,forward_rs1_mem,forward_rs1_wb,forward_rs2_ex,forward_rs2_mem,forward_rs2_wb,
	stall_if,stall_id,valid
	);
	
	predictor: entity work.BranchPredictor(rtl)
	port map (
		clk,reset,pc_from_if,update_predictor,update_value,
		branch_taken,branch_addr,hit,branch_predicted_pred_if
	);
	
end rtl;