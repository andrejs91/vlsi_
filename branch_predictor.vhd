library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity BranchPredictor is

	generic 
	(	
		tag_size: integer := 32;
		addr_length : integer := 32;
		data_length : integer := 32
	);
	
	
	port
	(
		-- Input ports
		clk : in std_logic;
		reset: in std_logic;
		
		pc_from_if: in std_logic_vector(addr_length-1 downto 0 );
		update_predictor: in std_logic; -- signalizira da treba updateovati prediktor
		update_value: in std_logic_vector(63 downto 0); -- vrednosti za koji ulaz se radi update 
		branch_taken: in std_logic; -- da li je doslo do skoka
		
		
		
		-- Output ports
		branch_addr:out std_logic_vector(addr_length-1 downto 0 );
		hit: out std_logic;
		
		branch_predicted : out std_logic
		
	);
end BranchPredictor;




architecture rtl of BranchPredictor is

type tag_array is array (0 to (tag_size - 1)) of std_logic_vector((addr_length - 1) downto 0);

signal tag_mem: tag_array:= (others=>(others=> '0'));
signal data_mem: tag_array:= (others=>(others=> '0')); 

type branch_array is array (0 to (tag_size - 1)) of std_logic_vector(1 downto 0);
type v_type is array (0 to tag_size - 1)  of std_logic;

signal branch_state: branch_array := (others=>(others=> '0'));
signal next_entry: std_logic_vector( 4 downto 0 );
signal v_bit: v_type;



begin

process (clk, reset)

	variable entry : integer := 0;
	variable found : boolean := false;
	variable tag_value : std_logic_vector (31 downto 0);
	variable data_value : std_logic_vector (31 downto 0);
	
begin
	

	if(reset='1')then 
		for i in 0 to (tag_size - 1) loop
			tag_mem(i) <= (others => '0');
			data_mem(i) <= (others => '0');
			v_bit(i) <= '0';
		end loop;
		next_entry <= (others => '0');
		
	elsif(rising_edge(clk)) then
		branch_addr <= (others => '0');
		hit <= '0';
		branch_predicted <= '0';
		tag_value := update_value(63 downto 32);
		data_value := update_value(31 downto 0);
		found := false;
		entry := 0;
		for i in 0 to (tag_size - 1) loop
			if( v_bit(i)='1' and tag_mem(i) = pc_from_if ) then
				hit <= '1';
				if( branch_state(i) = "00" or branch_state(i) = "01") then 
					branch_predicted <= '0';
				else 
					branch_predicted <= '1';
					branch_addr<= data_mem(i);
				end if;
			end if;
		end loop;
		
		if (update_predictor = '1') then
			for i in 0 to (tag_size - 1) loop
				if ( v_bit(i)='1' and tag_mem(i) = tag_value) then
					found := true;
					entry := i;
				end if;
			end loop;
			
			if(found = true) then
				if (branch_taken = '1') then
					if (branch_state(entry) = "00") then branch_state(entry) <= "01";
					else branch_state(entry) <= "11"; -- za ostala stanja prelazi u 11
					end if;
				else
					if (branch_state(entry) = "11") then branch_state(entry) <= "10";
					else branch_state(entry) <= "00";
					end if;
				end if;
			else --treba popuniti novi ulaz u kesu
				v_bit(to_integer(unsigned(next_entry))) <= '1';
				tag_mem(to_integer(unsigned(next_entry))) <= tag_value;
				data_mem(to_integer(unsigned(next_entry))) <= data_value;
				branch_state(to_integer(unsigned(next_entry))) <= "01";
				next_entry <= std_logic_vector((unsigned(next_entry) + 1) mod 32);
			end if;
			
		end if;
			
		
	end if;

end process;

end rtl;
